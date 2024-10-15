using UnityEngine;

using sl;

using NVT.EventSystem;

/// <summary>
/// Calculates the brightness of the left ZED camera grayscale image.
/// </summary>
public class CameraBrightnessManager : MonoBehaviour
{
    private ZEDManager cameraManager = null;

    private sl.ZEDMat zedMat = null;

    private float t;

    /// <summary>
    /// Whether the camera has been set up yet, used for blocking calls made too early.
    /// </summary>
    private bool isInit = false;

    [SerializeField]
    [Tooltip("Time interval between the brightness calculations")]
    private float timeIntervall = 1.0f;
    
    [SerializeField]
    [Tooltip("Sample interval between the pixels used to calculate the image brightness")]
    [Range(1, 2000)]
    private int sampleInterval = 1;

    [SerializeField]
    private IntObject cameraBrightnessObject = null;

    private int cameraBrightness = 0;
    /// <summary>
    /// Brightness of the real-world image. Values are in percentage from 0 to 100.
    /// </summary>
    public int CameraBrightness
    {
        get { return cameraBrightness; }
        set
        {
            if (cameraBrightness == value)
                return;

            cameraBrightness = value;

            if (cameraBrightnessObject != null)
                cameraBrightnessObject.Value = cameraBrightness;
        }
    }

    private void OnEnable()
    {
        cameraManager = gameObject.GetComponentInParent<ZEDManager>();
        if (!cameraManager)
        {
            cameraManager = FindObjectOfType<ZEDManager>();
        }

        cameraManager.OnZEDReady += ZEDReady;
        cameraManager.OnGrab += OnZEDGrabbed;
    }

    private void OnDisable()
    {
        if (cameraManager)
        {
            cameraManager.OnZEDReady -= ZEDReady;
            cameraManager.OnGrab -= OnZEDGrabbed;
        }
    }

    /// <summary>
    /// Initialization logic that must be done after the ZED camera has finished initializing.
    /// Added to the ZEDManager.OnZEDReady() callback in OnEnable().
    /// </summary>
    private void ZEDReady()
    {
        if (cameraManager == null)
            return;

        isInit = true;
    }

    /// <summary>
    /// Where various image processing effects are applied, including the green screen effect itself. 
    /// </summary>
    private void OnZEDGrabbed()
    {
        if (!isInit)
            return; //We haven't set up the camera mat yet, so we can't call any of the events that need it. 

        t += Time.deltaTime;
        if (t < timeIntervall)
        {
            return;
        }

        t = 0;

        CalculateIntensity(ref zedMat, VIEW.LEFT_GREY, ZEDMat.MAT_TYPE.MAT_8U_C1);
    }

    private void CalculateIntensity(ref ZEDMat zedmat, VIEW view, ZEDMat.MAT_TYPE mattype)
    {
        if (zedmat == null)
        {
            zedmat = new ZEDMat();
            zedmat.Create(new sl.Resolution((uint) cameraManager.zedCamera.ImageWidth, (uint) cameraManager.zedCamera.ImageHeight), mattype);
        }

        ERROR_CODE err = cameraManager.zedCamera.RetrieveImage(zedmat, view, ZEDMat.MEM.MEM_CPU, zedmat.GetResolution());

        if (err == ERROR_CODE.SUCCESS)
        {
            int width = zedmat.GetWidth();
            int height = zedmat.GetHeight();
            int dataLength = width * height;
            int cnt = dataLength / sampleInterval;

            float intensity = 0f;

            int x;
            int y;

            for (int i = 0; i < dataLength; i += sampleInterval)
            {
                y = i / width;
                x = y == 0 ? i : i % (y * width);
                zedmat.GetValue(x, y, out byte val, ZEDMat.MEM.MEM_CPU);
                intensity += val;
            }

            intensity /= cnt;

            CameraBrightness = Mathf.FloorToInt(intensity * 100f / 255f);

//#if DEBUG
//            Debug.Log("CameraBrightnessManager.OnPreRender: cameraBrightness = " + CameraBrightness);
//#endif
        }
    }
}
