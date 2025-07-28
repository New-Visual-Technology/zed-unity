using sl;
using UnityEngine;
#if ZED_NVT_FVW
using FVW.Events;
using FVW.Utility.Unity;
#endif

public class IMUSensorBinding : MonoBehaviour
{
    // Set configuration parameters
    [SerializeField] private ZEDManager zedManager;
#if ZED_NVT_FVW
    [SerializeField] private IMUSensorDataObject imuSensorDataObject;
    [SerializeField] private WeldingObjectVector3Buffered gravityDirection;
#endif

    private SensorsData sensors_data;
    private ulong last_imu_timestamp = 0;

    private void Update()
    {
        if (!zedManager)
        {
            if (FindObjectOfType<ZEDManager>())
            {
                zedManager = FindObjectOfType<ZEDManager>();
            }

            return;
        }

#if ZED_NVT_FVW
        if (!zedManager.IsRunning)
        {
            if (imuSensorDataObject.Running)
            {
                imuSensorDataObject.Running = false;
            }

            return;
        }

        zedManager.zedCamera.GetInternalSensorsData(ref sensors_data, TIME_REFERENCE.CURRENT);

        if (sensors_data.imu.timestamp > last_imu_timestamp)
        {
            // Set Sensors Data in Scriptable Object
            imuSensorDataObject.FusedOrientation = sensors_data.imu.fusedOrientation;

            gravityDirection.Value = sensors_data.imu.linearAcceleration.ConvertRHYDToLHYU();

            last_imu_timestamp = sensors_data.imu.timestamp;

            if (!imuSensorDataObject.Running)
            {
                imuSensorDataObject.Running = true;
            }
        }
#endif
    }
}
