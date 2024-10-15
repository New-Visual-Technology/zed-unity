using System;
using System.Threading.Tasks;
using UnityEngine;
using UnityEngine.Serialization;
using UnityEngine.UI;

namespace FVW.InteractionSystem
{
    public class DisplayZedUI : MonoBehaviour
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
        [FormerlySerializedAs("text")]
        protected string mainText;

        [SerializeField]
        protected bool fadeInOnEnable;

        [SerializeField] protected bool enableOnEnable = false;

        [SerializeField]
        protected float zPosition = 98f;

        protected static readonly int FadeIn = Animator.StringToHash("FadeIn");
        protected static readonly int FadeOut = Animator.StringToHash("FadeOut");
        protected static readonly int FadeToBlack = Animator.StringToHash("FadeToBlack");

        protected void Start()
        {
            ZEDManager zedManager = FindObjectOfType<ZEDManager>(true);

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

            Text textLeft = leftUI.GetComponentInChildren<Text>(true);

            if (mainText != string.Empty)
            {
                textLeft.text = mainText;
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

                Text textRight = rightUI.GetComponentInChildren<Text>(true);

                if (mainText != string.Empty)
                {
                    textRight.text = mainText;
                }
            }
            else
            {
                rightUI.SetActive(false);
            }
        }

        protected virtual async void OnEnable()
        {
            if (fadeInOnEnable)
            {
                leftUI?.GetComponent<Animator>()?.SetTrigger(FadeIn);
                rightUI?.GetComponent<Animator>()?.SetTrigger(FadeIn);
            }
            if (enableOnEnable)
            {
                leftUI?.SetActive(true);
                rightUI?.SetActive(true);
            }
        }
        
        protected virtual async void OnDisable()
        {
            if (enableOnEnable)
            {
                leftUI?.SetActive(false);
                rightUI?.SetActive(false);
            }
        }

        public void StartFadeOut()
        {
            leftUI?.GetComponent<Animator>()?.SetTrigger(FadeOut);
            rightUI?.GetComponent<Animator>()?.SetTrigger(FadeOut);
        }

        public void StartFadeToBlack()
        {
            leftUI?.GetComponent<Animator>()?.SetTrigger(FadeToBlack);
            rightUI?.GetComponent<Animator>()?.SetTrigger(FadeToBlack);
        }

        protected async void OnDestroy()
        {
            leftUI?.GetComponent<Animator>()?.SetTrigger(FadeOut);
            rightUI?.GetComponent<Animator>()?.SetTrigger(FadeOut);
            
            await Task.Delay(TimeSpan.FromSeconds(2f));

            Destroy(leftUI);
            Destroy(rightUI);
        }
    }
}
