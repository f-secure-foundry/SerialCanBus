require 'bit-struct'
require 'serialport'

# A simple implementation of the LAWICEL ASCII protocol for LAWICEL serial CAN
# bus adapters, tested with CANUSB though it should work with minimal or null
# effort on CAN232 adapters (both available at http://www.can232.com).
#
# This class of devices is covered by the slcan driver in the Linux kernel,
# this Ruby implementation however does not require such driver and allows full
# interaction with the adapters as long as the serial port is available.
#
# - Examples
#
# initialization:
#   slcan = SerialCanBus.new('/dev/ttyUSB0', 19200, 125000)
#
# transmission of standard CAN frame with identifier 0x7ff and 2 bytes of data:
#   slcan.transmit_frame(:standard, 0x7ff, 2, 0xbeef)
#
# sniff first 20 frames:
#   slcan.while_receiving(20) do |kind, identifier, length, data|
#     puts "identifier #{identifier.to_s(16)} data #{data.to_s(16)}"
#   end
#
# get adapter status:
#   puts slcan.issue_command(:status_flag).dump
#
# Andrea Barisani <andrea@inversepath.com> | dev.inversepath.com/serial_can_bus

class SerialCanBus

  # SerialPort object created during initialization.
  attr_accessor :serial

  # The RETURN CODE hash matches the LAWICEL ASCII protocol values returned by
  # transmit_frame() and certain Response types.

  RETURN_CODE = { 0x07 => :error,
                  0x5a => :ok, # Z
                  0x7a => :ok  # z
                }

  # Standard CAN frame with 11-bit identifier.

  class StandardFrame < BitStruct
    string :kind,       1*8, 'command - frame type', :default => 't'

    ##
    # :attr_accessor: identifier
    # 11-bit identifier (String, 3 bytes)
    string :identifier, 3*8, '11-bit identifier'

    ##
    # :attr_accessor: dlength
    # data length (String, 1 byte)
    string :dlength,    1*8, 'data_length'

    ##
    # :attr_accessor: data
    # frame data (binary)
    rest   :data
  end

  # Extended CAN frame with 29-bit identifier.

  class ExtendedFrame < BitStruct
    string :kind,       1*8, 'command - frame type', :default => 'T'

    ##
    # :attr_accessor: identifier
    # 29-bit identifier (String, 8 bytes)
    string :identifier, 8*8, '29-bit identifier'

    ##
    # :attr_accessor: dlength
    # data length (String, 1 byte)
    string :dlength,    1*8, 'data_length'

    ##
    # :attr_accessor: data
    # frame data (binary)
    rest   :data
  end

  # Initialize the serial adapter. Returns a SerialPort object.
  #
  # The initialization automatically opens the CAN bus channel, it can be
  # manually closed with issue_command(). It is recommended to close the
  # channel as soon as possible when not receiving frames to avoid filling the
  # adapter buffer, which prevents successful request transmission.
  #
  # example:
  #  slcan = SerialCanBus.new('/dev/ttyUSB0', 19200, 125000, 0x0, 0xffffffff)
  #
  # arguments:
  #   device   character device for the adapter serial port (String)
  #   speed    serial port baud rate (Fixnum)
  #   bitrate  desired can bus bitrate (Fixnum)
  #   mask     CAN acceptance mask register (Bignum)
  #   code     CAN acceptance code register (Bignum)

  def initialize(device = '/dev/ttyUSB0', speed = 19200, bitrate = 125000, mask = 0xffffffff, code = 0x0)
    responses = []
    @serial = SerialPort.new(device, speed)

    issue_command(:close_channel)

    responses << issue_command(:standard_setup,  { :bitrate => bitrate })
    responses << issue_command(:acceptance_mask, { :mask => mask })
    responses << issue_command(:acceptance_code, { :code => code })
    responses << issue_command(:open_channel)

    responses.each do |response|
      if !response or response.return_code != 13 # CR
        raise "initialization failed (#{response.class} returned (#{response.return_code}), please reset adapter"
      end
    end

    @serial
  end

  # Issue a command to the serial CAN adapter. Returns a SerialCanBus::Response
  # object for the specific subclass of the issued command.
  #
  # example:
  #   response = slcan.issue_command(:btr_setup, { :bitrate => 125000 })
  # or alternatively:
  #   response = slcan.issue_command(SerialCanBus::Request::BtrSetup.new(:bitrate => 125000))
  #
  # arguments:
  #   command  Symbol for the command name or request instance
  #   options  command attributes (when command is a Symbol)
  #
  # available command symbols and request classes:
  #   :acceptance_code (SerialCanBus::Request::AcceptanceCode)
  #   :acceptance_mask (SerialCanBus::Request::AcceptanceMask)
  #   :btr_setup       (SerialCanBus::Request::BtrSetup)
  #   :close_channel   (SerialCanBus::Request::CloseChannel)
  #   :get_serial      (SerialCanBus::Request::GetSerial)
  #   :get_version     (SerialCanBus::Request::GetVersion)
  #   :open_channel    (SerialCanBus::Request::OpenChannel)
  #   :standard_setup  (SerialCanBus::Request::StandardSetup)
  #   :status_flag     (SerialCanBus::Request::StatusFlag)
  #   :transmit        (SerialCanBus::Request::Transmit)

  def issue_command(command, options = {})
    begin
      case command
      when Symbol
        command = command.to_s.split('_').map { |s| s.capitalize }.join
        request = Request.const_get(command).new(options)
        response = Response.const_get(command)
      when Object
        request = command
        response = Response.const_get(request.class.to_s.split('::').last)
      end
    rescue Exception => e
      raise "invalid command: #{command}, #{e.message}"
    end

    @serial.write(request)
    @serial.write("\r")

    response.new(@serial.read(response.new.size))
  end

  # Transmit a CAN frame. Returns a SerialCanBus::Response::Transmit object. It
  # is a wrapper to SerialCanBus::Request::Transmit which can be used directly
  # with issue_command() and the respective frame kind class.
  #
  # When transmitting frames it is desirable to initialize the adapter with
  # acceptance mask and code that prevent packet reception (inverting
  # defaults), this helps performance and cuts noise on the serial channel.
  #
  #
  # example:
  #   response = slcan.transmit_frame(:standard, 0x7ff, 2, 0xbeef)
  #
  # arguments:
  #   kind       Symbol for the frame type
  #   length     frame length (0-8)
  #   identifier CAN identifier (11-bit for standard, 29-bit for extended)
  #   data       frame data
  #
  # available frame kinds:
  #   :standard
  #   :extended

  def transmit_frame(kind = :standard, identifier = 0, length = 0, frame_data = 0)
    unless (0..8).include?(length)
      raise 'invalid length (! 0-8)'
    end

    data = frame_data.to_s(16).rjust(length * 2, '0')

    case kind
    when :standard
      identifier = (identifier & 0x7ff).to_s(16).rjust(3, '0')
      frame = StandardFrame.new(:identifier => identifier, :data => data, :dlength => length.to_s)
    when :extended
      identifier = (identifier & 0x1fffffff).to_s(16).rjust(8, '0')
      frame = ExtendedFrame.new(:identifier => identifier, :data => data, :dlength => length.to_s)
    else
      raise 'invalid frame kind'
    end

    response = issue_command(:transmit, { :frame => frame })

    @serial.read(1) if RETURN_CODE[response.return_code] == :ok

    response.return_code
  end

  # Wrapper that yields received frames to the invoking block. Returns frame
  # elements.
  #
  # The wrapper does not close the CAN bus channel on exit, this can be
  # performed manually with issue_command(). It is recommended to close the
  # channel as soon as possible when not receiving frames to avoid filling the
  # adapter buffer, which prevents successful request transmission.
  #
  # example (inspect data of first 100 received frames):
  #   slcan.while_receiving(100) do |kind, identifier, length, data|
  #     puts "identifier #{identifier.to_s(16)} data #{data.to_s(16)}"
  #   end
  #
  # arguments:
  #   count  frame count (optional)
  #
  # available frame kinds:
  #   :standard
  #   :extended

  def while_receiving(count = nil, &block)
    n = 0

    loop do
      kind = @serial.read(1)

      case kind
      when /t/
        kind = :standard
        identifier = @serial.read(3).to_i(16)
        length = @serial.read(1).to_i(16)
      when /T/
        kind = :extended
        identifier = @serial.read(8).to_i(16)
        length = @serial.read(1).to_i(16)
      when /\r/
        next
      else
        raise "invalid frame kind: #{kind.inspect}"
      end

      next unless length

      data = @serial.read(length * 2).to_i(16)

      yield [kind, identifier, length, data]

      if @serial.read(1) != "\r"
        raise 'invalid data (expected CR) aborting'
      end

      n = n.next

      break if count and n >= count
    end
  end
end
