using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ProcessZEDImages : MonoBehaviour
{
    [Header ("Color Image")]
    /// <summary>
    /// Material to use for bluring a texture.
    /// </summary>
    public Material BlurMat;

    /// <summary>
    /// Material to use for video post processing.
    /// </summary>
    public Material PostProcessMat;

    [Header ("Depth Image")]
    public Material ToBinaryMat;
    public Material DillationMat;
    public Material ErosionMat;

    [Header ("...")]
    public RenderTexture MaskTexture;

    private MaterialPropertyBlock materialPropertyBlock;
    public MaterialPropertyBlock MaterialPropertyBlock { set => materialPropertyBlock = value; }

    private readonly int mainTexID = Shader.PropertyToID("_MainTex");
    private readonly int depthXYZTexID = Shader.PropertyToID("_DepthXYZTex");

    private RenderTexture tmpMainTex;
    private RenderTexture tmpDepthXYZTex;

    public void ProcessEyeImage(Renderer rend)
    {
        Texture mainTexSource = rend.material.GetTexture(mainTexID);

        // Create temporary render textures
        if (mainTexSource != null && tmpMainTex == null)
        {
            tmpMainTex = RenderTexture.GetTemporary(mainTexSource.width, mainTexSource.height);
        }

        Texture depthXYZTexSource = rend.material.GetTexture(depthXYZTexID);

        // Create temporary render textures
        if (depthXYZTexSource != null && tmpDepthXYZTex == null)
        {
            tmpDepthXYZTex = RenderTexture.GetTemporary(depthXYZTexSource.width, depthXYZTexSource.height, 0, RenderTextureFormat.RFloat);
        }

        //Graphics.Blit(depthXYZTexSource, tmpDepthXYZTex, ToBinaryMat);
        Graphics.Blit(MaskTexture, tmpDepthXYZTex, ToBinaryMat);

        //RenderTexture tmp = RenderTexture.GetTemporary(mainTexSource.width, mainTexSource.height);
        //Graphics.Blit(mainTexSource, tmp, BlurMat);
        //RenderTexture.ReleaseTemporary(tmp);

        RenderTexture tmpTex = RenderTexture.GetTemporary(depthXYZTexSource.width, depthXYZTexSource.height, 0, RenderTextureFormat.RFloat);
        //Graphics.Blit(tmpDepthXYZTex, tmpTex, DillationMat);
        //Graphics.Blit(tmpTex, tmpDepthXYZTex, ErosionMat);
        //Graphics.Blit(tmpDepthXYZTex, tmpTex, ErosionMat);
        //Graphics.Blit(tmpTex, tmpDepthXYZTex);
        RenderTexture.ReleaseTemporary(tmpTex);

        if (PostProcessMat != null)
        {
            if (BlurMat == null)
            {
                Graphics.Blit(mainTexSource, tmpMainTex, PostProcessMat);
            }
            else
            {
                // Horizontal blur
                BlurMat.SetVector("_Direction", new Vector4(1.0f, 0.0f, 0.0f, 0.0f));
                Graphics.Blit(mainTexSource, tmpMainTex, BlurMat);

                // Vertical blur
                RenderTexture tmpSource2 = RenderTexture.GetTemporary(mainTexSource.width, mainTexSource.height);
                BlurMat.SetVector("_Direction", new Vector4(0.0f, 1.0f, 0.0f, 0.0f));
                Graphics.Blit(tmpMainTex, tmpSource2, BlurMat);

                Graphics.Blit(tmpSource2, tmpMainTex, PostProcessMat);

                RenderTexture.ReleaseTemporary(tmpSource2);
            }
        }
        else
        {
            Graphics.Blit(mainTexSource, tmpMainTex);
        }

        materialPropertyBlock.SetTexture("_DepthXYZTex", tmpDepthXYZTex, RenderTextureSubElement.Color);
        materialPropertyBlock.SetTexture("_MainTex", tmpMainTex, RenderTextureSubElement.Color);
    }

    private void OnDestroy()
    {
        RenderTexture.ReleaseTemporary(tmpMainTex);
        RenderTexture.ReleaseTemporary(tmpDepthXYZTex);
    }
}
