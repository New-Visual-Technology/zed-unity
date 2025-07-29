using UnityEditor;
using UnityEngine;

public class LookAtHeadCenter : MonoBehaviour
{

    /// <summary>
    /// The ZEDManager that the object will face each frame. Faces the left camera. 
    /// </summary>
    [Tooltip("The ZEDManager that the object will face each frame. Faces the head center object.")]
    public ZEDManager ZedManager;

    [SerializeField]
    [Tooltip("Uses -Physics.up as up vector when checked instead of Vector3.up!")]
    private bool usePhysics = false;

    [Header("----- Editor Only -----")]
    [SerializeField]
    [Tooltip("Uses the Unity Editor scene view camera position as look target, otherwise it uses Camera.main.")]
    private bool lookAtSceneViewCamera = false;

    private GameObject headCenter;

    private void Start()
    {
        if (!ZedManager)
        {
            ZedManager = FindObjectOfType<ZEDManager>();
        }

        if (ZedManager)
        {
#if ZED_NVT_FVW
            headCenter = ZedManager.GetHeadCenter();
#endif
        }
    }


    private void LateUpdate()
    {
        if (headCenter)
        {
            FaceObject(headCenter);
        }

#if UNITY_EDITOR
        if (!headCenter)
        {
            if (lookAtSceneViewCamera)
            {
                transform.rotation = Quaternion.LookRotation(transform.position - SceneView.lastActiveSceneView.camera.transform.position,
                    Vector3.up);
            }
            else
            {
                transform.rotation = Quaternion.LookRotation(transform.position - Camera.main.transform.position, Vector3.up);
            }
        }
#endif

    }

    private void FaceObject(GameObject go)
    {
        //Make sure the target and this object don't have the same position. This can happen before the cameras are initialized.
        //Calling Quaternion.LookRotation in this case spams the console with errors.
        if (transform.position - go.transform.position == Vector3.zero)
        {
            return;
        }

        if (usePhysics)
        {
            transform.rotation = Quaternion.LookRotation(transform.position - go.transform.position, -Physics.gravity);
        }
        else
        {
            transform.rotation = Quaternion.LookRotation(transform.position - go.transform.position, Vector3.up);
        }
    }
}
