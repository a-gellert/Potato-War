components {
  id: "potato"
  component: "/main/entities/potato/potato.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"recruit\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.25
    y: 0.25
  }
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
    y: 26.0
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
    x: 4.0
    y: -3.0
    z: 0.05
  }
  scale {
    x: 0.55
    y: 0.55
  }
}
embedded_components {
  id: "hat_sprite"
  type: "sprite"
  data: "default_animation: \"hat_cap\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 16.0
    z: 0.06
  }
  scale {
    x: 0.6
    y: 0.6
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
    y: 25.0
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
    y: 25.0
    z: 0.09
  }
  scale {
    x: 3.8
    y: 0.5
  }
}
embedded_components {
  id: "emotion"
  type: "sprite"
  data: "default_animation: \"s_happy\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 7.0
    z: 0.07
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
