components {
  id: "plane"
  component: "/main/entities/plane/plane.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"plane\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 0.42
    y: 0.42
  }
}
