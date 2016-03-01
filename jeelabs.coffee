module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  serialport = env.require 'serialport'
  SerialPort = serialport.SerialPort

  rf12ConfigRegex = /^ \w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/
  rf12Config = null

  devices = []

  class Jeelabs extends env.plugins.Plugin

    onSerialOpen: =>
      #register devices
      deviceConfigDef = require("./device-config-schema")

      #include the device handling files
      roomnode = require("./roomnode")
      rgbremote = require("./rgbremote")
      
      @framework.deviceManager.registerDeviceClass("Roomnode", {
        configDef: deviceConfigDef.Roomnode,
        createCallback: (config) =>
          roomnode = new Roomnode(config)
          devices.push roomnode
          return roomnode
      })

      @framework.deviceManager.registerDeviceClass("RGBRemote", {
        configDef: deviceConfigDef.RGBRemote,
        createCallback: (config) =>
          rgbremote = new RGBRemote(config, serial)
          return rgbremote
      })

      #configure the jeelink to use the groupId from the configfile
      setTimeout ( =>
        @serial.write(@config.group + 'g\r\n')
      ), 5000

    onSerialData: (data)=>
      msg = data.toString 'utf8'

      #and the length of the msg is not longer then 300 chars
      if msg.length < 300
        tokens = msg.split(' ')

        #test if the msg matches on configuration regex
        match = msg.match(rf12ConfigRegex)

        #if there is a match
        if match

          #save the configuration for later use
          env.logger.info('CONFIG ' + msg)
          rf12Config = { recvid: +match[1], group: +match[2], band: +match[3] }

        #else, if the message starts with OK
        else if(tokens.shift() == 'OK')

          #this is een jeelabs protocol package, extract the nodeId
          nodeId = tokens[0] & 0x1F;

          #if the config is already known, i.e. all settings are known..
          if(rf12Config)
            #find the corresponding device
            for d in devices
              if(d.getNodeId() == nodeId)
                #and let it parse the received package
                d.parsePacket(tokens)


    init: (app, @framework, @config) =>
      @serial = new SerialPort @config.port, {baudrate: 57600, parser: serialport.parsers.readline("\n")}

      #when the serialport is opened
      serial.on 'open', => onSerialOpen

      #when we received data on the jeelink
      serial.on 'data', (data) => onSerialData (data)

  jeelabs = new Jeelabs
  return jeelabs
