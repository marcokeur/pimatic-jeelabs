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
      red:
        description: "The red value"
        type: "integer"
        default: 200
      green:
        description: "The green value"
        type: "integer"
        default: 200
      blue:
        description: "The blue value"
        type: "integer"
        default: 200
  },
  EC3000: {
    type: "object"
    properties:
      nodeid:
        description: "The id of this node"
        type: "integer"
        default: 0
  },
}
