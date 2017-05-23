Gem::Specification.new do |s|
  s.name = 'serial_can_bus'
  s.version = '0.4'
  s.date = '2016-05-05'
  s.summary = 'A simple implementation of the LAWICEL ASCII protocol for serial
CAN bus adapters (slcan).'

  s.description = 'A simple implementation of the LAWICEL ASCII protocol for
LAWICEL serial CAN bus adapters, tested with CANUSB though it should work with minimal
or null effort on CAN232 adapters (both available at http://www.can232.com).

This class of devices is covered by the slcan driver in the Linux kernel, this
Ruby implementation however does not require such driver and allows full
interaction with the adapters as long as the serial port is available.'

  s.authors = ["Andrea Barisani"]
  s.email = 'andrea@inversepath.com'
  s.files = ['lib/serial_can_bus.rb', 'lib/serial_can_bus/serial_can_bus.rb',
             'lib/serial_can_bus/request.rb', 'lib/serial_can_bus/response.rb',
             'lib/serial_can_bus/iso-tp.rb']
  s.extra_rdoc_files = ['CHANGELOG', 'LICENSE', 'README.md']
  s.homepage = 'https://github.com/inversepath/SerialCanBus'
  s.requirements = ['bit-struct', 'serialport']
  s.licenses = ['ISC']
end
