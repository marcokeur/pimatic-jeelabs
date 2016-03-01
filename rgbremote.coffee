class RGBRemote extends env.devices.DimmerActuator

  constructor: (config, serial) ->
    @name = config.name
    @id = config.id
    @jeelink = serial
    @config = config
    super()

  changeDimlevelTo: (dimlevel) =>
    #set the dimlevel to the DimmerActuator superclass
    @_setDimlevel dimlevel

    #recalculate because the RGBRemote ranges from 0-255
    dimlevel = Math.round(dimlevel * 2.55)

    #assemble a message containing preconfigured RGB and add the dimlevel
    #also attach the configured nodeId
    message = @config.red + ',' + @config.green + ',' + @config.blue + ',' + dimlevel +
        ',' + @config.red + ',' + @config.green + ',' + @config.blue + ',' + dimlevel +
        ',' + @config.nodeid + 's' + '\r\n'
    #and write the message to the jeelink
    @jeelink.write message

    #send a toast to the UI
    env.logger.info 'wrote ' + message + ' to ' + @config.nodeid
    return Promise.resolve()
