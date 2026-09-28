components {
  id: "airship"
  component: "/main/entities/airship/airship.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"airship\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: 0.0
    y: 0.0
    z: 0.0
  }
  scale {
    x: 1.5
    y: 1.5
    z: 1.0
  }
}
