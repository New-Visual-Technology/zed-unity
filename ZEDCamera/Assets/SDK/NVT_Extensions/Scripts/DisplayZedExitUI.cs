using System;
using System.Threading.Tasks;
using UnityEngine;

namespace FVW.InteractionSystem
{
    public class DisplayZedExitUI : DisplayZedUI
    {
        [SerializeField]
        private float waitBeforeFadeToBlack = 6f;

        protected override async void OnEnable()
        {
            base.OnEnable();

            await Task.Delay(TimeSpan.FromSeconds(waitBeforeFadeToBlack));

            StartFadeToBlack();
        }
    }
}
