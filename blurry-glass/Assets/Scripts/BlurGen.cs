using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class BlurGen : MonoBehaviour {

	public enum BlurFrequency {
		STATIC = 0,
		NORMAL = 1,
		HALF = 2,
		EVERY_FOURTH_FRAME = 4
	}

	public enum FilterType {
		GAUSSIAN,
		KAWASE
	}

	Camera _camera = null;

	RenderTexture BlurTex1;
	RenderTexture BlurTex2;
	RenderTexture BlurTex3;
	RenderTexture BlurTex4;

	public BlurFrequency _blurFreq;
	public FilterType _filterType;

	private Vector4 GaussianWeights = new Vector4(0.4f, 0.15f, 0.10f, 0.05f);
	private Vector3 GaussianOffsets = new Vector3(2, 4, 6);

	private int[] DownsampleFactors = { 1, 2, 4, 8 };

	Material _glassMaterial = null;

	public Texture DistortionTexture;
	public Texture BlurTexture;

	private bool _toggleDist;
	private bool _toggleBlur;

	void InitBlurTextures() {
		BlurTex1 = new RenderTexture(Screen.width / DownsampleFactors[0], Screen.height / DownsampleFactors[0], 0, RenderTextureFormat.Default);
		BlurTex1.filterMode = FilterMode.Bilinear;

		BlurTex2 = new RenderTexture(Screen.width / DownsampleFactors[1], Screen.height / DownsampleFactors[1], 0, RenderTextureFormat.Default);
		BlurTex2.filterMode = FilterMode.Bilinear;

		BlurTex3 = new RenderTexture(Screen.width / DownsampleFactors[2], Screen.height / DownsampleFactors[2], 0, RenderTextureFormat.Default);
		BlurTex3.filterMode = FilterMode.Bilinear;

		BlurTex4 = new RenderTexture(Screen.width / DownsampleFactors[3], Screen.height / DownsampleFactors[3], 0, RenderTextureFormat.Default);
		BlurTex4.filterMode = FilterMode.Bilinear;

		// Associate Render Textures with global shader identifiers
		Shader.SetGlobalTexture("_BgBlurTexture_1", BlurTex1);
		Shader.SetGlobalTexture("_BgBlurTexture_2", BlurTex2);
		Shader.SetGlobalTexture("_BgBlurTexture_3", BlurTex3);
		Shader.SetGlobalTexture("_BgBlurTexture_4", BlurTex4);
	}

	void Start() {
		_camera = GetComponent<Camera>();
		_camera.depthTextureMode = DepthTextureMode.Depth;
		_camera.clearFlags = CameraClearFlags.Skybox;

		InitBlurTextures();

		_blurFreq   = BlurFrequency.NORMAL;
		_filterType = FilterType.GAUSSIAN;

		_glassMaterial = GameObject.Find("Quad").GetComponent<Renderer>().sharedMaterial;

		_toggleDist = false;
		_toggleBlur = true;
	}

	void OnRenderImage(RenderTexture source, RenderTexture destination) {
		bool isStatic = _blurFreq == BlurFrequency.STATIC;
		if (isStatic && Time.renderedFrameCount != 0) {
			Graphics.Blit(source, destination); 
			return;
		}

		if (Time.renderedFrameCount % ((int)_blurFreq) == 0) {
			RenderTexture[] rts = {
				BlurTex1, BlurTex2, BlurTex3, BlurTex4
			};
				
			BlurFilter filter;
			for (int i = 0; i < 4; ++i) {
				if (_filterType == FilterType.GAUSSIAN)
					filter = new GaussianFilter(GaussianWeights, GaussianOffsets, DownsampleFactors[i]);
				else
					filter = new KawaseFilter(0.5f * i, DownsampleFactors[i]);

				// Execute the filter onto textures rts[i]
				filter.execute((i == 0 ? source : rts[i-1]), rts[i]);
			}
		}

		Graphics.Blit(source, destination);
	}
		
	private void OnGUI() {
		GUILayout.BeginVertical("Box");

		GUILayout.BeginHorizontal();
		GUILayout.Label("Filter Type : " + _filterType.ToString() + "\nBlur Frequency: " + _blurFreq.ToString());
		GUILayout.EndHorizontal();

		GUILayout.BeginHorizontal();
		if (GUILayout.Button("GAUSSIAN")) _filterType = FilterType.GAUSSIAN;
		if (GUILayout.Button("KAWASE")) _filterType = FilterType.KAWASE;
		GUILayout.EndHorizontal();

		GUILayout.BeginHorizontal();
		if (GUILayout.Button("NORMAL")) _blurFreq = BlurFrequency.NORMAL;
		if (GUILayout.Button("STATIC")) _blurFreq = BlurFrequency.STATIC;
		if (GUILayout.Button("HALF FREQUENCY")) _blurFreq = BlurFrequency.HALF;
		if (GUILayout.Button("EVERY FOURTH FRAME")) _blurFreq = BlurFrequency.EVERY_FOURTH_FRAME;
		GUILayout.EndHorizontal();

		GUILayout.BeginHorizontal();
		if (GUILayout.Button ("TOGGLE BLUR MAP")) {
			_toggleBlur = !_toggleBlur;
			_glassMaterial.SetTexture("_BlurMap", (_toggleBlur ? BlurTexture : null));
		}

		if (GUILayout.Button("TOGGLE DISTORTION MAP")) {
			_toggleDist = !_toggleDist;
			_glassMaterial.SetTexture("_NormalMap", (_toggleDist ? DistortionTexture : null));
		}

		GUILayout.EndHorizontal();

		GUILayout.EndVertical();
	}
}

