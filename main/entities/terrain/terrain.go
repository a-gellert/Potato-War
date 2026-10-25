components {
  id: "terrain"
  component: "/main/entities/terrain/terrain.script"
}
embedded_components {
  id: "sky"
  type: "sprite"
  data: "default_animation: \"bg_sky\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/terrain.atlas\"\n"
  "}\n"
  position {
    z: -0.45
  }
  scale {
    x: 4.5
    y: 3.5
  }
}
embedded_components {
  id: "bg_distant"
  type: "sprite"
  data: "default_animation: \"bg_distant\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/terrain.atlas\"\n"
  "}\n"
  position {
    y: 80.0
    z: -0.35
  }
  scale {
    x: 2.4
    y: 2.2
  }
}
embedded_components {
  id: "bg_islands"
  type: "sprite"
  data: "default_animation: \"bg_islands\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/terrain.atlas\"\n"
  "}\n"
  position {
    y: 120.0
    z: -0.25
  }
  scale {
    x: 2.2
    y: 2.0
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
  position {
    y: -652.0
    z: 0.4
  }
  scale {
    x: 2.5
    y: 2.5
  }
}
embedded_components {
  id: "spore1"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore2"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore3"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore4"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore5"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore6"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore7"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
embedded_components {
  id: "spore8"
  type: "sprite"
  data: "default_animation: \"spore\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  position {
    z: 0.25
  }
  scale {
    x: 1.5
    y: 1.5
  }
}
