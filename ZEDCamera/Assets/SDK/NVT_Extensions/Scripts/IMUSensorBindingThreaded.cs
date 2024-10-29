using System.Threading;
using sl;
using UnityEngine;
#if USING_FVW
using FVW.Events;
using FVW.Utility.Unity;
#endif


public class IMUSensorBindingThreaded : MonoBehaviour
{
    [SerializeField] private ZEDManager zedManager;
#if USING_FVW
    [SerializeField] private IMUSensorDataObject imuSensorDataObject;
    [SerializeField] private WeldingObjectVector3Buffered gravityDirection;
    [SerializeField] private WeldingObjectQuaternionBuffered fusedOrientation;
#endif

    private SensorsData sensors_data;
    private ulong last_imu_timestamp = 0;

    private Thread threadGrab = null;
    private bool running = false;

    private void Start()
    {
        running = true;

        threadGrab = new Thread(new ThreadStart(ThreadedZEDGrab));
        threadGrab.Start();
    }


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
    }

    private void OnApplicationQuit()
    {
        Destroy();
    }

    private void OnDestroy()
    {
        Destroy();
    }

    private void ThreadedZEDGrab()
    {
        //int frameTime_msec = (int)(1000.0f / 400.0f);
        int frameTime_msec = 1;

        while (running)
        {
            if (zedManager != null && zedManager.zedCamera != null)
            {
#if USING_FVW
                if (!zedManager.running)
                {
                    if (imuSensorDataObject.Running)
                    {
                        imuSensorDataObject.Running = false;
                    }
                }
                else
                {
                    zedManager.zedCamera.GetInternalSensorsData(ref sensors_data, TIME_REFERENCE.CURRENT);

                    if (sensors_data.imu.timestamp > last_imu_timestamp)
                    {
                        // Set Sensors Data in Scriptable Object
                        if (imuSensorDataObject != null)
                        {
                            imuSensorDataObject.Timestamp = sensors_data.imu.timestamp;
                            imuSensorDataObject.FusedOrientation = sensors_data.imu.fusedOrientation;
                            imuSensorDataObject.GravityDirection = sensors_data.imu.linearAcceleration;

                            if (!imuSensorDataObject.Running)
                            {
                                imuSensorDataObject.Running = true;
                            }
                        }

                        if (fusedOrientation != null)
                        {
                            fusedOrientation.Value = sensors_data.imu.fusedOrientation.ConvertQuaternion();
                        }

                        if (gravityDirection != null)
                        {
                            gravityDirection.Value = sensors_data.imu.linearAcceleration.Invert();
                        }

                        last_imu_timestamp = sensors_data.imu.timestamp;
                    }
                }
#endif
            }

            Thread.Sleep(frameTime_msec);
        }
    }

    private void Destroy()
    {
        running = false;

        if (threadGrab != null)
        {
            threadGrab.Join();
            threadGrab = null;
        }

        Thread.Sleep(10);
    }
}
