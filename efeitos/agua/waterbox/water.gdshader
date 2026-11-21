shader_type spatial;

uniform sampler2D noise_texture;
uniform float wave_speed = 0.5;
uniform float wave_strength = 0.2;
uniform vec3 water_color : source_color = vec3(0.1, 0.4, 0.8);

void vertex() {
    float noise_val = texture(noise_texture, UV + TIME * 0.05).r;
    VERTEX.y += sin(TIME * wave_speed + VERTEX.x * 2.0) * wave_strength * noise_val;
}

void fragment() {
    ALBEDO = water_color;
    
    METALLIC = 0.1;
    ROUGHNESS = 0.2;
    
    ALPHA = 0.7;
}