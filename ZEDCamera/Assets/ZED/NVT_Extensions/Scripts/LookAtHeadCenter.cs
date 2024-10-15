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

    private GameObject headCenter;

    private void Start()
    {
        if (!ZedManager)
        {
            ZedManager = FindObjectOfType<ZEDManager>();
        }

        if (ZedManager)
        {
            headCenter = ZedManager.GetHeadCenter();
        }
    }


    private void LateUpdate()
    {
        if (headCenter)
        {
            FaceObject(headCenter);
        }
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
