//======= Copyright (c) Stereolabs Corporation, All rights reserved. ===============

using UnityEngine;
using UnityEngine.XR;

#if ZED_HDRP || ZED_URP
using UnityEngine.Rendering;
#endif

/// <summary>
/// In AR mode, displays a full-screen, non-timewarped view of the scene for the editor's Game window.
/// Replaces Unity's default behavior of replicating the left eye view directly,
/// which would otherwise have black borders and move around when the headset moves because of 
/// latency compensation.
/// ZEDManager creates a hidden camera with this script attached when in AR mode (see ZEDManager.CreateMirror()). 
/// </summary>
public class ZEDMirror : MonoBehaviour
{
    /// <summary>
    /// The scene's ZEDManager component, for getting the texture overlay. 
    /// </summary>
    public ZEDManager manager;

    /// <summary>
    /// Reference to the ZEDRenderingPlane that renders the left eye, so we can get its target RenderTexture. 
    /// </summary>
	private ZEDRenderingPlane textureOverlayLeft;

    //private RenderTexture bufferTexture;

    void Start()
    {
        // NVT Port
        //XRSettings.showDeviceView = false; //Turn off default behavior.
        XRSettings.gameViewRenderMode = GameViewRenderMode.None; // Turn off mirroring to the game view
        // END NVT Port

#if ZED_HDRP || ZED_URP
        RenderPipelineManager.endFrameRendering += OnFrameEnd;
#endif
    }

    private void Update()
    {
        if (textureOverlayLeft == null && manager != null)
        {
            textureOverlayLeft = manager.GetLeftCameraTransform().GetComponent<ZEDRenderingPlane>();
        }
    }

#if !ZED_HDRP && !ZED_URP
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (textureOverlayLeft != null)
        {
            //Ignore source. Copy ZEDRenderingPlane's texture as the final image.
            Graphics.Blit(textureOverlayLeft.target, destination);
        }
    }

#else
    /// <summary>
    /// Blits the intermediary targetTexture to the final outputTexture for rendering. Used in SRP because there is no OnRenderImage automatic function. 
    /// </summary>
    private void OnFrameEnd(ScriptableRenderContext context, Camera[] cams)
    {
        // NVT Port
#if UNITY_EDITOR
        // Do not blit the texture for the editor's scene view camera!
        // This avoids render pipeline errors when running in the editor.
        if (cams.Length > 0 && cams[0].cameraType == CameraType.SceneView)
        {
            return;
        }
#endif
        // END NVT Port

        if (textureOverlayLeft != null)
        {
            Graphics.Blit(textureOverlayLeft.target, (RenderTexture) null);
        }
    }
#endif

    private void OnDestroy()
    {
#if ZED_URP || ZED_HDRP
        RenderPipelineManager.endFrameRendering -= OnFrameEnd;
#endif
    }
}
