module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  serialport = env.require 'serialport'
  SerialPort = serialport.SerialPort

  rf12ConfigRegex = /^ \w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/
  rf12Config = null

  devices = []

  class Jeelabs extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("Roomnode", {
        configDef: deviceConfigDef.Roomnode,
        createCallback: (config) => 
          roomnode = new Roomnode(config)
          devices.push roomnode
          return roomnode
      })

      serial = new SerialPort @config.port, {baudrate: 57600, parser: serialport.parsers.readline("\n")}
      serial.on 'open', =>
        callback = -> serial.write('h\r\n')
        setTimeout callback, 10000

      serial.on 'data', (data) =>
        msg = data.toString 'utf8'
        if msg.length < 300
          tokens = msg.split(' ')

          match = msg.match(rf12ConfigRegex)
          if match
            env.logger.info('CONFIG ' + msg)
            rf12Config = { recvid: +match[1], group: +match[2], band: +match[3] }
          
          else if(tokens.shift() == 'OK')
            #this is een jeelabs protocol package
            env.logger.info('MSG ' + tokens)

            groupId = tokens[0].substring(1)
            nodeId = tokens[1] & 0x1F;

            if(rf12Config)
              prefix = "rf12-" + rf12Config.band + ":" + groupId + ":" + nodeId
              for d in devices
                if(d.getDeviceId() == prefix)
                  d.parsePacket(tokens)

  class Roomnode extends env.devices.Device

    attributes:
      temperature:
        description: "the measured temperature"
        type: 'number'
        unit: '°C'
      motion:
        description: "is there motion detected"
        type: 'boolean'
      humidity:
        description: "the measured humidity"
        type: 'number'
        unit: '%' 
      light:
        description: "the measured light"
        type: 'number'
        unit: '%' 

    _temperature: null
    _motion: null
    _humidity: null
    _light: null
    _deviceId: null

    constructor: (@config) ->
      @_deviceId = @config.deviceid
      @name = @config.name
      @id = @config.id
      super()
    
    parsePacket: (packet) ->
      #parse temperature
      tmp = (((256 * (packet[5]&3) + packet[4]) ^ 512) - 512).toString()
      secondhalf = tmp.length - 1
      @_temperature = Number(tmp.substring(0,2) + '.' + tmp.substring(secondhalf))

      #parse light
      @_light = Number((packet[2] / 255 * 100)).toFixed()

      #parse humidity
      @_humidity = Number(packet[3] >> 1)

      #parse motion
      if (packet[3] & 1) == 0
        @_motion = false
      else
        @_motion = true

      @emit "temperature", @_temperature
      @emit "light", @_light
      @emit "humidity", @_humidity
      @emit "motion", @_motion

    getTemperature: -> Promise.resolve(@_temperature)
    getLight: -> Promise.resolve(@_light)
    getHumidity: -> Promise.resolve(@_humidity)
    getMotion: -> Promise.resolve(@_motion)

    getDeviceId: -> @_deviceId


  jeelabs = new Jeelabs
  return jeelabs