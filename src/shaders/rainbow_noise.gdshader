shader_type canvas_item;

uniform vec2 shape_size;

// 基础控制
uniform float noise_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float color_speed : hint_range(0.0, 5.0) = 1.0;
uniform float noise_scale : hint_range(0.1, 5.0) = 1.0;

// RGB通道独立控制
uniform float red_speed : hint_range(0.0, 3.0) = 1.0;
uniform float green_speed : hint_range(0.0, 3.0) = 1.2;
uniform float blue_speed : hint_range(0.0, 3.0) = 0.8;

// 扭曲效果
uniform float distortion : hint_range(0.0, 2.0) = 0.3;
uniform bool use_distortion = true;

// 颜色混合模式
uniform int blend_mode : hint_range(0, 2) = 0; // 0: 混合, 1: 叠加, 2: 屏幕

// 高级噪声函数 (Simplex noise 风格)
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }

// Simplex noise
float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// 生成动态五彩颜色
vec3 dynamic_rainbow(vec2 uv, float time) {
    // 为RGB通道使用不同的时间和位置偏移
    float t_r = time * red_speed;
    float t_g = time * green_speed;
    float t_b = time * blue_speed;
    
    // 添加扭曲效果
    vec2 uv_r = uv;
    vec2 uv_g = uv;
    vec2 uv_b = uv;
    
    if (use_distortion) {
        uv_r += vec2(snoise(uv * 2.0 + t_r * 0.5), snoise(uv * 2.0 + t_r * 0.5 + 10.0)) * distortion;
        uv_g += vec2(snoise(uv * 2.0 + t_g * 0.5 + 20.0), snoise(uv * 2.0 + t_g * 0.5 + 30.0)) * distortion;
        uv_b += vec2(snoise(uv * 2.0 + t_b * 0.5 + 40.0), snoise(uv * 2.0 + t_b * 0.5 + 50.0)) * distortion;
    }
    
    // 生成RGB通道
    float r = snoise(uv_r * noise_scale + vec2(t_r, 0.0)) * 0.5 + 0.5;
    float g = snoise(uv_g * noise_scale + vec2(t_g, t_g * 0.3)) * 0.5 + 0.5;
    float b = snoise(uv_b * noise_scale + vec2(t_b * 0.5, t_b)) * 0.5 + 0.5;
    
    return vec3(r, g, b);
}

// 混合模式
vec3 blend_colors(vec3 original, vec3 noise, float intensity, int mode) {
    if (mode == 0) { // 混合
        return mix(original, noise, intensity);
    } else if (mode == 1) { // 叠加
        return original + noise * intensity;
    } else { // 屏幕
        return 1.0 - (1.0 - original) * (1.0 - noise * intensity);
    }
}

bool is_inside_circle(vec2 pos, vec2 size) {
    float radius = min(size.x, size.y) * 0.5;
    return length(pos) <= radius;
}

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec2 local_pos = (UV - 0.5) * shape_size;
    
    float time = TIME * color_speed;
    
    // 生成动态UV (带扭曲)
    vec2 noise_uv = local_pos / shape_size * 2.0;
    
    // 生成动态五彩颜色
    vec3 rgb_noise = dynamic_rainbow(noise_uv, time);
    
    // 只影响圆形内部
    if (is_inside_circle(local_pos, shape_size)) {
        // 应用混合模式
        color.rgb = blend_colors(color.rgb, rgb_noise, noise_intensity, blend_mode);
    }
    
    COLOR = color;
}