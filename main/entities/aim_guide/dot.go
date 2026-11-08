embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"circle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
}
embedded_components {
  id: "glow"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"aim_glow\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ADD\n"
  position {
    z: -0.01
  }
}
