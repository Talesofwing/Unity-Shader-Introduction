Shader "Unity Shaders Book/Chapter 10/Reflection" {

    Properties {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_ReflectColor ("Reflection Color", Color) = (1, 1, 1, 1)
		_ReflectAmount ("Reflection Amount", Range(0, 1)) = 1
		_Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {}
        // Specular
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader {
        Tags {"RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass {

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed4 _ReflectColor;
			fixed _ReflectAmount;
			samplerCUBE _Cubemap;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 pos : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert (a2v i) {
                v2f o;
                o.pos = UnityObjectToClipPos (i.pos);
                o.worldNormal = UnityObjectToWorldNormal (i.normal);
                o.worldPos = mul (unity_ObjectToWorld, i.pos).xyz;
                o.worldViewDir = UnityWorldSpaceViewDir (o.worldPos);       // 在vertex shader中計算入射方向
                o.worldRefl = reflect (-o.worldViewDir, o.worldNormal);     // 計算反射角
                                                                            // r = 2 * (dot (i, n) * n - i);
                TRANSFER_SHADOW (o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed3 worldNormal = normalize (i.worldNormal);
                fixed3 worldLightDir = normalize (UnityWorldSpaceLightDir (i.worldPos));
                fixed3 worldViewDir = normalize (i.worldViewDir);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max (0, dot (worldNormal, worldLightDir));

                // Use the reflect dir in world space to access the cubemap
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

                // Specular
                fixed3 halfDir = normalize (worldLightDir + worldViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow (max (0, dot (halfDir, worldNormal)), _Gloss);

                UNITY_LIGHT_ATTENUATION (atten, i, i.worldPos);

                // Mix the diffuse color with the reflected color
                fixed3 color = ambient + (lerp (diffuse, reflection, _ReflectAmount) + specular) * atten;

                return fixed4 (color, 1.0);
            }

            ENDCG

        }

    }

    FallBack "Reflective/VertexLit"
}
