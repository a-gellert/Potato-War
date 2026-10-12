components {
  id: "projectile"
  component: "/main/entities/projectile/projectile.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"grenade\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
}
embedded_components {
  id: "trail1"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"smoke\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: -8.0
    y: 0.0
    z: -0.01
  }
}
embedded_components {
  id: "trail2"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"spark\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: -16.0
    y: 0.0
    z: -0.01
  }
}
embedded_components {
  id: "trail3"
  type: "sprite"
  data: "tile_set: \"/main/assets/game.atlas\"\n"
  "default_animation: \"smoke\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  position {
    x: -24.0
    y: 0.0
    z: -0.02
  }
}
