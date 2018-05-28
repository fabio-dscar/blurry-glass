Shader "Hidden/SeparableBlur"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "" {}
	}

	CGINCLUDE

	#include "BlurFilters.cginc"
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : POSITION;
		float2 uv  : TEXCOORD0;
	};

	sampler2D _MainTex;
	uniform float4 _MainTex_TexelSize;

	uniform float4 weights;
	uniform float3 offsets;
	uniform float2 dir;

	v2f vert(appdata_img v) {
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.texcoord.xy;
		return o;
	}
	
	half4 frag (v2f i) : COLOR {
		return SeparableBlur7Tap(_MainTex, i.uv, weights, offsets, dir);
	}

	ENDCG
	
	Subshader {
		Tags { "Queue"="Overlay" "IgnoreProjector"="True" "RenderType"="Opaque" }

		Pass {
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }

			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
	}

	Fallback off
}
