#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;
uniform float u_Amb;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Height;
in float fs_Sine;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    // out_Col = vec4(mix(vec3(0.5 * (fs_Sine + 1.0)), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);

    float heightScale = fs_Height / 2.0;

    vec3 lowCol = vec3(0.0, 0.0, 0.0);
    vec3 highCol = vec3(1.0, 1.0, 1.0);

    if (u_Amb == 0.0) { // red
        lowCol = vec3(34.0, 85.0, 165.0) / 255.0;
        highCol = vec3(66.0, 134.0, 244.0) / 255.0;
    }
    else if (u_Amb == 1.0) { // blue
        lowCol = vec3(239.0, 71.0, 71.0) / 255.0;
        highCol = vec3(165.0, 34.0, 34.0) / 255.0;
    }
    else if (u_Amb == 2.0) { // purple
        lowCol = vec3(113.0, 52.0, 193.0) / 255.0;
        highCol = vec3(164.0, 133.0, 255.0) / 255.0;
    }
    else { // something went wrong
    }

    vec3 height_Col = mix(lowCol, highCol, heightScale);
    out_Col = vec4(mix(height_Col, vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), t), 1.0);
}
