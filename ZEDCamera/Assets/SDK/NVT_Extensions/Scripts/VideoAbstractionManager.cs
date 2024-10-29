using UnityEngine;
using NVT.EventSystem;
using System;
#if USING_FVW
using FVW.Events;
using FVW.JsonSerializables.UserSettingsDataObject;
#endif


#if ZED_HDRP || ZED_URP
using UnityEngine.Rendering;
#endif

/// <summary>
/// When attached to an object that also has a ZEDRenderingPlane, applies an effect on the camera image for
/// abstraction purposes.
/// </summary>

public class VideoAbstractionManager : MonoBehaviour, IEventListener
{


    /// <summary>
    /// The plane used for rendering. Equal to the canvas value of ZEDRenderingPlane. 
    /// </summary>
    private GameObject screen = null;

    /// <summary>
    /// The Camera that this script is attached to. Only needed in SRP for a callback, since OnPreRender won't work. 
    /// </summary>
    private Camera cam;

    /// <summary>
    /// The screen manager script. Automatically assigned in OnEnable(). 
    /// </summary>
    private ZEDManager cameraManager = null;

    /// <summary>
    /// The screen manager script. Automatically assigned in OnEnable(). 
    /// </summary>
	private ZEDRenderingPlane screenManager = null;

    /// <summary>
    /// Final rendering material, eg. the material on the ZEDRenderingPlane's canvas object. 
    /// </summary>
    public Material FinalMat { get; private set; }
    /// <summary>
    /// Video abstraction effect material and mode.
    /// </summary>
    public Material AbstractionMat { get; private set; }
    private int abstractionMode = -1;
    /// <summary>
    /// Alpha texture for blending.
    /// </summary>
    private RenderTexture finalTexture;
    /// <summary>
    /// Public accessor for the alpha texture used for blending. 
    /// </summary>
    public RenderTexture FinalTexture
    {
        get { return finalTexture; }
    }

    public bool UseBlurMat = false;

    /// <summary>
    /// Material used to apply blur effect in OnPreRender().
    /// </summary>
    public Material BlurMat { get; private set; }
    /// <summary>
    /// Blur iteration number. A larger value increases the blur effect.
    /// </summary>
    public int NumberBlurIterations = 5;
    /// <summary>
    /// Sigma value. A larger value increases the blur effect.
    /// </summary>
    public float Sigma = 0.1f;
    /// <summary>
    /// Current sigma value.
    /// </summary>
    private float currentSigma = -1;
    /// <summary>
    /// Weights for blur effect. 
    /// </summary>
    private float[] weights = new float[5];
    /// <summary>
    /// Offsets for blur effect. 
    /// </summary>
    private float[] offsets = { 0.0f, 1.0f, 2.0f, 3.0f, 4.0f };

    /// <summary>
    /// Cached property id for _MainTex. use the mainTexID property instead. 
    /// </summary>
    private int? maintexid;
    /// <summary>
    /// Property id for _MaskTex, which is the RenderTexture property for the mask texture. 
    /// </summary>
    private int MainTexID
    {
        get
        {
            if (maintexid == null)
            {
                maintexid = Shader.PropertyToID("_MainTex");
            }

            return (int) maintexid;
        }
    }

    /// <summary>
    /// Cached property id for weights. use the weightsID property instead. 
    /// </summary>
    private int? weightsid;
    /// <summary>
    /// Property id for weights, which affects post-processing blurring. 
    /// </summary>
    private int WeightsID
    {
        get
        {
            if (weightsid == null)
            {
                weightsid = Shader.PropertyToID("weights");
            }

            return (int) weightsid;
        }
    }

    /// <summary>
    /// Cached property id for offset. use the offsetID property instead. 
    /// </summary>
    private int? offsetid;
    /// <summary>
    /// Property id for offset, which affects post-processing blurring. 
    /// </summary>
    private int OffsetID
    {
        get
        {
            if (offsetid == null)
            {
                offsetid = Shader.PropertyToID("offset");
            }

            return (int) offsetid;
        }
    }

    // [SerializeField]
    // [Tooltip("Event to register with.")]
    // private ValueChangedEvent abstractionChanged;
#if USING_FVW
    [SerializeField] private AbstractionObject abstractionObject;
#endif

    public void OnEnable()
    {
        cameraManager = gameObject.GetComponentInParent<ZEDManager>();
        if (!cameraManager)
        {
            cameraManager = FindObjectOfType<ZEDManager>();
        }

        screenManager = GetComponent<ZEDRenderingPlane>();
        cameraManager.OnZEDReady += ZEDReady;
#if USING_FVW
        if (abstractionObject.Event != null)
        {
            abstractionObject.Event.RegisterListener(this);
        }

        abstractionMode = (int)MapAbstraction(abstractionObject.Value);
#endif
    }

    public void OnDisable()
    {
        if (cameraManager)
        {
            cameraManager.OnZEDReady -= ZEDReady;
        }
#if USING_FVW
        if (abstractionObject.Event != null)
        {
            abstractionObject.Event.UnregisterListener(this);
        }
#endif
    }

    private void OnDestroy()
    {
#if ZED_HDRP || ZED_URP
        RenderPipelineManager.beginCameraRendering -= OnSRPPreRender;
#endif
    }

    private void Awake()
    {
        //cameraManager = gameObject.GetComponent<ZEDManager> ();
        Shader.SetGlobalInt("_ZEDStencilComp", 0);

        if (screen == null)
        {
            screen = gameObject.transform.GetChild(0).gameObject;
            FinalMat = screen.GetComponent<Renderer>().material;
        }

#if ZED_HDRP || ZED_URP
        cam = GetComponent<Camera>();

        if (!cam)
        {
            Debug.LogError("VideoAbstractionManager is not attached to a Camera.");
        }

        RenderPipelineManager.beginCameraRendering += OnSRPPreRender;
#endif
#if USING_FVW
        // Set default value
        abstractionMode = (int) MapAbstraction(Abstraction.Greyscale);
#endif
    }

    public UnityEngine.Object GetObject()
    {
        throw new System.NotImplementedException();
    }


    public void OnEventRaised(NVT.EventSystem.Object evtObj, IEvent sender)
    {
#if USING_FVW
        if (sender.Equals(abstractionObject.Event))
        {
            abstractionMode = (int) MapAbstraction(((AbstractionObject) evtObj).Value);
        }
#endif
    }


    /// <summary>
    /// Initialization logic that must be done after the ZED camera has finished initializing. 
    /// Added to the ZEDManager.OnZEDReady() callback in OnEnable(). 
    /// </summary>
    private void ZEDReady()
    {
        //Set up textures and materials used for the final output. 
        if (cameraManager == null)
            return;

        //We set the material again in case it has changed. 
        //screen = gameObject.transform.GetChild(0).gameObject;
        //FinalMat = ScreenManager.matRGB;
        FinalMat = screen.GetComponent<Renderer>().material;

        finalTexture = new RenderTexture(cameraManager.zedCamera.ImageWidth, cameraManager.zedCamera.ImageHeight, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);

        FinalMat.SetTexture("_CameraTex", finalTexture);
        FinalMat.SetTexture(MainTexID, finalTexture);

        AbstractionMat = new Material(Resources.Load("Materials/Mat_NVT_VideoProcessing") as Material);

        BlurMat = new Material(Resources.Load("Materials/PostProcessing/Mat_ZED_Blur") as Material);

        ZEDPostProcessingTools.ComputeWeights(1, out weights, out offsets);

        BlurMat.SetFloatArray("weights2", weights);
        BlurMat.SetFloatArray("offset2", offsets);
    }

    /// <summary>
    /// Enables or disables a shader keyword in the finalMat material.
    /// </summary>
    /// <param name="value"></param>
    /// <param name="name"></param>
    private void ManageKeyWord(bool value, string name)
    {
        if (FinalMat != null)
        {
            if (value)
            {
                FinalMat.EnableKeyword(name);
            }
            else
            {
                FinalMat.DisableKeyword(name);
            }
        }
    }

    private void OnApplicationQuit()
    {
        if (finalTexture != null && finalTexture.IsCreated())
        {
            finalTexture.Release();
        }
    }


#if ZED_HDRP || ZED_URP
    /// <summary>
    /// 
    /// </summary>
    /// <param name="cam"></param>
    private void OnSRPPreRender(ScriptableRenderContext context, Camera renderingcam)
    {
        if (renderingcam == cam)
        {
            OnPreRender();
        }
    }
#endif

    /// <summary>
    /// Where various image processing effects are applied, including the green screen effect itself. 
    /// </summary>
    private void OnPreRender()
    {
        if (screenManager.TextureEye == null || screenManager.TextureEye.width == 0)
        {
            return;
        }

        // -1 means no abstraction at all
        if (abstractionMode == -1)
        {
            Graphics.Blit(screenManager.TextureEye, finalTexture);

            return;
        }

        // If the sigma has changed, recompute the weights and offsets used by the blur.
        if (UseBlurMat && Sigma != 0.0f && NumberBlurIterations > 0)
        {
            if (Sigma != currentSigma)
            {
                currentSigma = Sigma;

                ZEDPostProcessingTools.ComputeWeights(currentSigma, out weights, out offsets);

                //Send the values to the current shader
                BlurMat.SetFloatArray(WeightsID, weights);
                BlurMat.SetFloatArray(OffsetID, offsets);
            }

            // Create temporary buffers
            RenderTexture tempFinal = RenderTexture.GetTemporary(finalTexture.width, finalTexture.height, finalTexture.depth, finalTexture.format);
            RenderTexture tempFinal2 = RenderTexture.GetTemporary(finalTexture.width, finalTexture.height, finalTexture.depth, finalTexture.format);

            Graphics.Blit(screenManager.TextureEye, tempFinal);
            ZEDPostProcessingTools.Blur(tempFinal, tempFinal2, BlurMat, 4, NumberBlurIterations, 1);

            Graphics.Blit(tempFinal2, finalTexture, AbstractionMat, abstractionMode);

            //Destroy all the temporary buffers
            RenderTexture.ReleaseTemporary(tempFinal2);
            RenderTexture.ReleaseTemporary(tempFinal);
        }
        else
        {
            Graphics.Blit(screenManager.TextureEye, finalTexture, AbstractionMat, abstractionMode);
        }
    }

    private enum VideoProcessing
    {
        None = -1,
        Grayscale = 0,
        Neon = 1,
        ColorEdges = 2,
        GrayscaleEdges = 3,
        ColorEdgesAddedToGrayscale = 4,
        GrayscaleEdgesAddedToColor = 5,
        GrayscaleEdgesAddedToGrayscale = 6
    }

#if USING_FVW
    private VideoProcessing MapAbstraction(Abstraction abstraction)
    {
        return abstraction switch
        {
            Abstraction.None => VideoProcessing.None,
            Abstraction.Greyscale => VideoProcessing.Grayscale,
            Abstraction.GreyscaleEdges1 => VideoProcessing.GrayscaleEdges,
            Abstraction.GreyscaleEdges2 => VideoProcessing.GrayscaleEdgesAddedToColor,
            Abstraction.GreyscaleEdges3 => VideoProcessing.GrayscaleEdgesAddedToGrayscale,
            Abstraction.Neon => VideoProcessing.Neon,
            Abstraction.ColouredEdges1 => VideoProcessing.ColorEdges,
            Abstraction.ColouredEdges2 => VideoProcessing.ColorEdgesAddedToGrayscale,
            _ => throw new Exception($"Abstraction not set correctly. Value was {abstraction}")
        };
    }
#endif
}
