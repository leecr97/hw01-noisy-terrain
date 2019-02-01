#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform float u_Time;
uniform float u_Amb;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;
out float fs_Height;

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}

float rand(float n){return fract(sin(n) * 43758.5453123);}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

// perlin noise

vec2 falloff(vec2 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
  }
vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec3 permute(vec3 x) {
    return mod((34.0 * x + 1.0) * x, 289.0);
  }

float pnoise(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = falloff(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

// worley noise
vec3 dist(vec3 x, vec3 y,  bool manhattanDistance) {
  return manhattanDistance ?  abs(x) + abs(y) :  (x * x + y * y);
}

vec2 worley(vec2 P, float jitter, bool manhattanDistance) {
float K= 0.142857142857; // 1/7
float Ko= 0.428571428571 ;// 3/7
  vec2 Pi = mod(floor(P), 289.0);
  vec2 Pf = fract(P);
  vec3 oi = vec3(-1.0, 0.0, 1.0);
  vec3 of = vec3(-0.5, 0.5, 1.5);
  vec3 px = permute(Pi.x + oi);
  vec3 p = permute(px.x + Pi.y + oi); // p11, p12, p13
  vec3 ox = fract(p*K) - Ko;
  vec3 oy = mod(floor(p*K),7.0)*K - Ko;
  vec3 dx = Pf.x + 0.5 + jitter*ox;
  vec3 dy = Pf.y - of + jitter*oy;
  vec3 d1 = dist(dx,dy, manhattanDistance); // d11, d12 and d13, squared
  p = permute(px.y + Pi.y + oi); // p21, p22, p23
  ox = fract(p*K) - Ko;
  oy = mod(floor(p*K),7.0)*K - Ko;
  dx = Pf.x - 0.5 + jitter*ox;
  dy = Pf.y - of + jitter*oy;
  vec3 d2 = dist(dx,dy, manhattanDistance); // d21, d22 and d23, squared
  p = permute(px.z + Pi.y + oi); // p31, p32, p33
  ox = fract(p*K) - Ko;
  oy = mod(floor(p*K),7.0)*K - Ko;
  dx = Pf.x - 1.5 + jitter*ox;
  dy = Pf.y - of + jitter*oy;
  vec3 d3 = dist(dx,dy, manhattanDistance); // d31, d32 and d33, squared
  // Sort out the two smallest distances (F1, F2)
  vec3 d1a = min(d1, d2);
  d2 = max(d1, d2); // Swap to keep candidates for F2
  d2 = min(d2, d3); // neither F1 nor F2 are now in d3
  d1 = min(d1a, d2); // F1 is now in d1
  d2 = max(d1a, d2); // Swap to keep candidates for F2
  d1.xy = (d1.x < d1.y) ? d1.xy : d1.yx; // Swap if smaller
  d1.xz = (d1.x < d1.z) ? d1.xz : d1.zx; // F1 is in d1.x
  d1.yz = min(d1.yz, d2.yz); // F2 is now not in d2.yz
  d1.y = min(d1.y, d1.z); // nor in  d1.z
  d1.y = min(d1.y, d2.x); // F2 is in d1.y, we're done.
  return sqrt(d1.xy);
}

// fbm - unused

// float interpNoise1D(float x) {
//   float intX = floor(x);
//   float fractX = fract(x);

//   float v1 = rand(intX);
//   float v2 = rand(intX + 1.0);
//   return mix(v1, v2, fractX);
// }

// float fbm(float x) {
//   float roughness = 1.0;
//   float freq = 1.0;
//   float amp = 0.5;
//   float sum = 0.0;

//   for (float i = 1.0; i < 8.0; i++) {
//     sum += interpNoise1D(x * freq) * amp * roughness;
//     amp *= 0.5;
//     freq *= 2.0;
//     roughness *= interpNoise1D(x * freq);
//   }
//   return sum;
// }

// float interpNoise2D(float x, float y) {
//   float intX = floor(x);
//   float fractX = fract(x);
//   float intY = floor(y);
//   float fractY = fract(y);

//   float v1 = random1(vec2(intX, intY), vec2(59.124, 14.382));
//   float v2 = random1(vec2(intX + 1.0, intY), vec2(940.22, 49.399));
//   float v3 = random1(vec2(intX, intY + 1.0), vec2(229.384, 5.9142));
//   float v4 = random1(vec2(intX + 1.0, intY + 1.0), vec2(329.481, 23.331));

//   float i1 = mix(v1, v2, fractX);
//   float i2 = mix(v3, v4, fractX);
//   return mix(i1, i2, fractY);
// }

// float fbm(float x, float y) {
//   float total = 0.0;
//   float persistence = 0.0;
//   float octaves = 8.0;

//   for (float i = 0.0; i < octaves; i++) {
//     float freq = pow(2.0, i);
//     float amp = pow(persistence, i);

//     total += interpNoise2D(x * freq, y * freq) * amp;
//   }
//   return total;
// }

float applyPerlinNoise(vec2 worldPos) {
  vec2 p = (worldPos + u_PlanePos) / 16.0;
  float x = pnoise(p);
  return x;
}

float applyWorleyNoise(vec2 worldPos) {
  vec2 p = (worldPos + u_PlanePos) / 8.0;
  vec2 wNoise = worley(p, 1.0, false);
  return wNoise.x;
}

void generateTerrain(vec3 pos, out float height) {  
  // two recursions of perlin noise
  height = applyPerlinNoise(vec2(pos.x, pos.y)) + applyPerlinNoise(vec2(pos.z, pos.y));
  height = pow(height, 2.0);
  height = applyPerlinNoise(vec2(pos.x, height)) + applyPerlinNoise(vec2(pos.z, height));
  height = pow(height, 2.0);

  // added to worley noise
  float w = applyWorleyNoise(vec2(pos.x, pos.z));
  height += w;
}

void main()
{
  fs_Pos = vs_Pos.xyz;
  // fs_Sine = (sin((vs_Pos.x + u_PlanePos.x) * 3.14159 * 0.1) + cos((vs_Pos.z + u_PlanePos.y) * 3.14159 * 0.1));
  // fs_Height = ceil(fs_Sine);
  generateTerrain(vs_Pos.xyz, fs_Height);

  // vec4 modelposition = vec4(vs_Pos.x, fs_Sine * 2.0, vs_Pos.z, 1.0);
  float xdisp = cos(u_Time) * 5.0;
  float ydisp = sin(u_Time);
  vec4 modelposition = vec4(fs_Pos.x + xdisp, fs_Height + ydisp, vs_Pos.z, 1.0);
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;
}
