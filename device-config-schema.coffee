# #my-plugin configuration options
# Declare your config option for your plugin here.
module.exports = {
  title: "jeelabs devices config schema"
  Roomnode: {
    type: "object"
    properties:
      deviceid:
        description: "The id of this node"
        type: "string"
        default: "foo"
  }
}