using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ColourChange : MonoBehaviour
{
    public Material[] materials;
    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
        {
            gameObject.GetComponent<Renderer>().material = materials[0];
            gameObject.GetComponent<Renderer>().material.color = Color.red;
           
        }
        else if (Input.GetKeyDown(KeyCode.W))
        {
            gameObject.GetComponent<Renderer>().material = materials[0];
            gameObject.GetComponent<Renderer>().material.color = Color.blue;
            
        }
        else if (Input.GetKeyDown(KeyCode.E))
        {
            gameObject.GetComponent<Renderer>().material = materials[0];
            gameObject.GetComponent<Renderer>().material.color = Color.white;
        }
        else if (Input.GetKeyDown(KeyCode.R))
        {
            gameObject.GetComponent<Renderer>().material = materials[1];
        }
        else if (Input.GetKeyDown(KeyCode.T))
        {
            gameObject.GetComponent<Renderer>().material = materials[2];
        }
    }
}
