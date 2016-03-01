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
    group:
      description: "The groupid of the network the jeelinks are using."
      type: "number"
      default: 33
}
