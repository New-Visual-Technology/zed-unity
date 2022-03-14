using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using sl;


public class IMUSensorBinding : MonoBehaviour
{
    // Set configuration parameters
    [SerializeField] private ZEDManager zedManager;
    [SerializeField] private IMUSensorDataObject imuSensorDataObject;

    private SensorsData sensors_data;

    private void Update()
    {

        if (!zedManager)
        {
            if (FindObjectOfType<ZEDManager>())
                zedManager = FindObjectOfType<ZEDManager>();
            return;
        }

        if (!zedManager.running)
        {
            if (imuSensorDataObject.running)
                imuSensorDataObject.running = false;
            return;
        }

        ulong last_imu_timestamp = 0;

        zedManager.zedCamera.GetInternalSensorsData(ref sensors_data, TIME_REFERENCE.CURRENT);
        if (sensors_data.imu.timestamp > last_imu_timestamp)
        {
            // Set Sensors Data in Scriptable Object
            imuSensorDataObject.fusedOrientation =  sensors_data.imu.fusedOrientation;

            last_imu_timestamp = sensors_data.imu.timestamp;
            if (!imuSensorDataObject.running)
                imuSensorDataObject.running = true;
        }
    }
}
