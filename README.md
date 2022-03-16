SerialCanBus
============

Copyright (c) Andrea Barisani <andrea@inversepath.com>

A Ruby library for LAWICEL serial CAN bus adapters

Introduction
============

A simple implementation of the LAWICEL ASCII protocol for LAWICEL serial CAN
bus adapters, tested with CANUSB though it should work with minimal or null
effort on CAN232 adapters (both available at http://www.can232.com).

This class of devices is covered by the slcan driver in the Linux kernel, this
Ruby implementation however does not require such driver and allows full
interaction with the adapters as long as the serial port is available.

Examples
========

initialization:

```
  require 'serial_can_bus'
  slcan = SerialCanBus.new('/dev/ttyUSB0', 19200, 125000)
```

transmission of standard CAN frame with identifier 0x7ff and 2 bytes of data:

```
  slcan.transmit_frame(:standard, 0x7ff, 2, 0xbeef)
```

sniff first 20 frames:

```
  slcan.while_receiving(20) do |kind, identifier, length, data|
    puts "kind #{kind} identifier #{identifier.to_s(16)} data #{data.unpack('H*')}"
  end
```

get adapter status:

```
  puts slcan.issue_command(:status_flag).dump
```

Requirements
============

bit-struct, serialport

Resources
=========

The SerialCanBus repository is https://github.com/f-secure-foundry/SerialCanBus

Automatically generated documentation can be found at
http://rubydoc.info/github/f-secure-foundry/SerialCanBus/master
or using the Ruby Index (ri) tool (e.g. `ri SerialCanBus.transmit_frame`)

Please report support and feature requests to <andrea@inversepath.com>

License
=======

Copyright (c) Andrea Barisani <andrea@inversepath.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
