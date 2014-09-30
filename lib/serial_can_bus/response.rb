# CANUSB ASCII command response definitions
# (http://www.canusb.com/docs/canusb_manual.pdf)
#
# All objects are BitStruct ones, you can use describe() class method for
# fields documentation (e.g. puts SerialCanBus::Response::Transmit.describe).
#
# available responses:
#   SerialCanBus::Response::AcceptanceCode
#   SerialCanBus::Response::AcceptanceMask
#   SerialCanBus::Response::BtrSetup
#   SerialCanBus::Response::CloseChannel
#   SerialCanBus::Response::GetSerial
#   SerialCanBus::Response::GetVersion
#   SerialCanBus::Response::OpenChannel
#   SerialCanBus::Response::StandardSetup
#   SerialCanBus::Response::StatusFlag
#   SerialCanBus::Response::Transmit

class SerialCanBus::Response
  class Simple < BitStruct #:nodoc:
    unsigned :return_code, 1*8, 'return code'
  end

  class GetSerial < BitStruct
    string :cmd, 1*8, 'command'

    ##
    # :attr_accessor: serial
    # serial number (String, 4 bytes)
    string :serial, 4*8, 'serial number'
  end

  class GetVersion < BitStruct
    string :cmd, 1*8, 'command'

    ##
    # :attr_accessor: hwv
    # hardware revision (String, 2 bytes)
    string :hwv, 2*8, 'hardware revision'

    ##
    # :attr_accessor: swv
    # software revision (String, 2 bytes)
    string :swv, 2*8, 'software revision'
  end

  # Provides decoding for the ASCII status_flag returned by the respective
  # Request.

  class StatusFlag < BitStruct
    string :cmd, 1*8, 'command'

    ##
    # :attr_accessor: status_flag
    # status flag (String, 2 bytes)
    string :status_flag, 2*8

    # CAN receive FIFO queue full (TrueClass or FalseClass)
    def rx_queue_full
      !((status_flag.to_i(16) >> 7) & 1).zero?
    end

    # CAN transmit FIFO queue full (TrueClass or FalseClass)
    def tx_queue_full
      !((status_flag.to_i(16) >> 6) & 1).zero?
    end

    # error warning (TrueClass or FalseClass)
    def error_warning
      !((status_flag.to_i(16) >> 5) & 1).zero?
    end

    # data overrun (TrueClass or FalseClass)
    def data_overrun
      !((status_flag.to_i(16) >> 4) & 1).zero?
    end

    # error passive (TrueClass or FalseClass)
    def error_passive
      !((status_flag.to_i(16) >> 2) & 1).zero?
    end

    # arbitration lost (TrueClass or FalseClass)
    def arbitration_lost
      !((status_flag.to_i(16) >> 1) & 1).zero?
    end

    # bus error (TrueClass or FalseClass)
    def bus_error
      !((status_flag.to_i(16) >> 0) & 1).zero?
    end

    # dump a Hash with all available information
    def dump
      { :status_flag => status_flag,
        :rx_queue_full => rx_queue_full,
        :tx_queue_full => tx_queue_full,
        :error_warning => error_warning,
        :data_overrun => data_overrun,
        :error_passive => error_passive,
        :arbitration_lost => arbitration_lost,
        :bus_error => bus_error
      }
    end
  end

  class AcceptanceCode < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end

  class AcceptanceMask < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end

  class BtrSetup < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end

  class CloseChannel < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end

  class OpenChannel < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end

  class StandardSetup < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end

  class Transmit < Simple
    ##
    # :attr_accessor: return_code
    # return code (Fixnum, 1 byte), see SerialCanBus RETURN_CODE constant
  end
end
