#include "../version.inl"

uniform sampler2D refractionTexture;
uniform sampler2D shieldTexture;
uniform sampler2D heightTexture;
uniform samplerCube fogTexture;
uniform float maxFoggyness;
uniform float fogStrength;

uniform samplerCube skyTexture;

uniform vec2 offset;
uniform float intensity;
uniform float reflectivity;
uniform float breakDown; // animation goes from 1 to 0
uniform vec3 shieldColor; // = vec3(0.5, 0.90, 1.0) * 1.8;

uniform vec3 lightDir;
uniform vec3 lightColor;
uniform vec3 eye;
uniform vec2 resolution;

in vec2 texWorld;
in vec3 position;
in vec3 tangent;
in vec3 bitangent;
in vec3 normal;

void main()
{
	// Sets the shimmer texture intensity to only 20% of normal, higher values add more "shimmer" and blur
    float intensity = intensity * 0.2;
	
	//vec3 shieldColor = vec3(0.5, 0.90, 1.0) * 1.8; // Original shield colour
	vec3 shieldColor = vec3(1); // Sets the shield colour to neutral/white

	//If low shields, then we make the shield colour a bit brighter
	vec3 dmgdShieldColor = shieldColor * 1.1;


#if defined (LOW_SHIELDS)
    outFragColor.rgb = dmgdShieldColor;
    outFragColor.a = min(1.0, intensity * 2.0);
#else
	// Distorted color - If this is removed the shields lose transparency
    vec3 distortion = texture(shieldTexture, texWorld + offset).xyz;
	vec2 texCoords = gl_FragCoord.xy / resolution + (distortion.xy - 0.5) * intensity;

	vec3 distortedColor;
    distortedColor.rgb = texture(refractionTexture, texCoords).rgb;

	//Outputs the shield colour, usually this is calculated based on several factors
	//I've set this to just use the vanilla colour and ignore the foggyness value, meaning the shield will always be it's full colour
	outFragColor.rgb = distortedColor * shieldColor.rgb;
	outFragColor.a = 1;

	//Outputs the brightness/reflectiveness?
	//Seems to affect how bright the shield is, if you set this to 1 for example it glows so bright you can't even see the ship
	//Leaving this at 0.5 (5%) makes the shield *just* visible even with the white colour, higher so that it glows a little when the shield depletes
	outFragColor.rgb += 0.05;

	//Outputs the colour of the glowing edges when the shield goes down, this is often just whiteish by default anyways, so unchanged
    float height = texture(heightTexture, texWorld * 0.5).x;
	if (height > breakDown)
	{
        outFragColor.rgb = texture(refractionTexture, gl_FragCoord.xy / resolution).rgb;
	}
	else if (height > breakDown - 0.05)
	{
		outFragColor.rgb = shieldColor * breakDown * 3.0;
	}
#endif
}
