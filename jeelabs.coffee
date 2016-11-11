module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  serialport = env.require 'serialport'
  SerialPort = serialport

  rf12ConfigRegex = /^ \w i(\d+)\*? g(\d+) @ (\d\d\d) MHz/
  rf12Config = null

  devices = []

  class Jeelabs extends env.plugins.Plugin
    init: (app, @framework, @config) ->
      @serial = new SerialPort @config.port, {baudrate: 57600, parser: serialport.parsers.readline("\n")}

      #when the serialport is opened
      @serial.on 'open', =>
        @onSerialOpen

      #when we received data on the jeelink
      @serial.on 'data', (data) =>
        @onSerialData (data)

      #register devices
      deviceConfigDef = require("./device-config-schema")

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
          rgbremote = new RGBRemote(config, @serial)
          return rgbremote
      })

      @framework.deviceManager.registerDeviceClass("EC3000", {
        configDef: deviceConfigDef.EC3000,
        createCallback: (config) =>
          ec3000 = new EC3000(config)
          devices.push ec3000
          return ec3000
      })

    onSerialOpen: ->
      #configure the jeelink to use the groupId from the configfile
      if not @config.simpleParser
        setTimeout ( =>
          @serial.write(@config.group + 'g\r\n')
        ), 5000

    onSerialData: (data) ->
      msg = data.toString 'utf8'

      if @config.simpleParser
        tokens = msg.split(' ')
        if tokens.length >= 21
          if tokens.shift() == 'OK'
            # we got a decrypted message
            tokens.shift()
            nodeid = (Number(tokens.shift()) << 8) + Number(tokens.shift())
            for d in devices
              if d.getNodeId() == nodeid
                d.parsePacket(tokens)
      else
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

    class RGBRemote extends env.devices.DimmerActuator

      constructor: (config, serial) ->
        @name = config.name
        @id = config.id
        @jeelink = serial
        @config = config
        super()

      changeDimlevelTo: (dimPercentage) =>
        #set the dimlevel to the DimmerActuator superclass
        @_setDimlevel dimPercentage

        #recalculate because the RGBRemote ranges from 0-255
        dimlevel = Math.round(dimPercentage * 2.55)

        #assemble a message containing preconfigured RGB and add the dimlevel
        #also attach the configured nodeId
        message = @config.red + ',' + @config.green + ',' + @config.blue + ',' + dimlevel +
            ',' + @config.red + ',' + @config.green + ',' + @config.blue + ',' + dimlevel +
            ',' + @config.nodeid + 's' + '\r\n'
        #and write the message to the jeelink
        @jeelink.write message

        #send a toast to the UI
        env.logger.info 'Dimmed RGBRemote ' + @config.nodeid + ' to ' + dimPercentage + '%'
        return Promise.resolve()

      destroy: () ->
        super()

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
        @name = @config.name
        @id = @config.id
        super()

      parsePacket: (packet) ->
        env.logger.info 'Roomnode ' + @config.nodeid + ' transmitted a message'

        #parse temperature
        tmp = (((256 * (packet[4]&3) + packet[3]) ^ 512) - 512).toString()
        secondhalf = tmp.length - 1
        @_temperature = Number(tmp.substring(0,2) + '.' + tmp.substring(secondhalf))

        #parse light
        @_light = Number(Number((packet[1] / 255 * 100)).toFixed())

        #parse humidity
        @_humidity = Number(packet[2] >> 1)

        #parse motion
        if (packet[2] & 1) == 0
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

      getNodeId: -> @config.nodeid

      destroy: () ->
        super()

    class EC3000 extends env.devices.Sensor
      attributes:
        secondsTotal:
          description: "Total runtime"
          type: "number"
          unit: "s"
        secondsOn:
          description: "On-time"
          type: "number"
          unit: "s"
        consumptionTotal:
          description: "Total consumption"
          type: "number"
          unit: "kWh"
        power:
          description: "Current consumption"
          type: "number"
          unit: "W"
        powerMax:
          description: "Peak consumption"
          type: "number"
          unit: "W"
        resets:
          description: "Resets"
          type: "number"
        reception:
          description: "RF reception"
          type: "number"

      _secondsTotal: null
      _secondsOn: null
      _consumptionTotal: null
      _power: null
      _powerMax: null
      _resets: null
      _reception: null

      constructor: (@config) ->
        @name = @config.name
        @id = @config.id
        super()

      parsePacket: (packet) ->
        # env.logger.info 'EC3000 ' + @config.nodeid + ' transmitted a message'

        secondsTotal = (Number(packet[0]) << 24) + (Number(packet[1]) << 16) + (Number(packet[2]) << 8) + (Number(packet[1]))
        secondsOn = (Number(packet[4]) << 24) + (Number(packet[5]) << 16) + (Number(packet[6]) << 8) + (Number(packet[7]))
        consumptionTotal = (Number(packet[8]) << 24) + (Number(packet[9]) << 16) + (Number(packet[10]) << 8) + (Number(packet[11]))
        power = ((Number(packet[12]) << 8) + (Number(packet[13]))) / 10.0
        powerMax = ((Number(packet[14]) << 8) + (Number(packet[15]))) / 10.0
        resets = (Number(packet[16]))
        reception = (Number(packet[17]))

        @_secondsTotal = secondsTotal
        @_secondsOn = secondsOn
        @_consumptionTotal = consumptionTotal
        @_power = power
        @_powerMax = powerMax
        @_resets = resets
        @_reception = reception

        @emit "secondsTotal", @_secondsTotal
        @emit "secondsOn", @_secondsOn
        @emit "consumptionTotal", @_consumptionTotal
        @emit "power", @_power
        @emit "powerMax", @_powerMax
        @emit "resets", @_resets
        @emit "reception", @_reception

      getSecondsTotal: -> Promise.resolve(@_secondsTotal)
      getSecondsOn: -> Promise.resolve(@_secondsOn)
      getConsumptionTotal: -> Promise.resolve(@_consumptionTotal)
      getPower: -> Promise.resolve(@_power)
      getPowerMax: -> Promise.resolve(@_powerMax)
      getResets: -> Promise.resolve(@_resets)
      getReception: -> Promise.resolve(@_reception)

      getNodeId: -> @config.nodeid

      destroy: () ->
        super()

  jeelabs = new Jeelabs
  return jeelabs
