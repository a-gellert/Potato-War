components {
  id: "crate"
  component: "/main/entities/crate/crate.script"
}
embedded_components {
  id: "box_sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"box\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.15
  }
  scale {
    x: 1.35
    y: 1.35
    z: 1.0
  }
}
embedded_components {
  id: "icon_sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"circle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.16
  }
  scale {
    x: 0.95
    y: 0.95
    z: 1.0
  }
}
embedded_components {
  id: "parachute_sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"circle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 26.0
    z: 0.14
  }
  scale {
    x: 1.35
    y: 0.85
    z: 1.0
  }
}
