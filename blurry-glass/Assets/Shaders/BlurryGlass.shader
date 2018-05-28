Shader "Unlit/BlurryGlass"
{
	Properties
	{	
		_TintColor("Tint Color", Color) = (1, 1, 1, 1)
		_TintMap("Tint Map", 2D) = "white" {}
		_TintScale("Tint Scale", Range(0.0, 1.0)) = 0.0

		_NormalMap("Distortion Map", 2D) = "black" {}
		_BumpScale("Bump Scale", Range(0.0, 50.0)) = 0.0

		_BlurMap("Blur Map", 2D) = "white" {}
		_BlurScale("Blur Scale", Range(0.0, 1.0)) = 0.0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		Cull Off 

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv     : TEXCOORD0;
			};

			struct v2f {
				float4 vertex   : SV_POSITION;
				float2 uvTint   : TEXCOORD0;
				float2 uvBlur   : TEXCOORD1;
				float4 uvScreen : TEXCOORD2;  
				float2 uvBump   : TEXCOORD3;
				float4 uvGrab   : TEXCOORD4;
			};

			float4 _TintColor;
			sampler2D _TintMap;
			float4 _TintMap_ST;
			float _TintScale;

			sampler2D _BlurMap;
			float4 _BlurMap_ST;

			sampler2D _NormalMap;
			float4 _NormalMap_ST;

			float _BumpScale;

			float _BlurScale;

			uniform sampler2D _BgBlurTexture_1;
			uniform sampler2D _BgBlurTexture_2;
			uniform sampler2D _BgBlurTexture_3;
			uniform sampler2D _BgBlurTexture_4;

			float4 _BgBlurTexture_1_TexelSize;
			float4 _BgBlurTexture_2_TexelSize;
			float4 _BgBlurTexture_3_TexelSize;
			float4 _BgBlurTexture_4_TexelSize;

			sampler2D _GlassMask;
			
			v2f vert(appdata v) {
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uvBlur = TRANSFORM_TEX(v.uv, _BlurMap);
				o.uvTint  = TRANSFORM_TEX(v.uv, _TintMap);
				o.uvBump  = TRANSFORM_TEX(v.uv, _NormalMap);

				o.uvScreen = ComputeGrabScreenPos(o.vertex);

				o.uvGrab.xy = (float2(o.vertex.x, o.vertex.y * -1) + o.vertex.w) * 0.5;
				o.uvGrab.zw = o.vertex.zw;

				return o;
			}

			float4 offsetUnprojUV(float4 uv, half2 bump, float2 texelSize) {
				float4 ret;
				ret.xy = bump * uv.z * texelSize + uv.xy;
				ret.wz = uv.wz;

				return ret;
			}

			fixed4 frag(v2f i) : SV_Target {
				// Unpack normal's extent onto the tangent axes to offset uvs
				half2 bump = _BumpScale * UnpackNormal(tex2D(_NormalMap, i.uvBump)).rg;

				float4 uv1 = UNITY_PROJ_COORD(offsetUnprojUV(i.uvGrab, bump, _BgBlurTexture_1_TexelSize.xy));
				float4 uv2 = UNITY_PROJ_COORD(offsetUnprojUV(i.uvGrab, bump, _BgBlurTexture_2_TexelSize.xy));
				float4 uv3 = UNITY_PROJ_COORD(offsetUnprojUV(i.uvGrab, bump, _BgBlurTexture_3_TexelSize.xy));
				float4 uv4 = UNITY_PROJ_COORD(offsetUnprojUV(i.uvGrab, bump, _BgBlurTexture_4_TexelSize.xy));

				// Blur amount calculation - interpolate between 4 blur textures
				float4 blurred;

				float smoothness = clamp(1 - tex2D(_BlurMap, i.uvBlur) * _BlurScale, 0, 1);

				float4 ref00 = tex2Dproj(_BgBlurTexture_1, uv1);
				float4 ref01 = tex2Dproj(_BgBlurTexture_2, uv2);
				float4 ref02 = tex2Dproj(_BgBlurTexture_3, uv3);
				float4 ref03 = tex2Dproj(_BgBlurTexture_4, uv4);

				// Build interpolation curve between all the 4 textures
				float step00 = smoothstep(0.90, 1.00, smoothness);
				float step01 = smoothstep(0.55, 0.85, smoothness);
				float step02 = smoothstep(0.25, 0.55, smoothness);
				float step03 = smoothstep(0.00, 0.05, smoothness);

				blurred = lerp(ref03,   ref02,   step02);
				blurred = lerp(blurred, ref01,   step01);
				blurred = lerp(blurred, ref00,   step00);
				blurred = lerp(ref03,   blurred, step03);

				// Interpolate between blur and tint
				float4 tint = tex2D(_TintMap, i.uvTint) * _TintColor;
				float4 col  = lerp(blurred, tint, _TintScale);

				return lerp(col, tint, _TintScale);
			}

			ENDCG
		}
	}
}