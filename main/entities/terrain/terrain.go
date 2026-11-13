components {
  id: "terrain"
  component: "/main/entities/terrain/terrain.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"terrain_base\"\n"
  "material: \"/main/materials/terrain.material\"\n"
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
  id: "debris_factory"
  type: "factory"
  data: "prototype: \"/main/entities/debris/debris.go\"\n"
}
embedded_components {
  id: "bg_layer_factory"
  type: "factory"
  data: "prototype: \"/main/entities/bg_layer/bg_layer.go\"\n"
}
embedded_components {
  id: "bg_mote_factory"
  type: "factory"
  data: "prototype: \"/main/entities/bg_layer/bg_mote.go\"\n"
}
