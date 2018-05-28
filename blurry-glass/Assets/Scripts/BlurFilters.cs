using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public abstract class BlurFilter {
	public abstract void execute(RenderTexture source, RenderTexture output);
}

public class GaussianFilter : BlurFilter {

	private Shader  _shader;
	private Vector4 _weights;
	private Vector3 _offsets;
	private int _downsample;

	private Material _material;

	public GaussianFilter(Vector4 weights, Vector3 offsets, int downsample) {
		_weights = weights;
		_offsets = offsets;
		_downsample = (int)Mathf.Max(1, (float)downsample);

		InitMaterial();
	}

	private void InitMaterial() {
		Shader sepBlurShader = Shader.Find("Hidden/SeparableBlur");

		_material = new Material(sepBlurShader);
		_material.hideFlags = HideFlags.HideAndDontSave;
	}

	public override void execute(RenderTexture source, RenderTexture output) {
		int sWidth  = Screen.width;
		int sHeight = Screen.height;

		int dWidth  = sWidth / _downsample;
		int dHeight = sHeight / _downsample;

		RenderTexture blurRTAux1 = RenderTexture.GetTemporary(dWidth, dHeight, 0, RenderTextureFormat.Default);
		blurRTAux1.filterMode = FilterMode.Bilinear;

		RenderTexture blurRTAux2 = RenderTexture.GetTemporary(dWidth, dHeight, 0, RenderTextureFormat.Default);
		blurRTAux2.filterMode = FilterMode.Bilinear;

		// Downsample
		Graphics.Blit(source, blurRTAux1);

		// Horizontal pass
		_material.SetVector("dir", new Vector2 (1.0f, 0.0f));
		_material.SetVector("offsets", _offsets / dWidth);
		_material.SetVector("weights", _weights);

		Graphics.Blit(blurRTAux1, blurRTAux2, _material);

		// Vertical pass
		_material.SetVector("dir", new Vector2 (0.0f, 1.0f));
		_material.SetVector("offsets", _offsets / dHeight);
		_material.SetVector("weights", _weights);

		Graphics.Blit(blurRTAux2, output, _material);

		RenderTexture.ReleaseTemporary(blurRTAux1);
		RenderTexture.ReleaseTemporary(blurRTAux2);
	}

}

public class KawaseFilter : BlurFilter {
	private Shader _shader;
	private float _pxOffset;
	private int _downsample;

	private Material _material;

	public KawaseFilter(float pxOffset, int downsample) {
		_pxOffset = pxOffset;
		_downsample = (int)Mathf.Max(1, (float)downsample);

		InitMaterial ();
	}

	private void InitMaterial() {
		Shader kawaseShader = Shader.Find("Hidden/KawaseBlur");

		_material = new Material(kawaseShader);
		_material.hideFlags = HideFlags.HideAndDontSave;
	}

	public override void execute(RenderTexture source, RenderTexture output) {
		int dWidth  = Screen.width / _downsample;
		int dHeight = Screen.height / _downsample;

		RenderTexture blurRTAux = RenderTexture.GetTemporary(dWidth, dHeight, 0, RenderTextureFormat.Default);
		blurRTAux.filterMode = FilterMode.Bilinear;

		// Downsample
		Graphics.Blit(source, blurRTAux);

		_material.SetFloat("pxOffset", _pxOffset);
		Graphics.Blit(blurRTAux, output, _material);

		RenderTexture.ReleaseTemporary(blurRTAux);
	}
}