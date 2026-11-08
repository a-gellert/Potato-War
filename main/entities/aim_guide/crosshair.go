embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"crosshair\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
}
embedded_components {
  id: "blast_ring"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"impact_ring\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    z: -0.01
  }
  scale {
    x: 0.4
    y: 0.4
  }
}
