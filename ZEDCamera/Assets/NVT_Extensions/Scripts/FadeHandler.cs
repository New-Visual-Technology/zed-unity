using System.Collections.Generic;
using System.Threading.Tasks;
using FVW.Utility;
using UnityEngine;
using UnityEngine.UI;

namespace FVW.InteractionSystem
{
    public class FadeHandler : MonoBehaviour
    {
        // render two separate UIs for each eye
        [SerializeField]
        protected bool renderTwice = true;

        [SerializeField]
        protected bool useWorldSpace;

        [SerializeField]
        protected GameObject leftUI;

        [SerializeField]
        protected GameObject rightUI;
        
        [SerializeField]
        protected float zPosition = 98f;

        [SerializeField]
        protected bool fadeInOnZedReady;

        [SerializeField]
        protected bool fadeOutOnEnable;

        [SerializeField]
        protected bool destroyOnFadeOut;
        
        [SerializeField]
        protected bool fadeInOutText;


        private ZEDManager zedManager;
        private Animation[] textAnimations;

        private string fadeOutAnimName = "fadeOut_loading_text_fadeOut";
        private string fadeInAnimName = "fadeOut_loading_text_fadeIn";

        private List<CastRaycastFromObject> activeRaycasts = new();
        protected void Start()
        {
            zedManager = FindObjectOfType<ZEDManager>(true);
            
            if (fadeInOnZedReady)
                zedManager.OnZEDReady += OnZEDReadyHandler;
            
            if (zedManager == null)
            {
                Debug.LogError($"{nameof(DisplayZedUI)} couldn't find the Zed manager in the scene!");
                Destroy(gameObject);

                return;
            }

            if (useWorldSpace)
            {
                leftUI.transform.SetParent(zedManager.GetLeftCameraTransform().parent);
            }
            else
            {
                leftUI.transform.SetParent(zedManager.GetLeftCameraTransform());
            }

            leftUI.GetComponent<Canvas>().planeDistance = zPosition;
            leftUI.GetComponent<Canvas>().worldCamera = zedManager.GetLeftCamera();

            if (useWorldSpace)
            {
                leftUI.GetComponent<Canvas>().renderMode = RenderMode.WorldSpace;
                LayoutRebuilder.MarkLayoutForRebuild(leftUI.GetComponent<RectTransform>());
            }
            
            if (renderTwice)
            {
                rightUI.SetActive(true);

                if (useWorldSpace)
                {
                    leftUI.transform.SetParent(zedManager.GetLeftCameraTransform().parent);
                }
                else
                {
                    rightUI.transform.SetParent(zedManager.GetRightCameraTransform());
                }

                rightUI.GetComponent<Canvas>().worldCamera = zedManager.GetRightCamera();
                rightUI.GetComponent<Canvas>().planeDistance = 0.31f;

                if (useWorldSpace)
                {
                    rightUI.GetComponent<Canvas>().renderMode = RenderMode.WorldSpace;
                }
            }
            else
            {
                rightUI.SetActive(false);
            }

            if (fadeOutOnEnable)
            {
                Fade(true, 1000);
                
                // disable raycasts when fadeout starts
                EnableRaycasts(false);
            }

            if (fadeInOutText)
            {
                textAnimations = new Animation[2];

                textAnimations[0] = leftUI.GetComponentInChildren<Animation>();
                textAnimations[1] = rightUI.GetComponentInChildren<Animation>();
            }
        }

        private void OnZEDReadyHandler()
        {
            Fade(false, 1000);
            
            // reactivate raycasts when Zed is ready again after resolution change
            EnableRaycasts(true);
        }

        private void EnableRaycasts(bool enable)
        {
            // make sure only originally active raycasts are later activated/deactivated
            if (!enable && activeRaycasts.Capacity == 0)
            {
                foreach (CastRaycastFromObject castRaycast in FindObjectsByType<CastRaycastFromObject>(FindObjectsInactive.Exclude, FindObjectsSortMode.None))
                {
                    activeRaycasts.Add(castRaycast);
                }
            }
            // deactivate raycasts from list, later activate them again
            foreach (CastRaycastFromObject raycast in activeRaycasts)
            {
                raycast.gameObject.SetActive(enable);
            }
        }

        public async Task Fade(bool fadeIn, int fadeDurationInMiliseconds = 500)
        {
            CanvasGroup fistCanvasGroup = leftUI.GetComponentInChildren<CanvasGroup>();
            
            float duration = (float)fadeDurationInMiliseconds / 1000;
            float elapsedTime = 0;
            float startAlpha = fistCanvasGroup.alpha;
            float targetAlpha = fadeIn ? 1 : 0;
            while (elapsedTime < duration)
            {
                rightUI.GetComponentInChildren<CanvasGroup>().alpha = Mathf.Lerp(startAlpha, targetAlpha, elapsedTime / duration);
                leftUI.GetComponentInChildren<CanvasGroup>().alpha = Mathf.Lerp(startAlpha, targetAlpha, elapsedTime  / duration);

                elapsedTime += Time.deltaTime;
                await Task.Yield(); // Yield to the Unity main thread to update the UI
            }
            
            rightUI.GetComponentInChildren<CanvasGroup>().alpha = targetAlpha;
            leftUI.GetComponentInChildren<CanvasGroup>().alpha = targetAlpha;
            
            if (fadeInOutText)
            {
                textAnimations[0].Play(fadeIn ? fadeOutAnimName : fadeInAnimName);
                textAnimations[1].Play(fadeIn ? fadeOutAnimName : fadeInAnimName);
            }

            if (destroyOnFadeOut && !fadeIn)
                Destroy(gameObject);
        }


        protected void OnDestroy()
        {
            Destroy(leftUI);
            Destroy(rightUI);
        }
    }
}
