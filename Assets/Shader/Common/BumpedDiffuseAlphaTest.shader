Shader "Unity Shaders Book/Common/Bumped Diffuse Alpha-Test" {

    Properties {
        _Color ("Color Tine", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Cutoff ("Alpha Cutoff", Range (0, 1)) = 0.5
    }

    SubShader {
        tags { "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" "Queue" = "AlphaTest" }

		Pass {
			Tags { "LightMode" = "ShadowCaster"	}

			CGPROGRAM

			#pragma target 3.0

            #include "UnityCG.cginc"

			#pragma multi_compile_shadowcaster

            #pragma vertex vert
            #pragma fragment frag

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Cutoff;

            struct a2v {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

			v2f vert (a2v i) {
                v2f o;
                o.pos = UnityApplyLinearShadowBias (UnityClipSpaceShadowCasterPos (i.pos.xyz, i.normal));
                o.uv = TRANSFORM_TEX (i.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_TARGET {
                fixed4 texColor = tex2D (_MainTex, i.uv);
                clip (texColor.a * _Color.a - _Cutoff);

                return 0;
            }
			
			ENDCG
		}

        Pass {
            Tags { "LightMode" = "ForwardBase" }

            Cull Off

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed _Cutoff;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS (4)
            };

            v2f vert (a2v v) {
                v2f o;

                o.pos = UnityObjectToClipPos (v.vertex);
                
                // o.uv.xy = TRANSFORM_TEX (i.texcoord, _MainTex);
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // o.uv.zw = TRANFORM_TEX (i.texcoord, _BumpMap);
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _MainTex_ST.zw;

                fixed3 worldPos = mul (unity_ObjectToWorld, v.vertex).xyz;
                // fixed3 worldNormal = UnityObjectToWorldNormal (v.normal);
                fixed3 worldNormal = normalize(mul (v.normal, unity_WorldToObject));
                // fixed3 worldTangent = UnityObjectToWorldDir (v.tangent.xyz);
                fixed3 worldTangent = normalize(mul (unity_ObjectToWorld, v.tangent.xyz));      // 注意v.tangent.w分量
                // 注意叉乘的順序
                fixed3 worldBinormal = cross (worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4 (worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4 (worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4 (worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW (o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 texColor = tex2D (_MainTex, i.uv.xy);
                clip (texColor.a * _Color.a - _Cutoff);

                float3 worldPos = float3 (i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // fixed3 lightDir = normalize (UnityWorldSpaceLightDir (worldPos));
                fixed3 lightDir = normalize (_WorldSpaceLightPos0.xyz);     // 平行光
                // fixed3 viewDir = normalize (UnityWorldSpaceViewDir (worldPos));
                fixed3 viewDir = normalize (_WorldSpaceCameraPos.xyz - worldPos);

                fixed3 bump = UnpackNormal (tex2D (_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt (1.0 - saturate (dot (bump.xy, bump.xy)));
                bump = normalize (half3 (dot (i.TtoW0.xyz, bump), dot (i.TtoW1.xyz, bump), dot (i.TtoW2.xyz, bump)));

                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max (0, dot (bump, lightDir));

                // 包含了Shadow的計算
                UNITY_LIGHT_ATTENUATION (atten, i, worldPos);

                return fixed4 (ambient + diffuse * atten, 1.0);
            }

            ENDCG

        }

        Pass {
            Tags { "LightMode" = "ForwardAdd" }

            // 注意Blend
            Blend One One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            // Use the line below to add shadows for point and spot lights
            // #pragma multi_compile_fwdadd_fullshadows

            #pragma vertex vert
            #pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            fixed _Cutoff;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS (4)
            };

            v2f vert (a2v v) {
                v2f o;

                o.pos = UnityObjectToClipPos (v.vertex);
                
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _MainTex_ST.zw;

                fixed3 worldPos = mul (unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = normalize(mul (v.normal, unity_WorldToObject));
                fixed3 worldTangent = normalize(mul (unity_ObjectToWorld, v.tangent.xyz));
                fixed3 worldBinormal = cross (worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4 (worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4 (worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4 (worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW (o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 texColor = tex2D (_MainTex, i.uv.xy);
                clip (texColor.a * _Color.a - _Cutoff);

                float3 worldPos = float3 (i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 lightDir = normalize (_WorldSpaceLightPos0.xyz);
                fixed3 viewDir = normalize (_WorldSpaceCameraPos.xyz - worldPos);

                fixed3 bump = UnpackNormal (tex2D (_BumpMap, i.uv.zw));
                bump = normalize (half3 (dot (i.TtoW0.xyz, bump), dot (i.TtoW1.xyz, bump), dot (i.TtoW2.xyz, bump)));

                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * albedo * max (0, dot (bump, lightDir));

                UNITY_LIGHT_ATTENUATION (atten, i, worldPos);

                return fixed4 (diffuse * atten, 1.0);
            }

            ENDCG

        }

    }

    // Fallback "Transparent/Cutout/VertexLit"
}