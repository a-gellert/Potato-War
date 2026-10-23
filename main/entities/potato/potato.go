components {
  id: "potato"
  component: "/main/entities/potato/potato.script"
}
components {
  id: "rig_factory"
  component: "/main/entities/weapon_rig/weapon_rig.factory"
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
    x: 0.3125
    y: 0.3125
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
    y: 32.5
    z: 0.1
  }
  scale {
    x: 0.625
    y: 0.625
  }
}
embedded_components {
  id: "hat_sprite"
  type: "sprite"
  data: "default_animation: \"hat_beret\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 22.5
    z: 0.06
  }
  scale {
    x: 0.875
    y: 0.875
  }
}
embedded_components {
  id: "hp_bg"
  type: "sprite"
  data: "default_animation: \"hp_frame\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    y: 38.75
    z: 0.08
  }
  scale {
    x: 0.74
    y: 0.70
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
    y: 38.75
    z: 0.09
  }
  scale {
    x: 2.05
    y: 0.38
  }
}
embedded_components {
  id: "hp_text"
  type: "label"
  data: "size { x: 160.0 y: 24.0 }\n"
  "color { x: 1.0 y: 1.0 z: 1.0 w: 1.0 }\n"
  "outline { x: 0.05 y: 0.08 z: 0.12 w: 1.0 }\n"
  "shadow { x: 0.0 y: 0.0 z: 0.0 w: 0.0 }\n"
  "leading: 1.0\n"
  "tracking: 0.0\n"
  "pivot: PIVOT_CENTER\n"
  "blend_mode: BLEND_MODE_ALPHA\n"
  "line_break: false\n"
  "text: \"100/100\"\n"
  "font: \"/main/assets/game.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  position {
    y: 38.75
    z: 0.10
  }
  scale {
    x: 0.22
    y: 0.22
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
    y: 8.75
    z: 0.07
  }
  scale {
    x: 0.625
    y: 0.625
  }
}
embedded_components {
  id: "hit_spark1"
  type: "sprite"
  data: "default_animation: \"spark\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.2
  }
  scale {
    x: 0.1
    y: 0.1
  }
}
embedded_components {
  id: "hit_spark2"
  type: "sprite"
  data: "default_animation: \"dirt_particle\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.2
  }
  scale {
    x: 0.1
    y: 0.1
  }
}
