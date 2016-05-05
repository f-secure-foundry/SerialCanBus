# Helpers for ISO-TP (ISO-15765-2) data packet creation/parsing.
#
# - Examples
#
# build multiple segments from single payload:
#   segments = SerialCanBus::ISOTP.split(payload)
#
#   segments.each do |data|
#    response = slcan.transmit_frame(:standard, 0x7ff, data.size, data)
#   end

class SerialCanBus::ISOTP

  # Single frame

  class Single < BitStruct
    unsigned :header,  4, :default => 0

    ##
    # :attr_accessor: dlength
    # data length (Fixnum, 4 bits)
    unsigned :dlength, 4, 'data length'

    ##
    # :attr_accessor: data
    # frame data (binary)
    rest     :data

    def errors
      errors = []

      unless (0..7).include?(dlength)
        errors << "invalid length (#{dlength} != 0-7)"
      end

      if data.size > 7
        errors << "excessive data length (#{data.size} > 7)"
      end

      errors
    end
  end

  # First frame of multi-frame packet

  class First < BitStruct
    unsigned :header,   4, :default => 1

    ##
    # :attr_accessor: dlength
    # total data length Fixnum, 12 bits)
    unsigned :dlength, 12, 'total data length'

    ##
    # :attr_accessor: data
    # frame data (binary)
    rest     :data

    def errors
      errors = []

      unless (8..0xfff).include?(dlength)
        errors << "invalid length (#{dlength} != 8-4095)"
      end

      if data.size > 6
        errors << "excessive data length (#{data.size} > 6)"
      end

      errors
    end
  end

  # Subsequent data of a multi-frame packet

  class Consecutive < BitStruct
    unsigned :header,  4, :default => 2

    ##
    # :attr_accessor: index
    # consecutive packet index (Fixnum, 4 bits)
    unsigned :dindex,  4, 'index'

    ##
    # :attr_accessor: data
    # frame data (binary)
    rest     :data

    def errors
      errors = []

      if dindex > 15
        errors << "invalid index (#{dindex} > 15)"
      end

      if data.size > 7
        errors << "excessive data length (#{data.size} > 7)"
      end

      errors
    end
  end

  # Flow control packet

  class Flow < BitStruct
    unsigned :header,     4, :default => 3

    ##
    # :attr_accessor: fc
    # flow control flag (Fixnum, 4 bits)
    unsigned :fc,         4, 'FC flag'

    ##
    # :attr_accessor: block_size
    # block size (Fixnum, 1 byte)
    unsigned :block_size, 8, 'block size'

    ##
    # :attr_accessor: st
    # separation time (Fixnum, 1 byte)
    unsigned :st,         8, 'ST'

    def errors
      errors = []

      if fc > 2
        errors << "invalid FC flag (#{dindex} > 2)"
      end

      errors
    end
  end

  # Split data in one ore more ISO-TP segments.
  #
  # arguments:
  #   count  frame count (optional)
  #
  # return values:

  def self.split(data)
    packets = []
    dlength = data.size

    if dlength <= 7
      packets << Single.new(:dlength => dlength, :data => data)
    elsif dlength <= 0xfff
      index = 1
      packets << First.new(:dlength => dlength, :data => data[0..5])

      data[6..-1].scan(/.{1,7}/).each do |segment|
        packets << Consecutive.new(:dindex => index % 16, :data => segment)
        index += 1
      end
    else
      raise "invalid length (#{dlength} != 0-4095)"
    end

    packets
  end
end
