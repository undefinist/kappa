#define POISSON_BIAS 1.f/ 700.f
#define DIVISIBLE_FACTOR 1.f/14.f

vec3 fresnel(float cos_theta, vec3 f0)
{
	return f0 + (vec3(1.f) - f0) * pow(1.f - cos_theta, 5.f);
}

vec3 fresnelRoughness(float cos_theta, vec3 f0, float roughness)
{
	return f0 + (vec3(1.f - roughness) - f0) * pow(1.f - cos_theta, 5.f);
}

float DistributionGGX(vec3 normal, vec3 half_vec, float roughness)
{
	float alpha  = roughness * roughness;
	float alpha2 = alpha * alpha;
	float NdotH  = max(dot(normal, half_vec), 0.f);
	float NdotH2 = NdotH * NdotH;
	
	float numer  = alpha2;
	float denom  = (NdotH2 * (alpha2 - 1.f) + 1.f);
	denom = PI * denom * denom;
	
	return numer / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
	float r = roughness + 1.f;
	float k = r *r / 8.f;
	
	float numer = NdotV;
	float denom = NdotV * (1.f - k) + k;
	
	return numer / denom;
}

float GeometrySmith(vec3 normal, vec3 view, vec3 light, float roughness)
{
	float NdotV = max(dot(normal, view), 0.f);
	float NdotL = max(dot(normal, light), 0.f);
	
	float ggx2 = GeometrySchlickGGX(NdotV, roughness);
	float ggx1 = GeometrySchlickGGX(NdotL, roughness);
	
	return ggx1 * ggx2;
}

//vec2 sampleOffsetDirections[8] = vec2[]
//(
//   vec3( 1,  1), vec3( 1, -1), vec3(-1, -1), vec3(-1,  1), 
//   vec3( 1,  0), vec3(-1,  0), vec3( 0,  1), vec3( 0, -1)
//);  

vec3 sampleOffsetDirections[20] = vec3[]
(
   vec3( 1,  1,  1), vec3( 1, -1,  1), vec3(-1, -1,  1), vec3(-1,  1,  1), 
   vec3( 1,  1, -1), vec3( 1, -1, -1), vec3(-1, -1, -1), vec3(-1,  1, -1),
   vec3( 1,  1,  0), vec3( 1, -1,  0), vec3(-1, -1,  0), vec3(-1,  1,  0),
   vec3( 1,  0,  1), vec3(-1,  0,  1), vec3( 1,  0, -1), vec3(-1,  0, -1),
   vec3( 0,  1,  1), vec3( 0, -1,  1), vec3( 0, -1, -1), vec3( 0,  1, -1)
);  

float computePCF(samplerCube tex, vec3 tc, vec2 texelSize, float tc_z, float bias, float curDepth, float far_plane)
{
	//float z_depth = tc_z/tc.w;
	
	float diskRadius = 0.05f;
	
	float avgDepth = 0.f;
	float biasedCDepth = curDepth - bias;
	for(int i = 0; i < 20; ++i)
	{
		float sampleShadow = texture(tex, tc + sampleOffsetDirections[i] * diskRadius).r;
		sampleShadow *= far_plane;   // Undo mapping [0;1]
		if(biasedCDepth > sampleShadow)
			avgDepth += 1.f;
	}
		
	return avgDepth;
}  

float computePCF(sampler2D tex, vec2 tc, vec2 texelSize, float tc_z, float bias, float curDepth, int x)
{
	//float z_depth = tc_z/tc.w;
	
	vec4 sampleShadow = texture(tex,  tc + vec2(x,-1) * texelSize);
	vec4 sampleShadow1 = texture(tex, tc + vec2(x,0) * texelSize );
	vec4 sampleShadow2 = texture(tex, tc + vec2(x,1) * texelSize );
	
	float avgDepth = 0.f, biasedCDepth = curDepth - bias;
	if(biasedCDepth > sampleShadow.r) 
		avgDepth = 1.f;
	
	if(biasedCDepth > sampleShadow1.r) 
		avgDepth += 1.f;
	
	if(biasedCDepth > sampleShadow2.r) 
		avgDepth += 1.f;
		
	return avgDepth;
} 

vec2 poissonDisk[16] = vec2[]( 
   vec2( -0.94201624, -0.39906216 ), 
   vec2( 0.94558609, -0.76890725 ), 
   vec2( -0.094184101, -0.92938870 ), 
   vec2( 0.34495938, 0.29387760 ), 
   vec2( -0.91588581, 0.45771432 ), 
   vec2( -0.81544232, -0.87912464 ), 
   vec2( -0.38277543, 0.27676845 ), 
   vec2( 0.97484398, 0.75648379 ), 
   vec2( 0.44323325, -0.97511554 ), 
   vec2( 0.53742981, -0.47373420 ), 
   vec2( -0.26496911, -0.41893023 ), 
   vec2( 0.79197514, 0.19090188 ), 
   vec2( -0.24188840, 0.99706507 ), 
   vec2( -0.81409955, 0.91437590 ), 
   vec2( 0.19984126, 0.78641367 ), 
   vec2( 0.14383161, -0.14100790 ) 
);

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898f,78.233f))) * 43758.5453f);
}

float computeStratifiedPoisson(sampler2D shadow_tex, vec2 tc, vec2 texelSize, float tc_z, float bias, int x)
{
	//int index = x;
	//float z_depth = tc_z/tc.w;
	
	int index = int(16.f*rand(tc*x))%16;
	vec2 poissonTC = poissonDisk[index] * POISSON_BIAS;
	vec2 tcc = tc + poissonTC;
	vec4 sampleShadow = texture(shadow_tex,tcc + vec2(x,-1) * texelSize);
	vec4 sampleShadow1 = texture(shadow_tex,tcc + vec2(x,0) * texelSize);
	vec4 sampleShadow2 = texture(shadow_tex,tcc + vec2(x,1) * texelSize);
	
	//0.2f*(1.f - sampleShadow) - 0.2f*(1.f - sampleShadow1) - 0.2f*(1.f - sampleShadow2)
	//return 0.2f*(-1.f + (-sampleShadow.r + sampleShadow1.r + sampleShadow2.r));
	
	return 0.2f*(3.f-sampleShadow.r - sampleShadow1.r - sampleShadow2.r);
}

//float computeStratifiedPoisson(samplerCube shadow_tex, vec2 tc, vec2 texelSize, float tc_z, float bias, int x)
//{
//	//int index = x;
//	//float z_depth = tc_z/tc.w;
//	
//	int index = int(16.f*rand(tc*x))%16;
//	vec2 poissonTC = poissonDisk[index] * POISSON_BIAS;
//	vec2 tcc = tc + poissonTC;
//	vec4 sampleShadow = texture(shadow_tex,tcc + vec2(x,-1) * texelSize);
//	vec4 sampleShadow1 = texture(shadow_tex,tcc + vec2(x,0) * texelSize);
//	vec4 sampleShadow2 = texture(shadow_tex,tcc + vec2(x,1) * texelSize);
//	
//	//0.2f*(1.f - sampleShadow) - 0.2f*(1.f - sampleShadow1) - 0.2f*(1.f - sampleShadow2)
//	//return 0.2f*(-1.f + (-sampleShadow.r + sampleShadow1.r + sampleShadow2.r));
//	
//	return 0.2f*(3.f-sampleShadow.r - sampleShadow1.r - sampleShadow2.r);
//}
 
 
vec3 ShadowCoords(vec4 fPosInLS)
{
	//Transformation of proj coord to NDC[0,1]
	 // perform perspective divide
	 fPosInLS.xyz=fPosInLS.xyz/fPosInLS.w;
    vec3 projCoords = fPosInLS.xyz *0.5f + 0.5f;
	
	return projCoords ;
}
float ShadowCalculation(Light light, sampler2D shadow_tex , vec3 lightDir , vec3 normal,vec4 fPosInLS)
{
	vec3 projCoords = ShadowCoords(fPosInLS);
	
	//Oversampling check
	if(projCoords.x > 0.f && projCoords.y > 0.f && projCoords.z <= 1.f)
	{					
		{//Other
						
			float curDepth = projCoords.z;
				
			//Bias calculation
			//float bias = max(0.005f * (1.0f - dot(normal,lightDir)),0.009f);
			float bias = light.shadow_bias;
			
			//PCF
			float avgDepth = 0.f;
			//float	tDepth=0.f;
			vec2 texelSize = textureSize(shadow_tex,0);
			texelSize = 1.f/texelSize;
			float tc_z = projCoords.z - bias;
			vec2 pc = projCoords.xy;
			
			
			for(int x = -2; x <= 2; ++x)
			{		
				avgDepth += computePCF(shadow_tex,pc, texelSize,tc_z,bias,curDepth,x);
				avgDepth -= computeStratifiedPoisson(shadow_tex,pc,texelSize, tc_z, bias,x);
			}

			
			//divide by 9 values
			avgDepth *= DIVISIBLE_FACTOR;
			
			return avgDepth;
		}
	}else{
		return 0.0f;
	}
	//return 0;
	//return 0;
}

float ShadowCalculation(Light light, samplerCube shadow_tex , vec3 lightDir , vec3 normal,vec4 fPosInLS, float far_plane, vec3 light_pos)
{

	vec3 projCoords = fPosInLS.xyz;
	
	vec3 fragToLight = projCoords - light_pos; 
    float closestDepth = texture(shadow_tex, fragToLight).r;
	closestDepth *= far_plane;
	
	if(closestDepth>0.f)	
	{//Other
	
		//Oversampling check	
		if(closestDepth > 1.0f)
			return 0.f;
			
		float curDepth = length(fragToLight);
			
		//Bias calculation
		//float bias = max(0.005 * (1.0 - dot(normal,lightDir)),0.009);
		float bias = light.shadow_bias;
		
		//PCF
		float avgDepth = 0.f;
		//float	tDepth=0.f;
		vec2 texelSize = textureSize(shadow_tex,0);
		texelSize = 1.f/texelSize;
		float tc_z = closestDepth - bias;
		//vec3 pc = projCoords.xy;
		
		
		for(int x = -1; x <= 1; ++x)
		{		
			avgDepth += computePCF(shadow_tex,fragToLight, texelSize,tc_z,bias,curDepth,far_plane);
			//avgDepth -= computeStratifiedPoisson(shadow_tex,fragToLight,texelSize, tc_z, bias,far_plane);
		}

		
		//divide by 9 values
		avgDepth *= DIVISIBLE_FACTOR;
		
		return avgDepth;
	}
	else
	{
		return 0.f;
	}
	
	//return 0;
	//return 0;
}





vec3 pbr_metallic(
	Light light
,	vec3  view_pos
,	vec3  normal
,   vec3  reflected
,	vec3  albedo
,	float metallic
,	float roughness
,	float ambient_o
)
{
//Gamma uncorrection
#ifndef VULKAN
	albedo = pow(albedo, vec3(2.2f));
#endif
// temporary light code
	
	vec3  frag_to_light = (vec4(light.v_pos,1)).xyz - view_pos;
	vec3  light_dir =	frag_to_light;

	
	
	float dist      =  length(frag_to_light); 
	
	if (light.type != 0) light_dir = -light.v_dir;
	if (light.type != 1) light_dir /= dist;

	
	vec3  view_dir  = -normalize(view_pos); // camera is at 0
	vec3  half_vec  =  normalize(view_dir + light_dir);
	
	float atten = 1.f;
	
	float spotlight_effect =1.f;
	
	if(light.type==2)
	{
	
		float cos_alpha= dot(normalize((frag_to_light)),normalize(light_dir));
	    float cos_phi  = light.cos_outer;
	    float cos_theta  = light.cos_inner;
		spotlight_effect = min(pow(((cos_alpha - cos_phi)/(cos_theta - cos_phi)),1),1);
        spotlight_effect = (cos_alpha<cos_phi)?0:spotlight_effect;
	}
	if (light.type != 1) atten = pow(max(light.falloff-dist,0)/light.falloff,3);//atten = (1.f/light.falloff)/(dist*dist);
	
	atten = min(max(atten, 0),1);
	
	vec3 radiance = light.color.rgb * atten * spotlight_effect;
	
	const vec3 f0 = vec3(0.04f);
	vec3 F = fresnel(min(max(dot(half_vec, view_dir), 0.0),1), mix(f0, albedo, metallic));
	
	float ndf = DistributionGGX(normal, half_vec, roughness);
	float G   = GeometrySmith(normal, view_dir, light_dir, roughness);
	
	vec3  numer = ndf * G * F;
	float denom = 4.0f * max(dot(normal, view_dir), 0.0) * max(dot(normal, light_dir), 0.0);
	vec3 specular = numer / max(denom, 0.001f);
	
	vec3 kS = F;
	vec3 kD = vec3(1.0f) - kS;
	
	float NdotL = max(dot(normal, light_dir), 0.0);
	
	kD *= 1.0f - metallic;
	
	//return vec3(cos_alpha*0.5 +0.5);
	return (kD * albedo / PI + specular) * radiance * NdotL;
}




vec3 pbr_specular(
	Light light
,	vec3  view_pos
,	vec3  normal
,   vec3  reflected
,	vec3  albedo
,	float specular
,	float roughness
,	float ambient_o
)
{
#ifndef VULKAN
	albedo = pow(albedo, vec3(2.2f));
#endif
	//specular = pow(specular, 2.2);
// temporary light code
	
	vec3  frag_to_light = (vec4(light.v_pos,1)).xyz - view_pos;
	vec3  light_dir =	frag_to_light;

	
	
	float dist      =  length(frag_to_light); 
	
	if (light.type != 0) light_dir = -light.v_dir;
	if (light.type != 1) light_dir /= dist;

	
	vec3  view_dir  = -normalize(view_pos); // camera is at 0
	vec3  half_vec  =  normalize(view_dir + light_dir);
	
	float atten = 1;
	
	float spotlight_effect =1.f;
	
	if(light.type==2)
	{
	
		float cos_alpha= dot(normalize((frag_to_light)),normalize(light_dir));
	    float cos_phi  = light.cos_outer;
	    float cos_theta  = light.cos_inner;
		spotlight_effect = min(pow(((cos_alpha - cos_phi)/(cos_theta - cos_phi)),0.5f),1);
        spotlight_effect = (acos(cos_alpha)>acos(cos_phi))?0:spotlight_effect;
	}
	if (light.type != 1) atten = (1.f/light.falloff)/(dist*dist);
	
	atten = min(max(atten, 0),1);
	
	vec3 radiance = light.color.rgb * atten * spotlight_effect;
	
	//const vec3 f0 = vec3(0.04f);
	//vec3 F = fresnel(min(max(dot(half_vec, view_dir), 0.0),1), mix(f0, albedo, specular));
	vec3 f0 = vec3(specular);
	vec3 F = fresnel(min(max(dot(half_vec, view_dir), 0.0),1), mix(f0, albedo, 0.5f));
	//vec3 F = f0;
	
	float ndf = DistributionGGX(normal, half_vec, roughness);
	float G   = GeometrySmith(normal, view_dir, light_dir, roughness);
	
	vec3  numer = ndf * G * F;
	float denom = 4.0 * max(dot(normal, view_dir), 0.0) * max(dot(normal, light_dir), 0.0);
	vec3 specular_color = numer / max(denom, 1e-10);
	
	float kD = 1.0f - specular;
	
	float NdotL = max(dot(normal, light_dir), 0.0);
	
	return (kD * albedo + specular_color) * radiance * NdotL;
}