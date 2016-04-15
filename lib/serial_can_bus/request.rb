# CANUSB ASCII command request definitions
# (http://www.canusb.com/docs/canusb_manual.pdf)
#
# All objects are BitStruct ones, you can use describe() class method for
# fields documentation (e.g. puts SerialCanBus::Request::Transmit.describe).
#
# available requests:
#   SerialCanBus::Request::AcceptanceCode
#   SerialCanBus::Request::AcceptanceMask
#   SerialCanBus::Request::BtrSetup
#   SerialCanBus::Request::CloseChannel
#   SerialCanBus::Request::GetSerial
#   SerialCanBus::Request::GetVersion
#   SerialCanBus::Request::OpenChannel
#   SerialCanBus::Request::StandardSetup
#   SerialCanBus::Request::StatusFlag
#   SerialCanBus::Request::Transmit

class SerialCanBus::Request
  class Simple < BitStruct #:nodoc:
    string :cmd, 1*8, 'command'
  end

  # Get adapter serial number.
  class GetSerial < Simple
    initial_value.cmd = 'N'
  end

  # Get adapter version number.
  class GetVersion < Simple
    initial_value.cmd = 'V'
  end

  # Open CAN bus channel.
  class OpenChannel < Simple
    initial_value.cmd = 'O'
  end

  # Close CAN bus channel.
  class CloseChannel < Simple
    initial_value.cmd = 'C'
  end

  # Request Status Flag.
  class StatusFlag < Simple
    initial_value.cmd = 'F'
  end

  # Transmit frame.
  class Transmit < BitStruct
    ##
    # :attr_accessor: data
    # frame data (binary)
    rest :frame
  end

  # Setup predefined CAN bus speeds.

  class StandardSetup < BitStruct
    # Standard values for predefined CAN bit-rates.

    BITRATE = { 1000000 => '8',
                 800000 => '7',
                 500000 => '6',
                 250000 => '5',
                 125000 => '4',
                 100000 => '3',
                  50000 => '2',
                  20000 => '1',
                  10000 => '0' }

    string :cmd, 1*8, 'command', :default => 'S'

    ##
    # :attr_accessor: value
    # speed (String, 1 byte)
    string :value, 1*8, 'command', :default => BITRATE[125000]
  end

  # Setup arbitrary CAN bus speeds.

  class BtrSetup < BitStruct
    # The following formula shows how the SJA1000 clock speed, Baud Rate
    # Prescaler and Time Segment registers are used to calculate the bitrate.
    #
    # bitrate = 16000000 / (2 * (BRP.x + 1) * (3 + TSEG1.x + TSEG2.x))
    #
    # The BITRATE hash includes valid BTR0/BTR1 values, for the SJA1000 of the
    # CANUSB adapter, corresponding to each bitrate.

    BITRATE = { 1000000 => 0x4014,
                 800000 => 0x4016,
                 500000 => 0x401c,
                 250000 => 0x411c,
                 125000 => 0x431c,
                 100000 => 0x441c,
                  50000 => 0x491c,
                  20000 => 0x581c,
                  10000 => 0x711c }

    string :cmd, 1*8, 'command', :default => 's'

    ##
    # :attr_accessor: value
    # bitrate (String, 4 bytes), see BITRATE constant and bitrate=() for
    # automatic conversion from Fixnum
    string :value, 4*8, 'command', :default => BITRATE[125000]

    def bitrate=(bitrate)
      unless BITRATE[bitrate]
        raise 'unsupported bitrate'
      end

      self.value = BITRATE[bitrate].to_s(16).rjust(4, '0').upcase
    end
  end

  # Configure Acceptance Mask (AMn register of SJA1000).

  class AcceptanceMask < BitStruct
    string :cmd, 1*8, 'command', :default => 'm'

    ##
    # :attr_accessor: value
    # acceptance mask (String, 8 bytes), receive all frames by default, see
    # mask=() for automatic conversion from Bignum
    string :value, 8*8, 'command', :default => 'FFFFFFFF'

    def mask=(mask)
      self.value = mask.to_s(16).rjust(8, '0').upcase
    end
  end

  # Configure Acceptance Code (ACn register of SJA1000).

  class AcceptanceCode < BitStruct
    string :cmd, 1*8, 'command', :default => 'M'

    ##
    # :attr_accessor: value
    # acceptance code (String, 8 bytes), receive all frames by default, see
    # code=() for automatic conversion from Bignum
    string :value, 8*8, 'command', :default => '00000000'

    def code=(code)
      self.value = code.to_s(16).rjust(8, '0').upcase
    end
  end
end
