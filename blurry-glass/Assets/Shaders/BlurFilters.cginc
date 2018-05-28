#define PI 3.14159265

struct SamplerInfo {
	sampler2D tex;
	float4 texelSize;
};

// Gaussian PDF with a 2D normalization term.
//
float GaussianPdf2(float x, float stddev) {
	float tsig2    = 2.0 * stddev * stddev;
	float normTerm = 1.0 / (PI * tsig2);

	return normTerm * exp(-(x * x) / tsig2);
}

// Executes a gaussian filter, separable by the _dir_ vector.
//
// This version performs wasteful analytic evaluations of the pdf - it is only for validation purposes.
//
float4 SeparableGaussianBlurNTap(SamplerInfo sinfo, int radius, float stddev, float2 uv, float2 dir) {
	float4 ret = 0;
	float fsum = 0;

	for (int fstep = -radius / 2; fstep <= radius / 2; ++fstep) {
		float  weight   = GaussianPdf2(fstep, stddev) + GaussianPdf2(fstep + 1, stddev);
		float2 uvSample = uv + (fstep * sinfo.texelSize) * dir;

		ret  += weight * tex2D(sinfo.tex, uvSample);
		fsum += weight;
	}

	return ret / fsum;
}

// Performs a 7 tap separable symmetric filter using precomputed weights and offsets.
//
// _weights_ do not need to correspond to a gaussian distribution.
//
// Additionally, _offsets_ can be precomputed so that linear interpolation sampling is performed:
//   [Rákos 2010, Efficient Gaussian blur with linear sampling]
//
float4 SeparableBlur7Tap(sampler2D tex, float2 uv, float4 weights, float3 offsets, float2 dir) {
	float4 ret = 0;

	ret += weights.x * tex2D(tex, uv);

	ret += weights.y * tex2D(tex, uv + (offsets.x * dir));
	ret += weights.y * tex2D(tex, uv - (offsets.x * dir));

	ret += weights.z * tex2D(tex, uv + (offsets.y * dir));
	ret += weights.z * tex2D(tex, uv - (offsets.y * dir));

	ret += weights.w * tex2D(tex, uv + (offsets.z * dir));
	ret += weights.w * tex2D(tex, uv - (offsets.z * dir));

	// Compute filter sum to normalize output
	// Avoids pixel intensity gain/loss due to non normalized weights
	float fsum = weights.x + 2.0 * (weights.y + weights.z + weights.w);

	return ret / fsum;
}

// Performs one Kawase blur iteration
//
float4 KawaseBlur(SamplerInfo sinfo, float2 uv, int pxOffset) {
	float txOffset = (pxOffset + 0.5) * sinfo.texelSize;

	float4 ret = 0;
	ret += tex2D(sinfo.tex, uv + float2( txOffset,  txOffset));
	ret += tex2D(sinfo.tex, uv + float2( txOffset, -txOffset));
	ret += tex2D(sinfo.tex, uv + float2(-txOffset,  txOffset));
	ret += tex2D(sinfo.tex, uv + float2(-txOffset, -txOffset));

	return ret * 0.25;
}