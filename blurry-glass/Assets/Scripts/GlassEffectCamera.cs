using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/*
 *  This camera only renders GameObjects on the 'Glass' layer.
 */

[RequireComponent(typeof(Camera))]
public class GlassEffectCamera : MonoBehaviour {

	Camera _camera = null;
	public Camera _cameraToCopy = null;

	void Start() {
		_camera = GetComponent<Camera>();
	}

	void Update() {
		_camera.CopyFrom(_cameraToCopy);
		_camera.clearFlags  = CameraClearFlags.Nothing;
		_camera.cullingMask = (1 << LayerMask.NameToLayer("Glass"));
	}

}
