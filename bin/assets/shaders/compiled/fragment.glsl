#version 330 core
#pragma fragmentoption ARB_precision_hint_nicest

in vec4 vColor;
in vec2 texCoord;

uniform vec2 u_resolution;
uniform float opacity = 1;
uniform float u_time = 0;
uniform vec2 u_mouse;

uniform float u_mouse_wheel;

uniform vec3 u_camera_position;
uniform ivec3 u_camera_position_int;

uniform vec3 u_camera_forward;
uniform vec3 u_camera_right;
uniform vec3 u_camera_up;
uniform vec3 u_camera_look_at;

uniform float u_objects[1000];
uniform int u_object_size;

uniform bool u_fog = true;

// 0 - no AA
// 2,3,4 - AA x 2/3/4
uniform int u_AA_type = 0;

// 0 - no shadows
// 1 - edgy shadows
// 2 - soft shadows
uniform int u_shadow_quality = 2;

out vec4 fragColor;

out float u_opacity;

const float FOV = 1.0;

//
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
//dynamic obj
const int MAX_STEPS_DYNAMIC = 512;
const int MAX_DIST_DYNAMIC = 200;
//static obj
const int MAX_STEPS_STATIC = 50;
const int MAX_DIST_STATIC = 300 * 300;

const float SHADOW_DISTANCE_SQUARE = 200 * 200;

// const float EPSILON = 1.4;
const float EPSILON = 0.0001;
const float EPSILON_MULTIPLIER = 2;
const float EPSILON_DYNAMIC = 0.00001;
const float EPSILON_STATIC = 0.001;

const float sphereScale = 1.0 / 1;
const float sphereBumpFactor = 0.21;

//tex
uniform sampler2D u_tex_01;
uniform sampler2D u_tex_01_bump;

#define NEWTON_ITER 2
#define HALLEY_ITER 0


///faster
// float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), 64.0 - 63.0*v );
//better
// float ww = pow( 1.0-smoothstep(0.0,1.414,sqrt(d)), 1.0 + 63.0*pow(1.0-v,4.0) );

////////////////////////////////////////////////////////////////
//
//                           HG_SDF
//
//     GLSL LIBRARY FOR BUILDING SIGNED DISTANCE BOUNDS
//
//     version 2021-07-28
//
//     Check https://mercury.sexy/hg_sdf for updates
//     and usage examples. Send feedback to spheretracing@mercury.sexy.
//
//     Brought to you by MERCURY https://mercury.sexy/
//
//
//
// Released dual-licensed under
//   Creative Commons Attribution-NonCommercial (CC BY-NC)
// or
//   MIT License
// at your choice.
//
// SPDX-License-Identifier: MIT OR CC-BY-NC-4.0
//
// /////
//
// CC-BY-NC-4.0
// https://creativecommons.org/licenses/by-nc/4.0/legalcode
// https://creativecommons.org/licenses/by-nc/4.0/
//
// /////
//
// MIT License
//
// Copyright (c) 2011-2021 Mercury Demogroup
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// /////
//
////////////////////////////////////////////////////////////////
//
// How to use this:
//
// 1. Build some system to #include glsl files in each other.
//   Include this one at the very start. Or just paste everywhere.
// 2. Build a sphere tracer. See those papers:
//   * "Sphere Tracing" https://link.springer.com/article/10.1007%2Fs003710050084
//   * "Enhanced Sphere Tracing" http://diglib.eg.org/handle/10.2312/stag.20141233.001-008
//   * "Improved Ray Casting of Procedural Distance Bounds" https://www.bibsonomy.org/bibtex/258e85442234c3ace18ba4d89de94e57d
//   The Raymnarching Toolbox Thread on pouet can be helpful as well
//   http://www.pouet.net/topic.php?which=7931&page=1
//   and contains links to many more resources.
// 3. Use the tools in this library to build your distance bound f().
// 4. ???
// 5. Win a compo.
// 
// (6. Buy us a beer or a good vodka or something, if you like.)
//
////////////////////////////////////////////////////////////////
//
// Table of Contents:
//
// * Helper functions and macros
// * Collection of some primitive objects
// * Domain Manipulation operators
// * Object combination operators
//
////////////////////////////////////////////////////////////////
//
// Why use this?
//
// The point of this lib is that everything is structured according
// to patterns that we ended up using when building geometry.
// It makes it more easy to write code that is reusable and that somebody
// else can actually understand. Especially code on Shadertoy (which seems
// to be what everybody else is looking at for "inspiration") tends to be
// really ugly. So we were forced to do something about the situation and
// release this lib ;)
//
// Everything in here can probably be done in some better way.
// Please experiment. We'd love some feedback, especially if you
// use it in a scene production.
//
// The main patterns for building geometry this way are:
// * Stay Lipschitz continuous. That means: don't have any distance
//   gradient larger than 1. Try to be as close to 1 as possible -
//   Distances are euclidean distances, don't fudge around.
//   Underestimating distances will happen. That's why calling
//   it a "distance bound" is more correct. Don't ever multiply
//   distances by some value to "fix" a Lipschitz continuity
//   violation. The invariant is: each fSomething() function returns
//   a correct distance bound.
// * Use very few primitives and combine them as building blocks
//   using combine opertors that preserve the invariant.
// * Multiply objects by repeating the domain (space).
//   If you are using a loop inside your distance function, you are
//   probably doing it wrong (or you are building boring fractals).
// * At right-angle intersections between objects, build a new local
//   coordinate system from the two distances to combine them in
//   interesting ways.
// * As usual, there are always times when it is best to not follow
//   specific patterns.
//
////////////////////////////////////////////////////////////////
//
// FAQ
//
// Q: Why is there no sphere tracing code in this lib?
// A: Because our system is way too complex and always changing.
//    This is the constant part. Also we'd like everyone to
//    explore for themselves.
//
// Q: This does not work when I paste it into Shadertoy!!!!
// A: Yes. It is GLSL, not GLSL ES. We like real OpenGL
//    because it has way more features and is more likely
//    to work compared to browser-based WebGL. We recommend
//    you consider using OpenGL for your productions. Most
//    of this can be ported easily though.
//
// Q: How do I material?
// A: We recommend something like this:
//    Write a material ID, the distance and the local coordinate
//    p into some global variables whenever an object's distance is
//    smaller than the stored distance. Then, at the end, evaluate
//    the material to get color, roughness, etc., and do the shading.
//
// Q: I found an error. Or I made some function that would fit in
//    in this lib. Or I have some suggestion.
// A: Awesome! Drop us a mail at spheretracing@mercury.sexy.
//
// Q: Why is this not on github?
// A: Because we were too lazy. If we get bugged about it enough,
//    we'll do it.
//
// Q: Your license sucks for me.
// A: Oh. What should we change it to?
//
// Q: I have trouble understanding what is going on with my distances.
// A: Some visualization of the distance field helps. Try drawing a
//    plane that you can sweep through your scene with some color
//    representation of the distance field at each point and/or iso
//    lines at regular intervals. Visualizing the length of the
//    gradient (or better: how much it deviates from being equal to 1)
//    is immensely helpful for understanding which parts of the
//    distance field are broken.
//
////////////////////////////////////////////////////////////////






////////////////////////////////////////////////////////////////
//
//             HELPER FUNCTIONS/MACROS
//
////////////////////////////////////////////////////////////////

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (sqrt(5)*0.5 + 0.5)

// Clamp to [0,1] - this operation is free under certain circumstances.
// For further information see
// http://www.humus.name/Articles/Persson_LowLevelThinking.pdf and
// http://www.humus.name/Articles/Persson_LowlevelShaderOptimization.pdf
#define saturate(x) clamp(x, 0, 1)

// Sign function that doesn't return 0
float sgn(float x) {
	return (x<0)?-1:1;
}

vec2 sgn(vec2 v) {
	return vec2((v.x<0)?-1:1, (v.y<0)?-1:1);
}

float square (float x) {
	return x*x;
}

vec2 square (vec2 x) {
	return x*x;
}

vec3 square (vec3 x) {
	return x*x;
}

float lengthSqr(vec3 x) {
	return dot(x, x);
}


// Maximum/minumum elements of a vector
float vmax(vec2 v) {
	return max(v.x, v.y);
}

float vmax(vec3 v) {
	return max(max(v.x, v.y), v.z);
}

float vmax(vec4 v) {
	return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(vec2 v) {
	return min(v.x, v.y);
}

float vmin(vec3 v) {
	return min(min(v.x, v.y), v.z);
}

float vmin(vec4 v) {
	return min(min(v.x, v.y), min(v.z, v.w));
}




////////////////////////////////////////////////////////////////
//
//             PRIMITIVE DISTANCE FUNCTIONS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that is a distance function is called fSomething.
// The first argument is always a point in 2 or 3-space called <p>.
// Unless otherwise noted, (if the object has an intrinsic "up"
// side or direction) the y axis is "up" and the object is
// centered at the origin.
//
////////////////////////////////////////////////////////////////

// float Q_rsqrt(float number)
// {
// 	union {
// 		float    f;
// 		uint32_t i;
// 	} conv = { .f = number };
// 	conv.i  = 0x5f3759df - (conv.i >> 1);
// 	conv.f *= 1.5F - (number * 0.5F * conv.f * conv.f);
// 	return conv.f;
// }

float fSphere(vec3 p, float r) {
	return length(p) - r;
}

// Plane with normal n (n is normalized) at some distance from the origin
float fPlane(vec3 p, vec3 n, float distanceFromOrigin) {
	return dot(p, n) + distanceFromOrigin;
}

// Cheap Box: distance to corners is overestimated
float fBoxCheap(vec3 p, vec3 b) { //cheap box
	return vmax(abs(p) - b);
}

// Box: correct distance to corners
float fBox(vec3 p, vec3 b) {
	vec3 d = abs(p) - b;
	return length(max(d, vec3(0))) + vmax(min(d, vec3(0)));
}

// Same as above, but in two dimensions (an endless box)
float fBox2Cheap(vec2 p, vec2 b) {
	return vmax(abs(p)-b);
}

float fBox2(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, vec2(0))) + vmax(min(d, vec2(0)));
}


// Endless "corner"
float fCorner (vec2 p) {
	return length(max(p, vec2(0))) + vmax(min(p, vec2(0)));
}

// Blobby ball object. You've probably seen it somewhere. This is not a correct distance bound, beware.
float fBlob(vec3 p) {
	p = abs(p);
	if (p.x < max(p.y, p.z)) p = p.yzx;
	if (p.x < max(p.y, p.z)) p = p.yzx;
	float b = max(max(max(
		dot(p, normalize(vec3(1, 1, 1))),
		dot(p.xz, normalize(vec2(PHI+1, 1)))),
		dot(p.yx, normalize(vec2(1, PHI)))),
		dot(p.xz, normalize(vec2(1, PHI))));
	float l = length(p);
	return l - 1.5 - 0.2 * (1.5 / 2)* cos(min(sqrt(1.01 - b / l)*(PI / 0.25), PI));
}

// Cylinder standing upright on the xz plane
float fCylinder(vec3 p, float r, float height) {
	float d = length(p.xz) - r;
	d = max(d, abs(p.y) - height);
	return d;
}

// Capsule: A Cylinder with round caps on both sides
float fCapsule(vec3 p, float r, float c) {
	return mix(length(p.xz) - r, length(vec3(p.x, abs(p.y) - c, p.z)) - r, step(c, abs(p.y)));
}

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
float fLineSegment(vec3 p, vec3 a, vec3 b) {
	vec3 ab = b - a;
	float t = saturate(dot(p - a, ab) / dot(ab, ab));
	return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r 
float fCapsule(vec3 p, vec3 a, vec3 b, float r) {
	return fLineSegment(p, a, b) - r;
}

// Torus in the XZ-plane
float fTorus(vec3 p, float smallRadius, float largeRadius) {
	return length(vec2(length(p.xz) - largeRadius, p.y)) - smallRadius;
}

// A circle line. Can also be used to make a torus by subtracting the smaller radius of the torus.
float fCircle(vec3 p, float r) {
	float l = length(p.xz) - r;
	return length(vec2(p.y, l));
}

// A circular disc with no thickness (i.e. a cylinder with no height).
// Subtract some value to make a flat disc with rounded edge.
float fDisc(vec3 p, float r) {
	float l = length(p.xz) - r;
	return l < 0 ? abs(p.y) : length(vec2(p.y, l));
}

// Hexagonal prism, circumcircle variant
float fHexagonCircumcircle(vec3 p, vec2 h) {
	vec3 q = abs(p);
	return max(q.y - h.y, max(q.x*sqrt(3)*0.5 + q.z*0.5, q.z) - h.x);
	//this is mathematically equivalent to this line, but less efficient:
	//return max(q.y - h.y, max(dot(vec2(cos(PI/3), sin(PI/3)), q.zx), q.z) - h.x);
}

// Hexagonal prism, incircle variant
float fHexagonIncircle(vec3 p, vec2 h) {
	return fHexagonCircumcircle(p, vec2(h.x*sqrt(3)*0.5, h.y));
}

// Cone with correct distances to tip and base circle. Y is up, 0 is in the middle of the base.
float fCone(vec3 p, float radius, float height) {
	vec2 q = vec2(length(p.xz), p.y);
	vec2 tip = q - vec2(0, height);
	vec2 mantleDir = normalize(vec2(height, radius));
	float mantle = dot(tip, mantleDir);
	float d = max(mantle, -q.y);
	float projected = dot(tip, vec2(mantleDir.y, -mantleDir.x));
	
	// distance to tip
	if ((q.y > height) && (projected < 0)) {
		d = max(d, length(tip));
	}
	
	// distance to base ring
	if ((q.x > radius) && (projected > length(vec2(height, radius)))) {
		d = max(d, length(q - vec2(radius, 0)));
	}
	return d;
}

//
// "Generalized Distance Functions" by Akleman and Chen.
// see the Paper at https://www.viz.tamu.edu/faculty/ergun/research/implicitmodeling/papers/sm99.pdf
//
// This set of constants is used to construct a large variety of geometric primitives.
// Indices are shifted by 1 compared to the paper because we start counting at Zero.
// Some of those are slow whenever a driver decides to not unroll the loop,
// which seems to happen for fIcosahedron und fTruncatedIcosahedron on nvidia 350.12 at least.
// Specialized implementations can well be faster in all cases.
//

const vec3 GDFVectors[19] = vec3[](
	normalize(vec3(1, 0, 0)),
	normalize(vec3(0, 1, 0)),
	normalize(vec3(0, 0, 1)),

	normalize(vec3(1, 1, 1 )),
	normalize(vec3(-1, 1, 1)),
	normalize(vec3(1, -1, 1)),
	normalize(vec3(1, 1, -1)),

	normalize(vec3(0, 1, PHI+1)),
	normalize(vec3(0, -1, PHI+1)),
	normalize(vec3(PHI+1, 0, 1)),
	normalize(vec3(-PHI-1, 0, 1)),
	normalize(vec3(1, PHI+1, 0)),
	normalize(vec3(-1, PHI+1, 0)),

	normalize(vec3(0, PHI, 1)),
	normalize(vec3(0, -PHI, 1)),
	normalize(vec3(1, 0, PHI)),
	normalize(vec3(-1, 0, PHI)),
	normalize(vec3(PHI, 1, 0)),
	normalize(vec3(-PHI, 1, 0))
);

// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
float fGDF(vec3 p, float r, float e, int begin, int end) {
	float d = 0;
	for (int i = begin; i <= end; ++i)
		d += pow(abs(dot(p, GDFVectors[i])), e);
	return pow(d, 1/e) - r;
}

// Version with without exponent, creates objects with sharp edges and flat faces
float fGDF(vec3 p, float r, int begin, int end) {
	float d = 0;
	for (int i = begin; i <= end; ++i)
		d = max(d, abs(dot(p, GDFVectors[i])));
	return d - r;
}

// Primitives follow:

float fOctahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 3, 6);
}

float fDodecahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 13, 18);
}

float fIcosahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 3, 12);
}

float fTruncatedOctahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 0, 6);
}

float fTruncatedIcosahedron(vec3 p, float r, float e) {
	return fGDF(p, r, e, 3, 18);
}

float fOctahedron(vec3 p, float r) {
	return fGDF(p, r, 3, 6);
}

float fDodecahedron(vec3 p, float r) {
	return fGDF(p, r, 13, 18);
}

float fIcosahedron(vec3 p, float r) {
	return fGDF(p, r, 3, 12);
}

float fTruncatedOctahedron(vec3 p, float r) {
	return fGDF(p, r, 0, 6);
}

float fTruncatedIcosahedron(vec3 p, float r) {
	return fGDF(p, r, 3, 18);
}


////////////////////////////////////////////////////////////////
//
//                DOMAIN MANIPULATION OPERATORS
//
////////////////////////////////////////////////////////////////
//
// Conventions:
//
// Everything that modifies the domain is named pSomething.
//
// Many operate only on a subset of the three dimensions. For those,
// you must choose the dimensions that you want manipulated
// by supplying e.g. <p.x> or <p.zx>
//
// <inout p> is always the first argument and modified in place.
//
// Many of the operators partition space into cells. An identifier
// or cell index is returned, if possible. This return value is
// intended to be optionally used e.g. as a random seed to change
// parameters of the distance functions inside the cells.
//
// Unless stated otherwise, for cell index 0, <p> is unchanged and cells
// are centered on the origin so objects don't have to be moved to fit.
//
//
////////////////////////////////////////////////////////////////



// Rotate around a coordinate axis (i.e. in a plane perpendicular to that axis) by angle <a>.
// Read like this: R(p.xz, a) rotates "x towards z".
// This is fast if <a> is a compile-time constant and slower (but still practical) if not.
void pR(inout vec2 p, float a) {
	p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout vec2 p) {
	p = (p + vec2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pMod1(p.x,5);> - using the return value is optional.
float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	return c;
}

// Same, but mirror every second cell so they match at the boundaries
float pModMirror1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p + halfsize,size) - halfsize;
	p *= mod(c, 2.0)*2 - 1;
	return c;
}

// Repeat the domain only in positive direction. Everything in the negative half-space is unchanged.
float pModSingle1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	if (p >= 0)
		p = mod(p + halfsize, size) - halfsize;
	return c;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p+halfsize, size) - halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}


// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
float pModPolar(inout vec2 p, float repetitions) {
	float angle = 2*PI/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = vec2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2)) c = abs(c);
	return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5,size) - size*0.5;
	return c;
}

// Same, but mirror every second cell so all boundaries match
vec2 pModMirror2(inout vec2 p, vec2 size) {
	vec2 halfsize = size*0.5;
	vec2 c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	p *= mod(c,vec2(2))*2 - vec2(1);
	return c;
}

// Same, but mirror every second cell at the diagonal as well
vec2 pModGrid2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5, size) - size*0.5;
	p *= mod(c,vec2(2))*2 - vec2(1);
	p -= size/2;
	if (p.x > p.y) p.xy = p.yx;
	return floor(c/2);
}

// Repeat in three dimensions
vec3 pMod3(inout vec3 p, vec3 size) {
	vec3 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5, size) - size*0.5;
	return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
float pMirror (inout float p, float dist) {
	float s = sgn(p);
	p = abs(p)-dist;
	return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
vec2 pMirrorOctant (inout vec2 p, vec2 dist) {
	vec2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

// Reflect space at a plane
float pReflect(inout vec3 p, vec3 planeNormal, float offset) {
	float t = dot(p, planeNormal)+offset;
	if (t < 0) {
		p = p - (2*t)*planeNormal;
	}
	return sgn(t);
}


////////////////////////////////////////////////////////////////
//
//             OBJECT COMBINATION OPERATORS
//
////////////////////////////////////////////////////////////////
//
// We usually need the following boolean operators to combine two objects:
// Union: OR(a,b)
// Intersection: AND(a,b)
// Difference: AND(a,!b)
// (a and b being the distances to the objects).
//
// The trivial implementations are min(a,b) for union, max(a,b) for intersection
// and max(a,-b) for difference. To combine objects in more interesting ways to
// produce rounded edges, chamfers, stairs, etc. instead of plain sharp edges we
// can use combination operators. It is common to use some kind of "smooth minimum"
// instead of min(), but we don't like that because it does not preserve Lipschitz
// continuity in many cases.
//
// Naming convention: since they return a distance, they are called fOpSomething.
// The different flavours usually implement all the boolean operators above
// and are called fOpUnionRound, fOpIntersectionRound, etc.
//
// The basic idea: Assume the object surfaces intersect at a right angle. The two
// distances <a> and <b> constitute a new local two-dimensional coordinate system
// with the actual intersection as the origin. In this coordinate system, we can
// evaluate any 2D distance function we want in order to shape the edge.
//
// The operators below are just those that we found useful or interesting and should
// be seen as examples. There are infinitely more possible operators.
//
// They are designed to actually produce correct distances or distance bounds, unlike
// popular "smooth minimum" operators, on the condition that the gradients of the two
// SDFs are at right angles. When they are off by more than 30 degrees or so, the
// Lipschitz condition will no longer hold (i.e. you might get artifacts). The worst
// case is parallel surfaces that are close to each other.
//
// Most have a float argument <r> to specify the radius of the feature they represent.
// This should be much smaller than the object size.
//
// Some of them have checks like "if ((-a < r) && (-b < r))" that restrict
// their influence (and computation cost) to a certain area. You might
// want to lift that restriction or enforce it. We have left it as comments
// in some cases.
//
// usage example:
//
// float fTwoBoxes(vec3 p) {
//   float box0 = fBox(p, vec3(1));
//   float box1 = fBox(p-vec3(1), vec3(1));
//   return fOpUnionChamfer(box0, box1, 0.2);
// }
//
////////////////////////////////////////////////////////////////


// The "Chamfer" flavour makes a 45-degree chamfered edge (the diagonal of a square of size <r>):
float fOpUnionChamfer(float a, float b, float r) {
	return min(min(a, b), (a - r + b)*sqrt(0.5));
}

// Intersection has to deal with what is normally the inside of the resulting object
// when using union, which we normally don't care about too much. Thus, intersection
// implementations sometimes differ from union implementations.
float fOpIntersectionChamfer(float a, float b, float r) {
	return max(max(a, b), (a + r + b)*sqrt(0.5));
}

// Difference can be built from Intersection or Union:
float fOpDifferenceChamfer (float a, float b, float r) {
	return fOpIntersectionChamfer(a, -b, r);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
float fOpUnionRound(float a, float b, float r, float r2 = 1) {
	vec2 u = max(vec2(r - a,r - b), vec2(0));
	return max(r, min (a, b)) - length(u * r2);
}

float fOpIntersectionRound(float a, float b, float r) {
	vec2 u = max(vec2(r + a,r + b), vec2(0));
	return min(-r, max (a, b)) + length(u);
}

float fOpDifferenceRound (float a, float b, float r) {
	return fOpIntersectionRound(a, -b, r);
}


// The "Columns" flavour makes n-1 circular columns at a 45 degree angle:
float fOpUnionColumns(float a, float b, float r, float n) {
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));
		pR45(p);
		p.x -= sqrt(2)/2*r;
		p.x += columnradius*sqrt(2);
		if (mod(n,2) == 1) {
			p.y += columnradius;
		}
		// At this point, we have turned 45 degrees and moved at a point on the
		// diagonal that we want to place the columns on.
		// Now, repeat the domain along this direction and place a circle.
		pMod1(p.y, columnradius*2);
		float result = length(p) - columnradius;
		result = min(result, p.x);
		result = min(result, a);
		return min(result, b);
	} else {
		return min(a, b);
	}
}

float fOpDifferenceColumns(float a, float b, float r, float n) {
	a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r)) {
		vec2 p = vec2(a, b);
		float columnradius = r*sqrt(2)/n/2.0;
		columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));

		pR45(p);
		p.y += columnradius;
		p.x -= sqrt(2)/2*r;
		p.x += -columnradius*sqrt(2)/2;

		if (mod(n,2) == 1) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

float fOpIntersectionColumns(float a, float b, float r, float n) {
	return fOpDifferenceColumns(a,-b,r, n);
}

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float fOpUnionStairs(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2 * s)) - s)));
}

// We can just call Union since stairs are symmetric.
float fOpIntersectionStairs(float a, float b, float r, float n) {
	return -fOpUnionStairs(-a, -b, r, n);
}

float fOpDifferenceStairs(float a, float b, float r, float n) {
	return -fOpUnionStairs(-a, b, r, n);
}


// Similar to fOpUnionRound, but more lipschitz-y at acute angles
// (and less so at 90 degrees). Useful when fudging around too much
// by MediaMolecule, from Alex Evans' siggraph slides
float fOpUnionSoft(float a, float b, float r) {
	float e = max(r - abs(a - b), 0);
	return min(a, b) - e*e*0.25/r;
}


// produces a cylindical pipe that runs along the intersection.
// No objects remain, only the pipe. This is not a boolean operator.
float fOpPipe(float a, float b, float r) {
	return length(vec2(a, b)) - r;
}

// first object gets a v-shaped engraving where it intersect the second
float fOpEngrave(float a, float b, float r) {
	return max(a, (a + r - abs(b))*sqrt(0.5));
}

// first object gets a capenter-style groove cut out
float fOpGroove(float a, float b, float ra, float rb) {
	return max(a, min(a + ra, rb - abs(b)));
}

// first object gets a capenter-style tongue attached
float fOpTongue(float a, float b, float ra, float rb) {
	return min(a, max(a - ra, abs(b) - rb));
}

struct Surface
{
    float sd;
    vec3 col;
    // int materialId = 0;
};

struct Voxel{
    ivec3 pos;
    int dist;
    float col;
    float dt;
    bool crossed;
};

Surface sdFloor(vec3 p, vec3 col) {
  float d = p.y + 1.;
  return Surface(d, col);
}

Surface minWithColor(Surface obj1, Surface obj2) {
  if (obj2.sd < obj1.sd) return obj2;
  return obj1;
}

vec4 pblOpUnionId( vec4 d1, vec4 d2 )
{
    return d1.x < d2.x ? d1 : d2;
    return min(d1,d2);
}

vec4 pblOpSubtractionId( vec4 d1, vec4 d2 )
{
    return -d1.x > d2.x ? d1 : d2;
    return max(-d1,d2);
}

float pblOpIntersectionId( float d1, float d2 )
{
    return max(d1,d2);
}

void rotate(inout vec3 p, vec3 r){
	if(r.x != 0)
		pR(p.yz, r.x);
	if(r.y != 0)
		pR(p.xz, r.y);
	if(r.z != 0)
		pR(p.xy, r.z);

	// return p;
}
void rotate(inout vec3 p, float x = PI * 2, float y = PI * 2, float z = PI * 2){
	pR(p.yz, x);
	pR(p.xz, y);
	pR(p.xy, z);

	// return p;
}

void xRot(inout vec3 p, float r){
	pR(p.yz, r);
}
void yRot(inout vec3 p, float r){
	pR(p.xz, r);
}
void zRot(inout vec3 p, float r){
	pR(p.xy, r);
}


float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

// float rand(vec2 c){
// 	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
// }

float fNoise(vec2 p, float unit ){
	// float unit = screenWidth/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*fNoise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

vec3 lerp3(vec3 a, vec3 b, float t){
	return (1 - t) * a + t * b;
}
vec4 lerp4(vec4 a, vec4 b, float t){
	return (1 - t) * a + t * b;
}
float lerp(float a, float b, float t){
	return (1 - t) * a + t * b;
}

// 2^x
int pow2(int x){
    int res = 1;
    for (int i=0;i<=31;i++){
        if (i<x){
            res *= 2;
        }
    }
    return res;
}

// a % n
float fmod(float a, int n){
    return a - (n * (a/n));
}

bool bitInt(int value, int bit){
	return ((value >> bit) & 1) == 1;
}
// return true if the bit at index bit is set
bool bitFloat(float value, int bit){

	return bitInt(floatBitsToInt(value), bit);
	
	return mod(floor((value + 0.5) / pow(2.0, float(bit))), 2.0) > 0;
	
    int bitShifts = pow2(bit);
    float bitShiftetValue = value / bitShifts;
    return fmod(bitShiftetValue, 2) > 0;
}
// a % n
int imod(int a, int n){
    return a - (n * (a/n));
}

// return true if the bit at index bit is set
// bool bitInt(int value, int bit){
	
//     int bitShifts = pow2(bit);
//     int bitShiftetValue = value / bitShifts;
//     return imod(bitShiftetValue, 2) > 0;
// }

float cbrt( float x )
{
	float y = sign(x) * uintBitsToFloat( floatBitsToUint( abs(x) ) / 3u + 0x2a514067u );

	for( int i = 0; i < NEWTON_ITER; ++i )
    	y = ( 2. * y + x / ( y * y ) ) * .333333333;

    for( int i = 0; i < HALLEY_ITER; ++i )
    {
    	float y3 = y * y * y;
        y *= ( y3 + 2. * x ) / ( 2. * y3 + x );
    }
    
    return y;
}

bool compare(float a, float b){
	// return false;
	// for(int i = 0;i < 32;i++){

	int b1 = 0;
	int b2 = 0;

	for (int i = 31; i >= 0; i--)
	{
		b1 = int(bitFloat(a, i));
		b2 = int(bitFloat(b, i));

		if(b1 + b2 == 1) break;
	}

	switch(b1 + b2){
		case 1:{
			switch(b1){
				case 1:{
					return true;
				}
				case 0:{
					return false;
				}
			}
		}
	}

	return false;
}

bool compareCheap(float a, float b){
	float c = a - b;
	return !bitFloat(c, 0);
}

Voxel fOpUnionVoxel(Voxel v1, Voxel v2){
	// return Voxel(min(v1.dist, v2.dist), v1.color);
	// return v2;a
	bool bb = false;

	// if(bitInt(t1, 0)){
	// 	return v2;
	// }

	// for(int i = 0;i < 32;i++){
	// // for(int i = 31;i >= 0;i--){
	// 	float a = v1.dist;
	// 	float b = v2.dist;
	// 	bool b1 = bitFloat(a, i);
	// 	bool b2 = bitFloat(b, i);
	// 	if(b1 != b2){
	// 		if(b1){
	// 			bb = true;
	// 			break;
	// 		}
	// 	}
	// }

	// if(bb){
	// 	return v1;
	// }else{
	// 	return v2;
	// }

	// return v2;

	// int a = int(abs(v1.dist * 10));
	// int b = int(abs(v2.dist * 10));

	// return compare(v1.dist * 1000, v2.dist * 1000) ? v2 : v1;
	// return compare(a, b) ? v1 : v2;
	// if(compare(a, b)){
	// 	a = b;
	// }else{
	// 	b = a;
	// }

	// return v2;
	// return compare(v1.iDist, v2.iDist) ? v1 : v2;

	// return ((v1.iDist) < (v2.iDist)) ? v1 : v2;
	// float f = abs(v1.dist - v2.dist);
	// if(f <= EPSILON){
	// 	return v2;
	// }
	// if(compareCheap(v1.dist, v2.dist)){
	// 	return v2;
	// }else{
	// 	return v1;
	// }
	return ((v1.dist) < (v2.dist)) ? v1 : v2;
	// return Voxel(min(v1.dist, v2.dist), 0, 0);
}

//how to pack 4 bytes values in dword
//as a side note, the order of the packed variables may be incorrect
//as I wrote this from memorydword
int PackValues (int x,int y,int z,int w){
	return (x<<24)+(y<<16)+(z<<8)+(w);
}
float pblfBoxCheap(vec3 p, vec3 b){
	return vmax(abs(p) - b);
	// return (pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
}
// Cheap Box: distance to corners is overestimated
// float fBoxCheap(vec3 p, vec3 b) { //cheap box
// 	return vmax(abs(p) - b);
// }

vec4 fOpUnionId(vec4 res1, vec4 res2){
    return (res1.x < res2.x) ? res1 : res2;
}
vec4 fOpDifferenceId(vec4 res1, vec4 res2){
    return (res1.x > -res2.x) ? res1 : vec4(
		-res2.x,
		res2.y,
		0,
		res1.y);
}
vec4 fOpDifferenceColumnsId(vec4 res1, vec4 res2, float r, float n){
    float dist = fOpDifferenceColumns(res1.x, res2.x, r, n);
    return (res1.x > -res2.x) ? vec4(dist, res1.y, 0, 0) : vec4(dist, res2.y, 0, 0);
}
vec4 fOpUnionRoundId(vec4 res1, vec4 res2, float r, float r2 = 1, float blendFactor = 0.0) {
    float dist = fOpUnionRound(res1.x, res2.x, r, r2);
	if(blendFactor != 0.0){
		return (res1.x < res2.x) ? vec4(
			dist,
			res1.y,
			// dist,
			lerp(0.5, 0.0, clamp((res2.x - res1.x) / r * blendFactor, 0, 1)),
			res2.y) : vec4(
				dist,
				res2.y,
				// 0.5,
				// dist,
				lerp(0.5, 0.0, clamp((res1.x - res2.x) / r * blendFactor, 0, 1)),
				res1.y);
	}else{
    	return (res1.x < res2.x) ? vec4(dist, res1.y, 0, res2.y) : vec4(dist, res2.y, 1, res1.y);
	}
}

float fDisplace(vec3 p, float s, float r, float t = 0){
    pR(p.yz, sin(t));
    return ((sin(p.x + (s * 2) * t) * sin(p.y + sin((s * 1) * t))) * sin(p.z + (s * 3) * t)) * r;
}

float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}
	
float simpleNoise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
  vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise3(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}


// vec3 hash3( in vec2 p )

vec4 _model(vec3 p, int modelId, vec4 rotation = vec4(0), vec3 scale = vec3(1), float materialId = -1){
    vec4 res = vec4(0);

    switch(modelId){
        case 0:{
            vec3 p1 = p + vec3(-2,1.5,0);
            float sphereR = 3 + fDisplace(p1, 1, 0.5, 29.7262 + u_time);
            // float boxDist = fBoxCheap(p1, vec3(sphereR));
            float boxDist = fSphere(p1, sphereR);
            // boxDist += bumpMapping(u_tex_01_bump, p1, p1 + sphereBumpFactor, boxDist, sphereBumpFactor, sphereScale);
            float boxId = 8.0;
            vec4 box = vec4(boxDist, boxId,0,0);
            
            p1 = p + vec3(1.5 + (sin(u_time) * 0.5),1 + sin(u_time),0);
            float boxDist2 = fSphere(p1, 2.5 + fDisplace(p * 0.5, 0.5, 1, u_time));
            float boxId2 = 9.0;
            vec4 box2 = vec4(boxDist2, boxId2,0,0);

            res = fOpUnionRoundId(box2, box, 0.5);
            break;
        }
        case 1:{
            vec4 q = rotation;
            vec3 temp = cross(q.xyz, p) + q.w * p;
            vec3 rotated = p + 2.0*cross(q.xyz, temp);
            vec3 b = vec3(2) * scale;
            float boxDist = fBoxCheap(rotated, b);
            float boxId = int(materialId) == -1 ? 7 : materialId;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
        case 2:{
            vec3 p1 = p;

            // xRot(p1, -u_time + (PI / 9.5));
            // zRot(p1, PI / 2);

            vec3 b = vec3(1, 0.5, 1);
            float boxDist = fBoxCheap(p1, b);
            float boxId = 8.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);

            // yRot(p1, PI / 4);
            boxDist = fBoxCheap(p1, b);
            vec4 box2 = vec4(boxDist, boxId, 0, 0);

            res = fOpUnionId(box, box2);

            break;
        }
        case 3:{
            vec4 q = vec4( 0.854, 0.354, 0.354, 0.146);
            vec3 temp = cross(q.xyz, p) + q.w * p;
            vec3 rotated = p + 2.0*cross(q.xyz, temp);
            // vec3 rotated = p;
            // xRot(rotated, 45);
            // yRot(rotated, 45);
            // vec3 p1 = p;
            // pMod1(p1.z, 7);
            vec3 b = vec3(2);
            float boxDist = fBoxCheap(rotated, b);
            float boxId = 7.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
        case 4:{
            vec3 p1 = p;
            pMod1(p1.z, 7);
            vec3 b = vec3(2);
            float boxDist = fSphere(p1, b.x);
            float boxId = 8.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
        case 5:{
            vec3 p1 = p;
            float b = 0.00001;
            float boxDist = fSphere(p1, b);
            float boxId = 9.0;
            vec4 box = vec4(boxDist, boxId, 0, 0);
            res = box;
            break;
        }
    }

    return res;
}



vec3 triPlanar(sampler2D tex, vec3 p, vec3 normal) {
    normal = abs(normal);
    normal = pow(normal, vec3(5.0));
    normal /= normal.x + normal.y + normal.z;
    return (texture(tex, p.xy * 0.5 + 0.5) * normal.z +
            texture(tex, p.xz * 0.5 + 0.5) * normal.y +
            texture(tex, p.yz * 0.5 + 0.5) * normal.x).rgb;
}
float bumpMapping(sampler2D tex, vec3 p, vec3 n, float dist, float factor, float scale){
	float bump = 0.0;
	if(dist < 0.1){
		vec3 normal = normalize(n);
		bump += factor * triPlanar(tex, (p * scale), normal).r;
	}

	return bump;
}

vec4 getMaterial(vec3 p, float id, vec3 normal){
    vec4 m;

    return vec4(vec3(rand(vec2(id))),1);

    switch(int(id)){
        
        case 1:{//r
            m = vec4(1.0, 0.0, 0.0, 1);
            break;
		}
        case 2:{//g
            m = vec4(0.0, 1.0, 0.0, 1);
            break;
		}
        case 3:{//b
            m = vec4(0.0, 0.0, 1.0, 1);
            break;
		}
        case 4:{//cells
            m = vec4(vec3(0.2 + 0.4 * mod(floor(p.x) + floor(p.z), 2.0)), 1);
            break;
		}
        case 5:{
            m = vec4(0.7, 0.8, 0.9, 1);
            break;
		}
        case 6:{
            m = vec4(1, 0.6, 0.0, 1);
            break;
		}
        case 7:{//texture
            // m = vec3(0);
			normal = abs(normal);
			normal = pow(normal, vec3(5.0));
			normal /= (normal.x + normal.y + normal.z);
            m = vec4(triPlanar(u_tex_01, p * (1.0 / 3.0), normal), 1);
            break;
		}
		case 8:{//noise
			m = vec4(0, 1, 0, 1);
			break;
			m *= 1 + fDisplace(p / 4, 1, 1, u_time) / 5;
			m *= 1 + pow((noise(vec2(0, u_time / 2) + (p.xz / 5))), 3);
			break;
		}
        case 9:{
            m = vec4(vec3(noise3((p * 5))), 1);
            m = vec4(1);
            
            break;
        }
        case 10:{//sand
            // float bw1 = noise(p.xz * 200);
            // float bw2 = noise((p.xz + vec2(1000, 1000)) * 100);
            // vec4 m1 = vec4(lerp3(vec3(0.99, 0.87, 0.46), vec3(1.00, 0.93, 0.55), bw1), 1);
            // vec4 m2 = vec4(lerp3(vec3(1.00, 0.83, 0.37), vec3(0.77, 0.63, 0.29), bw2), 1);
            // m = (m1 + m2) / 2;
            float bw1 = pNoise(p.xz / 2, 0);
            float bw2 = pNoise(p.xz + vec2(100,100) / 2, 0);
            bw1 = (bw1 + bw2) / 2;
            float bw3 = pNoise(p.xz * 100, 0);

            float bwres = (bw1 + bw3) / 2;
            

            vec4 m1 = vec4(lerp3(vec3(1.00, 0.83, 0.37), vec3(0.77, 0.63, 0.29) / 2, bw1), 1);
            vec4 m2 = vec4(lerp3(vec3(0.99, 0.87, 0.46), vec3(1.00, 0.93, 0.55), bw3), 1);
            m = (m1 + m2) / 2;

            // m = vec4(vec3(bwres), 1);
            // m = vec4((vec3(bw1) + vec3(bw2)) / 2, 1);
            break;
        }
    }

    return m;
}

vec4 getSpecColor(float id){
	vec4 spec = vec4(0.6, 0.5, 0.4, 1);
	// vec4 spec = vec4(0.1,0,0, 0.1);
	switch(int(id)){
		case 5: spec = vec4(vec3(0.25), 1); break;
        case 7: spec = vec4(0.6, 0.5, 0.4, 1) / 50; break;
        case 10: spec = vec4(0.6, 0.5, 0.4, 1) / 50; break;
	}

	return spec;
}



bool intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    // return vec2(tNear, tFar);

    return tNear < tFar;
    
    //no interesct
    // vec.x > vec.y
}

bool BBoxIntersect(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tbot = rayDir * (boxMin - rayOrigin);
    vec3 ttop = rayDir * (boxMax - rayOrigin);
    vec3 tmin = min(ttop, tbot);
    vec3 tmax = max(ttop, tbot);
    vec2 t = max(tmin.xx, tmin.yz);
    float t0 = max(t.x, t.y);
    t = min(tmax.xx, tmax.yz);
    float t1 = min(t.x, t.y);
    return t1 > max(t0, 0.0);
}

bool compareInt(int a, int b){
    return bitInt(a - b, 31);
}


int boxDist(ivec3 pos){
    // return int(max(max(pos.x, pos.y), pos.z));
    return abs(pos.x) + abs(pos.y) + abs(pos.z);
    // return int(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
    // return int(lengthSqr(pos));
}

Voxel rayMarchStatic(vec3 ro, vec3 rd){
	Voxel res = Voxel(ivec3(0), MAX_DIST_STATIC + 1, 0, -1, false);

    // int fori = 5 * u_object_size;
    // for(int i = 0;i < fori;i+= 5){
    //             vec3 voxPos = vec3(u_objects[i + 0], u_objects[i + 1], u_objects[i + 2]) * 2;
    //             // vec3 voxPos = vec3(i,0,0);

    //             vec3 b = vec3(1) * u_objects[i + 3];
    //             // vec3 b = vec3(0.1);
    //             // vec3 b = vec3(1) * 10;

    //             float dt = dot(rd, normalize(-ro + voxPos));
    //             // if(dt < 0.0){
    //             //     continue;
    //             // }

    //             bool voxCross = intersectAABB(ro, rd, voxPos - b, voxPos + b);

    //             if(!voxCross) continue;

    //             voxPos = voxPos;
    //             float voxDist = boxDist(voxPos - ro);
    //             float voxCol = 1;
    //             voxCol = 1;
    //             Voxel obj = Voxel(voxPos, voxDist, voxCol, dt, voxCross);

    //             res = obj.dist < res.dist ? obj : res;
    // }

    // return res;

    int edge = 10;
    // edge = int(cbrt(8));
    for(int x = 0;x < edge; x++){
        for(int y = 0;y < edge; y++){
            for(int z = 0;z < edge; z++){
                ivec3 voxPos = ivec3(x,y,z) * 2;
                vec3 voxPosF = vec3(x,y,z) * 2;

                vec3 b = vec3(1) * 0.5;

                // if(x > 0 && x < edge - 1 && y > 0 && y < edge - 1 && z > 0 && z < edge - 1) continue;

                // float dt = dot(rd, normalize(-ro + voxPos));
                // int dt = int(bitInt(floatBitsToInt(dot(rd, normalize(-ro + voxPos))), 31));
                // if(dt == 1){
                //     continue;
                // }

                bool voxCross = intersectAABB(ro, rd, voxPosF - b, voxPosF + b);
                // bool voxCross = BBoxIntersect(ro, rd, voxPosF - b, voxPosF + b);

                if(!voxCross) continue;

                voxPos = voxPos;
                int voxDist = boxDist(voxPos - u_camera_position_int);
                float voxCol = 1;
                voxCol = 1;
                Voxel obj = Voxel(voxPos, voxDist, voxCol, 0.0, voxCross);
                

                res = compareInt(obj.dist, res.dist) ? obj : res;

                //work but slow
                // res = obj.dist < res.dist ? obj : res;

                //work but toy
                // res = obj.dt > res.dt ? obj : res;
            }
        }
    }

    return res;
}




mat3 getCam(vec3 camF, vec3 camR, vec3 camU){
    return mat3(camR, camU, camF);
}

vec4 render(in vec2 uv){
    vec4 col = vec4(0,0,0,0);
    vec3 ro = u_camera_position;
    vec3 rd = getCam(u_camera_forward, u_camera_right, u_camera_up) * normalize((vec3(uv, FOV * u_mouse_wheel)));


    Voxel staticVox = rayMarchStatic(ro, rd);

    Voxel vox = staticVox;
    
        // float dt = dot(u_camera_forward, normalize(-u_camera_position - vox.pos));

    vec4 background = vec4(0.5, 0.8, 0.9, 1);
    
    // if(vox.dt >= 0.9){
    if(vox.crossed){
    // if(vox.dist < MAX_DIST_STATIC){
        col = vec4(vec3(noise3(vox.pos)),1);
    }else{
        col = background;
    }

    return col;
}

vec2 getUV(vec2 offset, float div = 1){
    return (2.0 * (gl_FragCoord.xy + offset) - (u_resolution.xy / div)) / (u_resolution.y / div);
}
vec4 renderAAx4(){
    vec4 e = vec4(0.125, -0.125, 0.375, -0.375);
    vec4 colAA = render(getUV(e.xz)) + render(getUV(e.yw)) + render(getUV(e.wx)) + render(getUV(e.zy));
    return colAA / 4.0;
}

void main()
{
    float ratio = u_resolution.x / u_resolution.y;
    vec2 resol = vec2(u_resolution.x / 4, u_resolution.x / 4 / ratio);
    // resol = u_resolution;
    vec2 uv = (0.5 * gl_FragCoord.xy - resol.xy) / resol.y;


    vec4 color = vec4(vec3(0), 1);

    color = render(uv);

    //gamma
    vec4 col = color;
    
    // vec4 col = pow(color, vec4(0.4545,0.4545,0.4545,1));

    col.w = color.w;

    fragColor = col;
}

