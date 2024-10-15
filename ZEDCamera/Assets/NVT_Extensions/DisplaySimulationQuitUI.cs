using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DisplaySimulationQuitUI : MonoBehaviour
{
    [SerializeField]
    private GameObject leftUI;
    
    [SerializeField]
    private GameObject rightUI;
    private void Start()
    {
        ZEDManager zedManager = GameObject.FindObjectOfType<ZEDManager>(true);

        leftUI.transform.SetParent(zedManager.GetLeftCameraTransform());
        leftUI.GetComponent<Canvas>().worldCamera = zedManager.GetLeftCamera();
        leftUI.GetComponent<Canvas>().planeDistance = 1;
        
        Text textLeft = leftUI.GetComponentInChildren<UnityEngine.UI.Text>();
        textLeft.text = $"Simulation is shutting down.{Environment.NewLine}Please check your Fronius tablet.";
        
        rightUI.transform.SetParent(zedManager.GetRightCameraTransform());
        rightUI.GetComponent<Canvas>().worldCamera = zedManager.GetRightCamera();
        rightUI.GetComponent<Canvas>().planeDistance = 1;
        
        Text textRight = rightUI.GetComponentInChildren<UnityEngine.UI.Text>();
        textRight.text = $"Simulation is shutting down.{Environment.NewLine}Please check your Fronius tablet.";
    }
}
