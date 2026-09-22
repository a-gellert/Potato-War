components {
  id: "napalm"
  component: "/main/entities/napalm/napalm.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"circle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ADD\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.4
  }
  scale {
    x: 0.5
    y: 0.5
    z: 1.0
  }
}
