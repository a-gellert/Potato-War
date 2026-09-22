components {
  id: "potato"
  component: "/main/entities/potato/potato.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"potato_blue\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "reticle"
  type: "sprite"
  data: "default_animation: \"crosshair\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 30.0
    z: 0.1
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
embedded_components {
  id: "weapon_sprite"
  type: "sprite"
  data: "default_animation: \"grenade\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0.0
    y: 0.0
    z: 0.05
  }
  scale {
    x: 0.8
    y: 0.8
  }
}
embedded_components {
  id: "hp_bg"
  type: "sprite"
  data: "default_animation: \"white_pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 22.0
    z: 0.08
  }
  scale {
    x: 4.0
    y: 0.6
  }
}
embedded_components {
  id: "hp_fill"
  type: "sprite"
  data: "default_animation: \"white_pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 22.0
    z: 0.09
  }
  scale {
    x: 3.8
    y: 0.5
  }
}
