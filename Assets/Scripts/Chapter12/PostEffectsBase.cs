using UnityEngine;

[ExecuteInEditMode]
[RequireComponent (typeof (Camera))]
public abstract class PostEffectsBase : MonoBehaviour {
	private Camera _camera;
	public Camera Cam {
		get {
			if (_camera == null)
				_camera = GetComponent<Camera> ();

			return _camera;
		}
	}

	protected void Start () {
		CheckResources ();
	}

	// Called when start
	protected void CheckResources () {
		bool isSupported = CheckSupport ();

		if (isSupported == false)
			NotSupported ();
	}

	// Called in CheckResources to check support on this platform
	protected bool CheckSupport () {
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) {
			Debug.LogWarning ("This platform does not support image effects or render textures.");
			return false;
		}

		return true;
	}

	// Called when the platform doesn't support this effect
	protected void NotSupported () {
		enabled = false;
	}

	// Called when need to create the material used by this effect
	protected Material CheckShaderAndCreateMaterial (Shader shader, Material material) {
		if (!shader)
			return null;

		if (shader.isSupported && material && material.shader == shader)
			return material;

		if (!shader.isSupported) {
			return null;
		} else {
			material = new Material (shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else
				return null;
		}
	}

}
