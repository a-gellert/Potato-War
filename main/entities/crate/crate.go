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
    x: 1.4
    y: 1.4
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
  id: "cross_h"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"white_pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.17
  }
  scale {
    x: 14.0
    y: 4.5
    z: 1.0
  }
}
embedded_components {
  id: "cross_v"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"white_pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.17
  }
  scale {
    x: 4.5
    y: 14.0
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
    y: 38.0
    z: 0.14
  }
  scale {
    x: 3.2
    y: 2.0
    z: 1.0
  }
}
