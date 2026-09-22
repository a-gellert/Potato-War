components {
  id: "explosion"
  component: "/main/entities/explosion/explosion.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"explosion\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.5
  }
}
embedded_components {
  id: "smoke1"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"smoke\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: -10.0
    y: 8.0
    z: 0.45
  }
  scale {
    x: 0.6
    y: 0.6
    z: 1.0
  }
}
embedded_components {
  id: "smoke2"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"smoke\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 10.0
    y: 10.0
    z: 0.45
  }
  scale {
    x: 0.6
    y: 0.6
    z: 1.0
  }
}
