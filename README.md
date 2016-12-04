# pimatic-jeelabs

This plugin is an interface between the Jeelabs infrastructure and Pimatic.
Currently there is support for the following sketches:
* Roomnode - display temperature, humidity, light and motion in the UI
* RGBRemote - configure RGB settings in the config and set brightness from the UI
* EC3000 - Energy Count 3000 Monitor (also known as RT-110)
  Use the Jeelink firmware from FHEM and flash your own hardware (Arduino + RFM12B)
  or use the Jeelink stick with the firmware flashed. Then configure the Jeelabs
  module to use the simpleParser and configure the device node id as printed on
  the device as a decimal number.

  Example:

      ...
      {
        "plugin": "jeelabs",
        "port": "/dev/ttyUSB0",
        "simpleParser": true,
        "active": true
      },
      ...
      "devices" : [
      {
        "id": "EC3000TestDevice",
        "class": "EC3000",
        "name": "EC3000 Energy Monitor",
        "nodeid": 23867
      },
      ]
      ...

  The number `23867` can be calculated from the hexadecimal printed label
  on the device e.g. in this case `0x5d3b`.

Further sketches will follow.
