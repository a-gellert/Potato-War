components {
  id: "terrain"
  component: "/main/entities/terrain/terrain.script"
}
embedded_components {
  id: "sky"
  type: "sprite"
  data: "default_animation: \"white_pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    z: -0.3
  }
  scale {
    x: 100.0
    y: 100.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"terrain_base\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/terrain.atlas\"\n"
  "}\n"
  ""
  position {
    z: -0.1
  }
  scale {
    x: 2.0
    y: 2.0
  }
}
embedded_components {
  id: "water"
  type: "sprite"
  data: "default_animation: \"water\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/terrain.atlas\"\n"
  "}\n"
  ""
  position {
    y: -255.0
    z: 0.4
  }
  scale {
    x: 2.0
    y: 2.0
  }
}
