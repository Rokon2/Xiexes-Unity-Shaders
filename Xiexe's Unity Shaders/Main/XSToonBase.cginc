		#include "UnityStandardBRDF.cginc"
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) fixed3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			float3 worldRefl;
			float3 viewDir;
			INTERNAL_DATA
			float2 uv2_texcoord2;
			float3 worldPos;
			float4 screenPos;
			float3 tangentDir;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			fixed Alpha;
			fixed3 Tangent;
			Input SurfInput;
			UnityGIInput GIData;
		};

		 float4 _EmissiveColor;
		 sampler2D _EmissiveTex;
		 float4 _EmissiveTex_ST;
		 float _EmissiveStrength;
		 sampler2D _ShadowRamp;
		 sampler2D _Normal;
		 float2 _NormalTiling;
		 float _UseUV2forNormalsSpecular;
		 float4 _SimulatedLightDirection;
		 sampler2D _MainTex;
		 float4 _MainTex_ST;
		 float4 _Color;
		 float _RimWidth;
		 float3 _Xiexe;
		 float _RimIntensity;
		 sampler2D _SpecularMap;
		 sampler2D _SpecularPattern;
		 float2 _SpecularPatternTiling;
		 float _SpecularIntensity;
		 float _SpecularArea;
		 float _Cutoff;
		 float _RimlightType;
		 float _RampDir;
		 float _ShadowIntensity;
		 float _DitherScale;
		 float _ColorBanding;
		 float _ReflSmoothness;
		 float _Metallic;
		 sampler2D _MetallicMap;
		 sampler2D _RoughMap;
		 samplerCUBE _BakedCube;
		 float _UseReflections;
		 float _UseOnlyBakedCube;
		 float _ShadowType;
		 float _ReflType;
		 float _StylelizedIntensity;
		 float _Saturation;
		 float _MatcapStyle;
		 float3 _ShadowTint;
		 float _IndirectType;


		float3 ShadeSH9( float3 normal )
		{
			return ShadeSH9(half4(normal, 1.0));
		}

		float3 StereoWorldViewDir( float3 worldPos )
		{
			#if UNITY_SINGLE_PASS_STEREO
			float3 cameraPos = float3((unity_StereoWorldSpaceCameraPos[1]+ unity_StereoWorldSpaceCameraPos[1])*.5); 
			#else
			float3 cameraPos = _WorldSpaceCameraPos;
			#endif
			float3 worldViewDir = normalize((cameraPos - worldPos));
			return worldViewDir;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;

			half4 c = 0;
		//light and show attenuation
			#if DIRECTIONAL
			float steppedAtten = round(data.atten);
			float ase_lightAtten = lerp(steppedAtten, data.atten, _ShadowType);//data.atten;
			#else
			float3 ase_lightAttenRGB = smoothstep(0, 0.1, (gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 )));
			float ase_lightAtten = (max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b ));
			#endif

		//assign the first and second texture coordinates
			float2 texcoord1 = i.uv_texcoord;// * float2( 1,1 ) + float2( 0,0 );
			float2 texcoord2 = i.uv2_texcoord2;// * float2( 1,1 ) + float2( 0,0 );
			
		//set up uvs for all main texture maps
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;

		//swap UV sets based on if we're using UV2 or not
			float2 UVSet = lerp(texcoord1,texcoord2,_UseUV2forNormalsSpecular);
			//float2 normalUVset = (((UVSet - float2( 0.5,0.5)) * _NormalTiling) + float2(0.5,0.5));

			float3 normalMap = UnpackNormal( tex2D( _Normal, (((UVSet - float2( 0.5,0.5)) * _NormalTiling) + float2(0.5,0.5))));
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float4 worldNormals = mul(unity_ObjectToWorld,float4( ase_vertexNormal , 0.0 ));
			float4 lerpedNormals = lerp( float4( WorldNormalVector( i , normalMap ) , 0.0 ) , worldNormals , 0.3);
			float4 vertexNormals = lerpedNormals;


			float3 shadeSH9 = ShadeSH9(float4(0,0,0,1));
			float3 lightColor = (_LightColor0); 


			float3 ase_worldPos = i.worldPos;
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			float4 simulatedLight = normalize( _SimulatedLightDirection );

		//figure out whether we are in a realtime lighting scnario, or baked, and return it as a 0, or 1 (1 for realtime, 0 for baked)
			float light_Env = float(any(_WorldSpaceLightPos0.xyz));

		//we use the simulated light direction if we're in a baked scenario
			float4 light_Dir = simulatedLight;

		//otherwise, we use the actual light direction
			if( light_Env == 1)
			{
				light_Dir = float4( ase_worldlightDir , 0.0 );
			}

			//After some searching I discovered that NdotL is actually a way to hide the horrible artifacting you get from 
			//selfshadowing, which is provided by light Attenuation. So I do both a Smooth and Sharp calc for NdotL, and then
			//choose one based on the Shadow Type you choose. 
			float NdotL = dot( vertexNormals , float4( light_Dir.xyz , 0.0 ) );
			float roundedNdotL = ceil(dot( vertexNormals , float4( light_Dir.xyz , 0.0 ) )); 
			float finalNdotL = lerp(roundedNdotL, NdotL, _ShadowType);
			
			//We don't need to use the rounded NdotL for this, as all it's doing is remapping for our shadowramp. The end result should be the same with either.
			float remappedRamp = NdotL * 0.5 + 0.5;
			
			float2 horizontalRamp = (float2(remappedRamp , 0.0));
			float2 verticalRamp = (float2(0.0 , remappedRamp));
			
			float4 ase_vertex4Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float4 vertexWorldPos = mul(unity_ObjectToWorld,ase_vertex4Pos);
			float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
			float3 stereoWorldViewDir = StereoWorldViewDir(vertexWorldPos);
			float VdotN = dot(vertexNormals, float4(stereoWorldViewDir, 0.0));

		//rimlight typing
			float smoothRim = (smoothstep(0, 0.9, pow((1.0 - saturate(VdotN)), (1.0 - _RimWidth))) * _RimIntensity);
			float sharpRim = (step(0.9, pow((1.0 - saturate(VdotN)), (1.0 - _RimWidth))) * _RimIntensity);
			float FinalRimLight = lerp(sharpRim, smoothRim, _RimlightType);


	//Do reflections
		#ifdef _REFLECTIONS_ON
		
		//making variables for later use for texture sampling. We want to create them empty here, so that we can save on texture samples by only
		//sampling when we need to, we assign the texture samples as needed. I.E. We don't need the metallic map for the stylized reflections, so why sample it?
			float4 reflection = float4(0,0,0,0);
			float4 metalMap = float4(0,0,0,0);
			float4 roughMap = float4(0,0,0,0);

		//reflectedDir = reflections bouncing off the surface into the eye
			float3 reflectedDir = reflect(-viewDir, vertexNormals);
		//reflectionDir = reflections bouncing off of the eye as if it were the light source
			float3 reflectionDir = reflect(-light_Dir, vertexNormals);

		//PBR
			#ifdef _PBRREFL_ON
				metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
				roughMap = tex2D(_RoughMap, uv_MainTex);
				float roughness = saturate((_ReflSmoothness * roughMap.r));
				reflection = (UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectedDir, roughness * 6));
					
				if (any(reflection.xyz) == 0)
					{
						reflection = texCUBElod(_BakedCube, float4(reflectedDir, roughness * 6));
					}
				#endif
		//Stylized	
				#ifdef _STYLIZEDREFLECTION_ON
					#ifdef _ANISTROPIC_ON
					//Anistropic Stripe
						float3 tangent = i.tangentDir;
						half3 h = normalize(light_Dir + viewDir);
						float ndh = max(0, dot (vertexNormals, h));
						half3 binorm = cross(vertexNormals, tangent);
						fixed ndv = dot(viewDir, vertexNormals);
						float aX = dot(h, tangent) / 0.75;
						float aY = dot(h, binorm) / _Metallic;
						reflection = sqrt(max(0.0, NdotL / ndv)) * exp(-2.0 * (aX * aX + aY * aY) / (1.0 + ndh)) * (_ReflSmoothness) * 2.0;
						reflection = ceil(smoothstep(0.5-_ReflSmoothness*0.5, 0.5+_ReflSmoothness*0.5, reflection));
					#else
					//Dot Stylized	
						metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
						float reflectionUntouched = step(0.9, (pow(DotClamped(stereoWorldViewDir, reflectionDir), ((1-_ReflSmoothness))))) * metalMap;
						reflection = (round(reflectionUntouched * 10) / 10);
					#endif
				#endif
		//Matcap	
				#ifdef _MATCAP_ON
					roughMap = tex2D(_RoughMap, uv_MainTex);
					#ifdef _MATCAP_CUBEMAP_ON
						reflection = texCUBElod(_BakedCube, float4(reflectedDir, _ReflSmoothness * 6));
					#else
						float2 remapUV = (mul(UNITY_MATRIX_V, float4(vertexNormals.xyz, 0)).xy * 0.5 + 0.5);
						reflection = tex2Dlod(_MetallicMap, float4(remapUV,0, (_ReflSmoothness * 6)));
					#endif
				#endif
			#endif

		//Recieved Shadows and lighting
			float4 shadowRamp = tex2D( _ShadowRamp, float2(remappedRamp,remappedRamp));	
			//we initialize finalshadow here, but we will be editing this based on the lighting env below
			float finalShadow = saturate(((ase_lightAtten * .5) - (1-shadowRamp.r)));
			float realtimeShadows = saturate(1-finalShadow);

		//We default to baked lighting situations, so we use these values
			//FakeAmbient or RealAmbient
			float3 fakeindirectLight = length(shadeSH9) * _ShadowTint;
			float3 realindirectLight = shadeSH9;

			float3 indirectLight = lerp(realindirectLight, fakeindirectLight, _IndirectType);
			
			
			float3 finalLight = indirectLight * (shadowRamp + ((1-_ShadowIntensity) * (1-shadowRamp)));

		//If our lighting environment matches the number for realtime lighting, use these numbers instead
			if (light_Env == 1) 
			{
				finalShadow = saturate(((finalNdotL * ase_lightAtten * .5) - (1-shadowRamp.r)));
				lightColor = lightColor * (finalShadow);
				finalLight = lightColor + (indirectLight);
			}
		//get the main texture and multiply it by the color tint, and do saturation on the main texture
			float4 MainTex = pow(tex2D( _MainTex, uv_MainTex ), _Saturation);
			float4 MainColor = MainTex * _Color;
		
		//grab the specular map texture sample, get the dot product of the vertex normals vs the stereo correct view direction, and create specular reflections and a rimlight based on that and a texture we feed in.
			float4 specularMap = tex2D( _SpecularMap, UVSet );
			float NdotV = dot(reflect(light_Dir , vertexNormals), float4((stereoWorldViewDir * -1.0), 0.0));
		//clean this
			float specularRefl = (((specularMap.g * (1.0 - specularMap.r)) * tex2D(_SpecularPattern, (((UVSet - float2( 0.5,0.5)) * _SpecularPatternTiling) + float2(0.5,0.5))).r) * (_SpecularIntensity * 2) * saturate(pow(saturate(NdotV) , _SpecularArea)));
		
		//calculate the final lighting for our lighting model
			//Change this as well, not sure why I'm doing any of the adding 0.5 and such. Seems weird. 
			float3 finalAddedLight = ( (FinalRimLight + (specularRefl)) * saturate((saturate(MainColor + 0.5) * pow(finalLight, 2) * (shadowRamp)))).rgb;
		    float3 finalColor = MainColor;

		//if we have reflections turned on, return the final color with reflections
			#ifdef _REFLECTIONS_ON
			//Do PBR
				#ifdef _PBRREFL_ON
					float3 finalreflections = (reflection * (MainColor * 2));
					finalColor = (MainColor * ((1-_Metallic) * (1-metalMap.r))) + finalreflections;
				#endif
			//Do Stylized
				#ifdef _STYLIZEDREFLECTION_ON
					finalColor = MainColor + ((reflection * ((MainColor) * finalLight)) * _StylelizedIntensity);
				#endif
			//Do Matcap
				#ifdef _MATCAP_ON
					metalMap = (tex2D(_MetallicMap, uv_MainTex) * _Metallic);
				//Additive
					if(_MatcapStyle == 0)
					{
						finalColor = MainColor + (reflection * _Metallic * (roughMap.r));
					}
				//Multiplicitive
					if(_MatcapStyle == 1)
					{
						finalColor = MainColor * (reflection * _Metallic * (roughMap.r));
					}
				//Subtractive
					if(_MatcapStyle == 2)
					{
						finalColor = MainColor - (reflection * _Metallic * (roughMap.r));
					} 
				#endif
			#endif

		//return the RGB of all the stuff from above as c	
			c.rgb = finalColor * (finalLight + finalAddedLight);
		
		//get the alpha, based on if we have cutout, or alphablending enabled from our editor script, and finally return everything
            #ifdef opaque
        		c.a = 1;
            #endif
			
		//alphablend
            #ifdef alphablend
				c.a = (MainTex.a * _Color.a);
            #endif

		//cutout
			#ifdef cutout
				clip(MainTex.a - _Cutoff);
				c.a = 1;
			#endif

		//dithered
			#ifdef dithered
				 // Screen-door transparency: Discard pixel if below threshold.
				 // This may be replaced in the future, as there are better ways to do this. 
    			float4x4 thresholdMatrix =
    			{  1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
    			  13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
    			   4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
    			  16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
   				};
   				float4x4 _RowAccess = { 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 };
				float2 screenPos = i.screenPos.xy;
				float2 pos = screenPos / i.screenPos.w;
				pos *= _ScreenParams.xy; // pixel position
   					
				 #ifdef UNITY_SINGLE_PASS_STEREO
				 	clip((MainTex.a * _Color.a) - thresholdMatrix[fmod((pos.x * 2), 4)] * _RowAccess[fmod(pos.y, 4)]);
				 #else
					clip((MainTex.a * _Color.a) - thresholdMatrix[fmod(pos.x, 4)] * _RowAccess[fmod(pos.y, 4)]);
				 #endif

			#endif

			return c;
		}