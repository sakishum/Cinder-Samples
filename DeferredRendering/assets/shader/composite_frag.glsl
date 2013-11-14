#version 110

varying vec4		vVertex;
varying vec3		vNormal;
varying vec3		vTangent;
varying vec3		vBiTangent;

uniform	sampler2D	uDiffuseMap;
uniform	sampler2D	uSpecularMap;
uniform	sampler2D	uNormalMap;
uniform	sampler2D	uEmmisiveMap;
uniform	sampler2D	uSSAOMap;

uniform bool		uHasDiffuseMap;
uniform bool		uHasSpecularMap;
uniform bool		uHasNormalMap;
uniform bool		uHasEmmisiveMap;

uniform bool		bShowNormalMap;

uniform vec4		uScreenParams;

void main()
{
	vec3	vToCamera = normalize(-vVertex.xyz);

	// fetch the normal from the normal map and modify it using the normal (and tangents) from the 3D mesh
	vec3	vMappedNormal = texture2D(uNormalMap, gl_TexCoord[0].st).rgb * 2.0 - 1.0;
	vec3	vSurfaceNormal = uHasNormalMap ? normalize((vTangent * vMappedNormal.x) + (vBiTangent * vMappedNormal.y) + (vNormal * vMappedNormal.z)) : vNormal;
		
	// calculate ambient term
	vec2	vTexCoord = gl_FragCoord.xy * uScreenParams.zw + uScreenParams.xy;
	float	fAmbient = pow(texture2D(uSSAOMap, vTexCoord).r, 0.75);	// non-standard attenuation of SSAO

	// apply each of our light sources
	vec4	vAmbientColor	= vec4(0, 0, 0, 1);
	vec4	vDiffuseColor	= uHasEmmisiveMap ? texture2D(uEmmisiveMap, gl_TexCoord[0].st) : vec4(0, 0, 0, 1);
	vec4	vSpecularColor	= vec4(0, 0, 0, 1);  

	for(int i=0; i<2; ++i)
	{
		// calculate view space light vectors (for directional light source)
		vec3	vToLight = normalize(-gl_LightSource[i].position.xyz); 
		vec3	vReflect = normalize(-reflect(vToLight,vSurfaceNormal));

		// calculate diffuse term
		float	fDiffuse = max(dot(vSurfaceNormal,vToLight), 0.0);
		fDiffuse = clamp(fDiffuse, 0.1, 1.0) * fAmbient;		// non-standard application of SSAO

		// calculate specular term
		float	fSpecularPower = 100.0;
		float	fSpecular = pow( max( dot(vReflect, vToCamera), 0.0), fSpecularPower );
		fSpecular = clamp(fSpecular, 0.0, 1.0);

		// calculate final colors
		//vAmbientColor += gl_LightSource[i].ambient * fAmbient;

		if(uHasDiffuseMap)
			vDiffuseColor += texture2D(uDiffuseMap, gl_TexCoord[0].st) * gl_LightSource[i].diffuse * fDiffuse;
		else
			vDiffuseColor += gl_LightSource[i].diffuse * fDiffuse; 

		if(uHasSpecularMap)
			vSpecularColor += texture2D(uSpecularMap, gl_TexCoord[0].st) * gl_LightSource[i].specular * fSpecular;
		else
			vSpecularColor += gl_LightSource[i].specular * fSpecular; 
	}

	// output colors to buffer
	gl_FragColor.rgb = bShowNormalMap ? vSurfaceNormal : (vAmbientColor + vDiffuseColor + vSpecularColor).rgb;
	gl_FragColor.a = 1.0;
}