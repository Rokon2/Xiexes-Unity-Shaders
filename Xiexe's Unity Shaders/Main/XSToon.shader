//The base of this shader was made in amplify - however it has been heavily altered. If you open this in amplify it will kill the shader, don't do it.

Shader "Xiexe/Toon/XSToon"
{
	Properties
	{
		[Toggle]_UseUV2forNormalsSpecular("Use UV2 for Normals/Specular", Float) = 0

	//Enums for all options
		[Enum(Off,0,Front,1,Back,2)] _Culling ("Culling Mode", Int) = 2
		[Enum(Horizontal,0,Vertical,1)] _RampDir ("Shadow Ramp Direction", Int) = 1
		[Enum(Sharp,0,Smooth,1,Off,2)] _RimlightType("Rimlight Type", Int) = 0
		[Enum(On,0,Off,1)] _UseReflections ("Use Reflections", Int) = 1
		[Enum(No,0,Yes,1)] _UseOnlyBakedCube ("UseBakedReflOnly", Int) = 0
		[Enum(Sharp,0,Smooth,1)] _ShadowType ("Recieved Shadow Type", Int) = 0
		[Enum(PBR,0,Stylized,1,Matcap,2,Matcap Cubemap,3)] _ReflType ("Reflection Type", Int) = 0
		[Enum(Add,0,Multiply,1,Subtract,2)] _MatcapStyle ("Matcap Blend Mode", Int) = 1
		[Enum(Dot,0,Anistropic,1)] _StylizedReflStyle ("StylizedReflStyle", Int) = 0
		[Enum(Real,0,Fake,1)] _IndirectType ("Indirect Type", Int) = 0
		
		[NoScaleOffset]_ShadowRamp("Shadow Ramp", 2D) = "white" {}
		[NoScaleOffset]_SpecularMap("Specular Map", 2D) = "black" {}
		[NoScaleOffset]_SpecularPattern("Specular Pattern", 2D) = "black" {}
		_MetallicMap("Metallic Map", 2D) = "white" {}
		_RoughMap("Rough Map", 2D) = "white" {}
		_BakedCube("Local Cubemap", Cube) = "black" {}
		_SpecularPatternTiling("Specular Pattern Tiling", Vector) = (20,20,0,0)
		_Color("Color Tint", Color) = (1,1,1,1)
		_ShadowTint("Shadow Tint", Color) = (0.5, 0.5, 0.5, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		[Normal]_Normal("Normal", 2D) = "bump" {}
		_NormalTiling("NormalTiling", Vector) = (1,1,0,0)
		_SimulatedLightDirection("Simulated Light Direction", Vector) = (0,45,90,0)
		_SpecularIntensity("Specular Intensity", Float) = 5
		_SpecularArea("Specular Area", Range( 0 , 50)) = 25
		_RimWidth("Rim Width", Range( 0 , 1)) = 0.2
		_RimIntensity("Rim Intensity", Range(0, 10)) = 0.8
		[Toggle] _Emissive("Emissive?", Float) = 0.0
		_EmissiveTex("Emissive Tex", 2D) = "white" {}
		[HDR]_EmissiveColor("Emissive Color", Color) = (0,0,0,0) 
		[HideInInspector]_Cutoff ("Cutout Amount", Float) = 0.5
		_ShadowIntensity ("ShadowIntensity", Range(0,1)) = 0.3
		_ReflSmoothness ("Reflection Smoothness", Range(0.001,1)) = 1
		_Metallic ("Metallic", Range(0,1)) = 0
		_StylelizedIntensity("Stylized Refl Intensity", Range(0,2)) = 1
		_Saturation("Saturation", Range(0.1,6)) = 1
		
	//Don't delete these or comment them out, they are needed. Not sure why as of now.
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1

	//Blending states, the editor script accesses these to change what state the material is in. They are needed.
		[HideInInspector] _mode ("__mode", Float) = 0.0
		[HideInInspector] _advMode ("__advMode", float) = 0.0
		[HideInInspector] _srcblend ("__src", Float) = 1.0
		[HideInInspector] _dstblend ("__dst", Float) = 0.0

	//Advanced Stuff
		[Header(Stencil)]
		_Offset("Offset", float) = 0
		[IntRange] _Stencil ("Stencil ID [0;255]", Range(0,255)) = 0
		_ReadMask ("ReadMask [0;255]", Int) = 255
		_WriteMask ("WriteMask [0;255]", Int) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
		[Enum(None,0,Alpha,1,Red,8,Green,4,Blue,2,RGB,14,RGBA,15)] _colormask("Color Mask", Int) = 15 


	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry" "IsEmissive" = "true"  }

		Cull [_Culling]
		ColorMask [_colormask]
		ZTest [_ZTest]
		ZWrite [_ZWrite]

		Stencil
		{
			Ref [_Stencil]
			ReadMask [_ReadMask]
			WriteMask [_WriteMask]
			Comp [_StencilComp]
			Pass [_StencilOp]
			Fail [_StencilFail]
			ZFail [_StencilZFail]
		}

		
		CGINCLUDE
		#define opaque
		#include "XSToonBase.cginc"

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		//we also need to put the cutout stuff here, otherwise emission breaks with cutout, unfortunetly it costs an extra texture sample if you're using cutout
			
			#ifdef _CUTOUT_ON
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			float4 MainTex194 = ( tex2D( _MainTex, uv_MainTex ));
			clip(MainTex194.a - _Cutoff);
			#endif
		

		//do all the emission
			float2 uv_EmissiveTex = i.uv_texcoord * _EmissiveTex_ST.xy + _EmissiveTex_ST.zw;
			float4 emissive = ( _EmissiveColor * tex2D( _EmissiveTex, uv_EmissiveTex ));
			o.Emission = emissive;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nometa
		#pragma shader_feature _ _REFLECTIONS_ON
		#pragma shader_feature _ _PBRREFL_ON 
		#pragma shader_feature _ _STYLIZEDREFLECTION_ON
		#pragma shader_feature _ _ANISTROPIC_ON
		#pragma shader_feature _ _MATCAP_ON
		#pragma shader_feature _ _MATCAP_CUBEMAP_ON


		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal( v.normal );
				fixed3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.zw = customInputData.uv2_texcoord2;
				o.customPack1.zw = v.texcoord1;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			fixed4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv2_texcoord2 = IN.customPack1.zw;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				fixed3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "XSToonEditor"
}