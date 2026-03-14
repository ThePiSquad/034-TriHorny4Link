
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float glow_radius : hint_range(0.0, 50.0) = 20.0;
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float glow_softness : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_size = 1.0 / tex_size;
    
    // 采样周围像素实现模糊
    vec4 glow = vec4(0.0);
    float samples = 0.0;
    
    // 简单的径向模糊
    for(float x = -glow_radius; x <= glow_radius; x += 1.0) {
        for(float y = -glow_radius; y <= glow_radius; y += 1.0) {
            vec2 offset = vec2(x, y) * pixel_size;
            float dist = length(vec2(x, y));
            if(dist <= glow_radius) {
                vec4 sample_color = texture(TEXTURE, UV + offset);
                float weight = 1.0 - (dist / glow_radius);
                weight = pow(weight, glow_softness);
                glow += sample_color * weight;
                samples += weight;
            }
        }
    }
    
    glow /= samples;
    glow *= glow_intensity;
    glow.rgb *= glow_color.rgb;
    
    // 混合原图和发光
    COLOR = original_color + glow * (1.0 - original_color.a);
    COLOR.a = max(original_color.a, glow.a);
}
