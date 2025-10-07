using System.Collections;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine;
using UnityEngine.Assertions.Must;

public class EffectControls : MonoBehaviour
{
    [SerializeField]
    private Material Vignette;
    [SerializeField]
    private Material Outlines_FX;

    [SerializeField]
    private Transform Scream;
    [SerializeField]
    private Transform ScreamPivot;

    private Vector3 startPos;
    private Vector3 startEulers;

    private bool party = false;
    private bool sepia = false;

    // Start is called before the first frame update
    void Start()
    {
        Outlines_FX.SetInt("_Party", 0);
        Vignette.SetInt("_Party", 0);
        Vignette.SetFloat("_Size", 0.0f);
        Vignette.SetFloat("_SepiaIntensity", 0.0f);

        startEulers = ScreamPivot.eulerAngles;
        startPos = Scream.position;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.P))
        {
            ToggleParty();
        }
        else if (Input.GetKeyDown(KeyCode.M))
        {
            ToggleSepia();
        }
        else if (Input.GetKeyDown(KeyCode.R))
        {
            RevertToRegular();
        }

        // scream dance
        if (party)
        {
            float time = Time.realtimeSinceStartup;
            Scream.position = startPos + new Vector3(0.0f, (Mathf.Sin(time * 15.0f) + 1.0f) / 2.8f, 0.0f);
            ScreamPivot.eulerAngles = startEulers + new Vector3(Mathf.Sin(time * 15.0f) * 40.0f, Mathf.Sin(time * 15.0f) * 10.0f, Mathf.Cos(time * 15.0f) * 5.0f);
        }
        else
        {
            Scream.position = startPos;
            ScreamPivot.eulerAngles = startEulers;
        }
    }
    void ToggleParty()
    {
        if (sepia)
        {
            ToggleSepia();
        }
        party = !party;
        Outlines_FX.SetInt("_Party", party? 1 : 0);
        Vignette.SetInt("_Party", party? 1 : 0);
        Vignette.SetFloat("_Size", party? 1.23f : 0.0f);
    }

    void ToggleSepia()
    {
        if (party)
        {
            ToggleParty();
        }

        sepia = !sepia;
        Vignette.SetFloat("_Size", sepia? 1.23f : 0.0f);
        Vignette.SetFloat("_SepiaIntensity", sepia? 0.2f : 0.0f);
    }

    void RevertToRegular()
    {
        if (party)
        {
            ToggleParty();
        }
        if (sepia)
        {
            ToggleSepia();
        }
    }
}
