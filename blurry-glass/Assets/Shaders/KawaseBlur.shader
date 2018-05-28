Shader "Hidden/KawaseBlur" {
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "BlurFilters.cginc"
	
	uniform sampler2D _MainTex;
	uniform float4 _MainTex_TexelSize;

	uniform sampler2D _GrabTexture;
	uniform float4 _GrabTexture_TexelSize;

	uniform float pxOffset;
	
	float4 frag(v2f_img i) : COLOR {
		SamplerInfo sinfo;
		sinfo.tex = _MainTex;
		sinfo.texelSize = _MainTex_TexelSize;

		return KawaseBlur(sinfo, i.uv, pxOffset);
	}
	ENDCG
	
	Properties 
	{ 
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "Queue"="Overlay" }
		Lighting Off 
		Cull Off 
		ZWrite Off 
		ZTest Always 

	    Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			ENDCG
		}
	}
}
