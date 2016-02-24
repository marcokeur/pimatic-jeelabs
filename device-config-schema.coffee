# #my-plugin configuration options
# Declare your config option for your plugin here.
module.exports = {
  title: "jeelabs devices config schema"
  Roomnode: {
    type: "object"
    properties:
      nodeid:
        description: "The id of this node"
        type: "integer"
        default: 0
  },
  RGBRemote: {
    type: "object"
    properties:
      nodeid:
        description: "The id of this node"
        type: "integer"
        default: 0
  }
}
