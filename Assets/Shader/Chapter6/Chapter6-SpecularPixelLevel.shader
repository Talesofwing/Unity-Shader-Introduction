//
// 逐像素: 高光, Phong模型
//
Shader "Unity Shaders Book/Chapter 6/Specular Pixel-Level" {
    Properties {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range (8.0, 256)) = 20
    }

    SubShader {
        Pass {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (a2v v) {
                v2f o;
                // Transform the vertex from object space to projection space
                o.pos = UnityObjectToClipPos (v.vertex);

                // Transform the normal from object space to world space
                o.worldNormal = normalize(mul (unity_WorldToObject, v.normal));
                // Transform the vertex from object space to world space
                o.worldPos = mul (unity_ObjectToWorld, v.vertex).xyz;
                
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                 // Get Ambient term
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // Get the light direction in world space
                fixed3 worldLight = normalize (_WorldSpaceLightPos0.xyz);
                
                // Compute diffuse term
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate (dot (i.worldNormal, worldLight));

                // Get the reflect direction in world space
                fixed3 reflectDir = normalize (reflect (-worldLight, i.worldNormal));
                // Get the view direction in world space
                fixed3 viewDir = normalize (_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // Compute specular term
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow (saturate (dot (reflectDir, viewDir)), _Gloss);
                
                return float4 (ambient + diffuse + specular, 1.0);
            }
            
            ENDCG
        }
    }
    FallBack "Diffuse"
}