using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;
using System;

public class XSToonEditor : ShaderGUI
{
    public enum BlendMode
    {
        Opaque,
        Cutout
    }

    public enum DisplayType
    {
        Basic,
        Advanced
    }

    // Styles for most options on the texture - shows name and mouseover description
    //public static GUIContent nameText = new GUIContent("name", "desc");
    private static class Styles
    {
        public static GUIContent version = new GUIContent("XSToon v1.3.2 DEV", "The currently installed version of XSToon.");
        public static GUIContent mainText = new GUIContent("Main Options", "The main options for the Shader");
        public static GUIContent rampText = new GUIContent("Shadow Ramp", "Shadow ramp texture, horizontal or vertical, Black to White gradient that controls how shadows look - examples are included in the Shadow Ramps folder");
        public static GUIContent specMapText = new GUIContent("Specular Map", "Specular Map, This controls where the specular pattern can show. Should be a black and white image");
        public static GUIContent specPatternText = new GUIContent("Specular Pattern", "Specular Pattern, This is the pattern that shows in specular reflections. Control how much shows with the Smoothness and Intensity");
        public static GUIContent MainTexText = new GUIContent("Main Texture", "Main texture (RGB) and Transparency (A)");
        public static GUIContent normalText = new GUIContent("Normal Map", "Normal Map, used for controlling how light bends to fake small details, such as a cloth pattern");
        public static GUIContent emissText = new GUIContent("Emissive Map", "The texture used to control where emission happens, I recommend a black and white image, white for on, black for off");
        public static GUIContent simLightText = new GUIContent("Light Direction", "The fake lighting direction. This will only show if you disable all realtime lights in your scene. The shader detects if there is no realtime light, and uses this as a fake direction for lighting automatically");
        public static GUIContent SmoothnessText = new GUIContent("Area", "How smooth the material is - this affects the size of the area that the pattern shows when reflecting light");
        public static GUIContent sintensityText = new GUIContent("Intensity", "The intensity of the specular reflections, higher is more visible");
        public static GUIContent stilingText = new GUIContent("Tiling", "The tiling of the specular reflection's pattern, used to make the pattern smaller or larger");
        public static GUIContent rimWidthText = new GUIContent("Rim Width", "The width of the rimlight, there is no catch-all value - you will probably need to figure out what works on a per model basis");
        public static GUIContent rimIntText = new GUIContent("Rim Intensity", "The intensity of the rimlight, this is how bright this rimlight is in comparison to the main texture");
        public static GUIContent rimLightTypeText = new GUIContent("Rim Style", "The style of rimlight, which is an edge light around the model in the lit up areas, sharp or smooth.");
        public static GUIContent cullingModeText = new GUIContent("Culling Mode", "Changes which side of the mesh is visible. Off is two-sided.");
        public static GUIContent cutoutText = new GUIContent("Cutout Amount", "This option only works on the 'Cutout' varient of the shader, and will do nothing on the others.");
        public static GUIContent advancedOptions = new GUIContent("Advanced Options", "This is where advanced options will go, anything that isn't part of the base experience, they are not for the faint of heart. Don't break anything :)");
        public static GUIContent MetalMap = new GUIContent("Metallic Map", "Black to white texture that defines areas that can be metallic, full white = full metallic, full black = no metallic, if you use this, set Metallic to 0");
        public static GUIContent roughMap = new GUIContent("Roughness Map", "Black to white texture that defines the roughness of the object white = 100% rough, black = 100% smooth. If you use this, set Roughness to 1");
        public static GUIContent bakedCube = new GUIContent("Baked Cubemap", "This is the cubemap that will be sampled for reflections if there are no reflection probes in the scene, if there are, the shader will sampler those instead.");
        public static GUIContent shadowTypeText = new GUIContent("Shadow Style", "Received Realtime Shadow style, sharp or smooth, match this up with your shadow ramp for optimal results.");
        public static GUIContent ReflMask = new GUIContent("Reflection Mask","Mask for reflections, the same as the metallic mask, black to white image.");
        public static GUIContent StyleIntensity = new GUIContent("Intensity", "The intensity of the stylized reflection.");
        public static GUIContent Saturation = new GUIContent("Saturation", "Saturation of the main texture.");
        public static GUIContent Matcap = new GUIContent("Matcap Texture", "A matcap texture. These generally look like orbs with some sort of lighting on them. You can find some in 'Textures > Matcap' as examples.");
        public static GUIContent normalTiling = new GUIContent("Tiling", "Normal map tiling, adjust the X and Y to make the normals larger or smaller.");
        public static GUIContent MatcapCubemap = new GUIContent("Matcap Cubemap", "A Cubemap generated by a matcap texture. This can be done by selecting the texture and changing the type to 'cubemap' in the inspector.");
        public static GUIContent MatcapMask = new GUIContent("Matcap Mask","The mask for the matcap. Black for off, white for on.");
    }
    
    void DoFooter(){
        GUILayout.Label(Styles.version, new GUIStyle(EditorStyles.centeredGreyMiniLabel)
        {
            alignment = TextAnchor.MiddleCenter,
            wordWrap = true,
            fontSize = 12
        });
    }

    MaterialProperty shadowRamp;
    MaterialProperty specMap;
    MaterialProperty specPattern;
    MaterialProperty specTiling;
    MaterialProperty tint;
    MaterialProperty mainTex;
    MaterialProperty normal;
    MaterialProperty simLightDir;
    MaterialProperty specIntensity;
    MaterialProperty specArea;
    MaterialProperty rimWidth;
    MaterialProperty rimIntensity;
    MaterialProperty emissiveToggle;
    MaterialProperty emissiveTex;
    MaterialProperty emissiveColor;
    MaterialProperty blendMode;
    MaterialProperty advMode;
    MaterialProperty alphaCutoff;
    MaterialProperty culling;
    MaterialProperty rampDir;
    MaterialProperty rimStyle;
    MaterialProperty uv2;
    MaterialEditor m_MaterialEditor;

    //advanced
    MaterialProperty colorMask;
    MaterialProperty stencil;
    MaterialProperty readMask;
    MaterialProperty writeMask;
    MaterialProperty stencilComp;
    MaterialProperty stencilOp;
    MaterialProperty stencilFail;
    MaterialProperty stencilZFail;
    MaterialProperty ztest;
    MaterialProperty zwrite;
    MaterialProperty shadowIntensity;
    MaterialProperty reflSmooth;
    MaterialProperty metal;
    MaterialProperty metalMap;
    MaterialProperty roughMap;
    MaterialProperty bakedCube;
    MaterialProperty useRefl;//_UseReflections
    MaterialProperty bakedReflOnly;//_UseOnlyBakedCube
    MaterialProperty shadowType;
    MaterialProperty reflType;
    MaterialProperty saturation;
    MaterialProperty styleIntensity;
    MaterialProperty matcapStyle;
    MaterialProperty normalTiling;
    MaterialProperty stylizedType;
    MaterialProperty shadowTint;
    MaterialProperty IndirectType;
    public Texture m_EmptyTexture;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {


        Material material = materialEditor.target as Material;
        {
            //Find all the properties within the shader
            shadowRamp = ShaderGUI.FindProperty("_ShadowRamp", props);
            specMap = ShaderGUI.FindProperty("_SpecularMap", props);
            specPattern = ShaderGUI.FindProperty("_SpecularPattern", props);
            specTiling = ShaderGUI.FindProperty("_SpecularPatternTiling", props);
            tint = ShaderGUI.FindProperty("_Color", props);
            mainTex = ShaderGUI.FindProperty("_MainTex", props);
            normal = ShaderGUI.FindProperty("_Normal", props);
            simLightDir = ShaderGUI.FindProperty("_SimulatedLightDirection", props);
            specIntensity = ShaderGUI.FindProperty("_SpecularIntensity", props);
            specArea = ShaderGUI.FindProperty("_SpecularArea", props);
            rimWidth = ShaderGUI.FindProperty("_RimWidth", props);
            rimIntensity = ShaderGUI.FindProperty("_RimIntensity", props);
            emissiveToggle = ShaderGUI.FindProperty("_Emissive", props);
            emissiveTex = ShaderGUI.FindProperty("_EmissiveTex", props);
            emissiveColor = ShaderGUI.FindProperty("_EmissiveColor", props);
            alphaCutoff = ShaderGUI.FindProperty("_Cutoff", props);
            culling = ShaderGUI.FindProperty("_Culling", props);
            rampDir = ShaderGUI.FindProperty("_RampDir", props);
            rimStyle = ShaderGUI.FindProperty("_RimlightType", props);
            uv2 = ShaderGUI.FindProperty("_UseUV2forNormalsSpecular", props);
            blendMode = ShaderGUI.FindProperty("_mode", props);
            advMode = ShaderGUI.FindProperty("_advMode", props);
            shadowIntensity = ShaderGUI.FindProperty("_ShadowIntensity", props);
            reflSmooth = ShaderGUI.FindProperty("_ReflSmoothness", props);
            metal = ShaderGUI.FindProperty("_Metallic", props);
            metalMap = ShaderGUI.FindProperty("_MetallicMap", props);
            roughMap = ShaderGUI.FindProperty("_RoughMap", props);
            bakedCube = ShaderGUI.FindProperty("_BakedCube", props);
            shadowType = ShaderGUI.FindProperty("_ShadowType", props);
            reflType = ShaderGUI.FindProperty("_ReflType", props);
            saturation = ShaderGUI.FindProperty("_Saturation", props);
            styleIntensity = ShaderGUI.FindProperty("_StylelizedIntensity", props);
            normalTiling = ShaderGUI.FindProperty("_NormalTiling", props);
            bakedReflOnly = ShaderGUI.FindProperty("_UseOnlyBakedCube", props);
            useRefl = ShaderGUI.FindProperty("_UseReflections", props);
            matcapStyle = ShaderGUI.FindProperty("_MatcapStyle", props);
            stylizedType = ShaderGUI.FindProperty("_StylizedReflStyle", props);
            shadowTint = ShaderGUI.FindProperty("_ShadowTint", props);
            IndirectType = ShaderGUI.FindProperty("_IndirectType", props);

            //advanced options
            colorMask = ShaderGUI.FindProperty("_colormask", props);
            stencil = ShaderGUI.FindProperty("_Stencil", props);
            readMask = ShaderGUI.FindProperty("_ReadMask", props);
            writeMask = ShaderGUI.FindProperty("_WriteMask", props);
            stencilComp = ShaderGUI.FindProperty("_StencilComp", props);
            stencilOp = ShaderGUI.FindProperty("_StencilOp", props);
            stencilFail = ShaderGUI.FindProperty("_StencilFail", props);
            stencilZFail = ShaderGUI.FindProperty("_StencilZFail", props);
            zwrite = ShaderGUI.FindProperty("_ZWrite", props);
            ztest = ShaderGUI.FindProperty("_ZTest", props);

            //Show Properties in Inspector
            //materialEditor.ShaderProperty(, .displayName);   

            // Swap between blend modes 
            EditorGUI.BeginChangeCheck();
            {
                EditorGUI.showMixedValue = blendMode.hasMixedValue;
                var bMode = (BlendMode)blendMode.floatValue;

                EditorGUI.BeginChangeCheck();

                EditorGUI.showMixedValue = advMode.hasMixedValue;
                var aMode = (DisplayType)advMode.floatValue;

                EditorGUI.BeginChangeCheck();
                aMode = (DisplayType)EditorGUILayout.Popup("Shader Mode", (int)aMode, Enum.GetNames(typeof(DisplayType)));

                if (EditorGUI.EndChangeCheck())
                {
                    materialEditor.RegisterPropertyChangeUndo("Shader Mode");
                    advMode.floatValue = (float)aMode;
                    EditorGUI.showMixedValue = false;
                }

                materialEditor.ShaderProperty(culling, culling.displayName);
                materialEditor.ShaderProperty(shadowType, Styles.shadowTypeText);
                materialEditor.ShaderProperty(rimStyle, Styles.rimLightTypeText);


                if (rimStyle.floatValue == 0)
                {
                    // material.DisableKeyword("_SMOOTHRIMLIGHT_ON");
                    materialEditor.ShaderProperty(rimWidth, Styles.rimWidthText, 2);
                    materialEditor.ShaderProperty(rimIntensity, Styles.rimIntText, 2);
                }

                materialEditor.ShaderProperty(IndirectType, "Indirect Style");
                if(IndirectType.floatValue == 1){
                    materialEditor.ShaderProperty(shadowTint, "Indirect Color");                    
                }

                if (rimStyle.floatValue == 1)
                {
                    // material.EnableKeyword("_SMOOTHRIMLIGHT_ON");
                    materialEditor.ShaderProperty(rimWidth, Styles.rimWidthText, 2);
                    materialEditor.ShaderProperty(rimIntensity, Styles.rimIntText, 2);
                }

                if (rimStyle.floatValue == 2)
                {
                    material.SetFloat("_RimIntensity", 0);
                }

                EditorGUILayout.Space();
                
                //main
                GUILayout.Label(Styles.mainText, EditorStyles.boldLabel);
                materialEditor.TexturePropertySingleLine(Styles.MainTexText, mainTex, tint);
                materialEditor.ShaderProperty(saturation, Styles.Saturation, 3);
                materialEditor.TexturePropertySingleLine(Styles.normalText, normal);
                materialEditor.ShaderProperty(normalTiling, Styles.normalTiling, 3);
                materialEditor.TexturePropertySingleLine(Styles.rampText, shadowRamp);

                //specular
                materialEditor.TexturePropertySingleLine(Styles.specMapText, specMap);
                materialEditor.TexturePropertySingleLine(Styles.specPatternText, specPattern);
                materialEditor.ShaderProperty(specArea, Styles.SmoothnessText, 3);
                materialEditor.ShaderProperty(specIntensity, Styles.sintensityText, 3);
                materialEditor.ShaderProperty(specTiling, Styles.stilingText, 3);

                //metallic
                materialEditor.ShaderProperty(useRefl, "Use Reflections");
                if (useRefl.floatValue == 0)
                {
                    materialEditor.ShaderProperty(reflType, "Reflection Style");

                    material.EnableKeyword("_REFLECTIONS_ON");
                    //pbr
                    if(reflType.floatValue == 0)
                    {
                        materialEditor.TexturePropertySingleLine(Styles.bakedCube, bakedCube);
                        material.DisableKeyword("_MATCAP_ON");
                        material.EnableKeyword("_PBRREFL_ON");
                        material.DisableKeyword("_STYLIZEDREFLECTION_ON");
                        materialEditor.TexturePropertySingleLine(Styles.MetalMap, metalMap);
                        materialEditor.ShaderProperty(metal, "Metallic", 2);
                        materialEditor.TexturePropertySingleLine(Styles.roughMap, roughMap);
                        materialEditor.ShaderProperty(reflSmooth, "Roughness", 2);
                    }
                    //stylized
                    if(reflType.floatValue == 1)
                    {
                        material.DisableKeyword("_MATCAP_ON");
                        material.EnableKeyword("_STYLIZEDREFLECTION_ON");
                        material.DisableKeyword("_PBRREFL_ON");
                        materialEditor.ShaderProperty(stylizedType,"Stylized Type");
                        materialEditor.TexturePropertySingleLine(Styles.ReflMask, metalMap);
                            if(stylizedType.floatValue == 1)
                            {
                                material.EnableKeyword("_ANISTROPIC_ON");
                                materialEditor.ShaderProperty(metal, "Width", 2);
                                materialEditor.ShaderProperty(reflSmooth, "Roughness", 2);
                            }
                            else{
                                material.DisableKeyword("_ANISTROPIC_ON");
                                material.SetFloat("_Metallic", 1);
                                materialEditor.ShaderProperty(reflSmooth, "Roughness", 2);
                            }
                        materialEditor.ShaderProperty(styleIntensity, Styles.StyleIntensity, 2);
                    }
                    //matcap
                    if(reflType.floatValue == 2)
                    {
                        material.EnableKeyword("_MATCAP_ON");
                        material.DisableKeyword("_MATCAP_CUBEMAP_ON");                        
                        material.DisableKeyword("_STYLIZEDREFLECTION_ON");
                        material.DisableKeyword("_PBRREFL_ON");
                        materialEditor.ShaderProperty(matcapStyle, "Blend Mode");
                        materialEditor.TexturePropertySingleLine(Styles.Matcap, metalMap);
                        materialEditor.TexturePropertySingleLine(Styles.MatcapMask, roughMap);
                        materialEditor.ShaderProperty(metal, "Intensity", 2);
                        materialEditor.ShaderProperty(reflSmooth, "Blur", 2);
                    }
                    if(reflType.floatValue == 3)
                    {
                        material.EnableKeyword("_MATCAP_CUBEMAP_ON");
                        material.DisableKeyword("_MATCAP_ON");
                        material.DisableKeyword("_STYLIZEDREFLECTION_ON");
                        material.DisableKeyword("_PBRREFL_ON");
                        materialEditor.ShaderProperty(matcapStyle, "Blend Mode");
                        materialEditor.TexturePropertySingleLine(Styles.MatcapCubemap, bakedCube);
                        materialEditor.TexturePropertySingleLine(Styles.MatcapMask, roughMap);
                        materialEditor.ShaderProperty(metal, "Intensity", 2);
                        materialEditor.ShaderProperty(reflSmooth, "Blur", 2);
                    }
                }
                else
                {
                    material.DisableKeyword("_REFLECTIONS_ON");
                    material.DisableKeyword("_PBRREFL_ON");
                    material.DisableKeyword("_STYLIZEDREFLECTION_ON");
                    material.DisableKeyword("_MATCAP_ON");
                    material.DisableKeyword("_MATCAP_CUBEMAP_ON");
                }


                materialEditor.ShaderProperty(emissiveToggle, "Emission");
                if (emissiveToggle.floatValue == 1)
                {
                    materialEditor.TexturePropertySingleLine(Styles.emissText, emissiveTex, emissiveColor);
                }
                else
                {
                    material.SetColor("_EmissiveColor", Color.black);
                }
                materialEditor.ShaderProperty(alphaCutoff, Styles.cutoutText);

                EditorGUILayout.Space();
                GUILayout.Label("Baked Lighting Settings", EditorStyles.boldLabel);
                materialEditor.ShaderProperty(simLightDir, Styles.simLightText);
                materialEditor.ShaderProperty(shadowIntensity, "Shadow Intensity");

                EditorGUILayout.Space();

                if (advMode.floatValue == 1)
                {
                    GUILayout.Label(Styles.advancedOptions, EditorStyles.boldLabel);
                    //Stencil
                    GUILayout.Label("Stencil Buffer", EditorStyles.boldLabel);
                    materialEditor.ShaderProperty(colorMask, colorMask.displayName, 2);
                    materialEditor.ShaderProperty(stencil, stencil.displayName, 2);
                    materialEditor.ShaderProperty(stencilComp, stencilComp.displayName, 2);
                    materialEditor.ShaderProperty(stencilOp, stencilOp.displayName, 2);
                    materialEditor.ShaderProperty(stencilFail, stencilFail.displayName, 2);
                    materialEditor.ShaderProperty(stencilZFail, stencilZFail.displayName, 2);
                    materialEditor.ShaderProperty(ztest, ztest.displayName, 2);
                    materialEditor.ShaderProperty(zwrite, zwrite.displayName, 2);
                    materialEditor.ShaderProperty(uv2, "UV2 for Normal/Spec", 2);
                }
            }
        }
    DoFooter();
    }
}
