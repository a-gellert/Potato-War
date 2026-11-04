#version 140

in mediump vec2 var_texcoord0;
in highp vec2 var_world_pos;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;

uniform fs_uniforms
{
    mediump vec4 tint;
    mediump vec4 terrain_params; // x: tex_w, y: tex_h, z: outline_width, w: micro_grain
};

// Fast procedural hash for crisp HD micro-grain (runs in world space)
float hash21(vec2 p)
{
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void main()
{
    vec2 tex_size = vec2(
        terrain_params.x > 0.0 ? terrain_params.x : 960.0,
        terrain_params.y > 0.0 ? terrain_params.y : 480.0
    );
    vec2 texel = 1.0 / tex_size;

    // Sample center color and alpha
    vec4 base_color = texture(texture_sampler, var_texcoord0);

    // If completely transparent air, discard early
    if (base_color.a < 0.02) {
        discard;
    }

    // Sub-pixel smooth edge anti-aliasing
    float alpha = smoothstep(0.15, 0.65, base_color.a);
    if (alpha <= 0.001) {
        discard;
    }

    // 4-tap neighborhood query for stylized cartoon dark outline
    float outline_offset = terrain_params.z > 0.0 ? terrain_params.z : 1.25;
    float a_up    = texture(texture_sampler, var_texcoord0 + vec2(0.0, texel.y * outline_offset)).a;
    float a_down  = texture(texture_sampler, var_texcoord0 - vec2(0.0, texel.y * outline_offset)).a;
    float a_left  = texture(texture_sampler, var_texcoord0 - vec2(texel.x * outline_offset, 0.0)).a;
    float a_right = texture(texture_sampler, var_texcoord0 + vec2(texel.x * outline_offset, 0.0)).a;

    float min_neighbor = min(min(a_up, a_down), min(a_left, a_right));
    float edge_factor = 1.0 - smoothstep(0.20, 0.75, min_neighbor);

    // Clean, smooth stylized shading without harsh pixel grain
    vec3 shaded_color = base_color.rgb;
    if (terrain_params.w > 0.0) {
        // Soft, subtle micro-variation if explicitly requested (w > 0)
        float grain = (hash21(floor(var_world_pos * 0.5)) - 0.5) * (0.015 * terrain_params.w);
        shaded_color += vec3(grain);
    }

    // Rich dark comic outline along crater rims and surface edges for crisp foreground separation
    vec3 outline_color = vec3(0.04, 0.03, 0.04);
    shaded_color = mix(shaded_color, outline_color, edge_factor * 0.94);

    // Inner rim backlight: subtle luminous bevel just inside the dark outline
    float inner_rim = smoothstep(0.18, 0.45, edge_factor) * (1.0 - smoothstep(0.62, 0.90, edge_factor));
    shaded_color += vec3(inner_rim * 0.18);

    // Top surface rim highlight (sunlight bouncing off grass/snow/soil crest)
    float top_edge = max(0.0, (a_down - a_up)) * (1.0 - edge_factor * 0.5);
    shaded_color += vec3(top_edge * 0.16);

    // Boost terrain contrast & vibrancy so foreground gameplay terrain pops forward
    shaded_color = clamp(pow(shaded_color, vec3(0.92)) * 1.08, 0.0, 1.0);

    // Final color with pre-multiplied alpha
    vec4 final_color = vec4(shaded_color * tint.rgb, alpha * tint.a);
    out_fragColor = vec4(final_color.rgb * final_color.a, final_color.a);
}
