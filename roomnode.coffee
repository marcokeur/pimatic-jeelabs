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
