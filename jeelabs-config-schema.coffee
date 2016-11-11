# #my-plugin configuration options
# Declare your config option for your plugin here.
module.exports = {
  title: "my plugin config options"
  type: "object"
  properties:
    port:
      description: "The tty the jeelink is connected to."
      type: "string"
      default: "/dev/null"
    simpleParser:
      description: "Use a simple parser without extracting the rfm12 parameters"
      type: "boolean"
      default: false
    group:
      description: "The groupid of the network the jeelinks are using."
      type: "number"
      default: 33
}
