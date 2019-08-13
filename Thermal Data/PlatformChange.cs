using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlatformChange : MonoBehaviour
{

    // Use this for initialization
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.A))
        {
            gameObject.GetComponent<Renderer>().material.color = new Color(1, 0, 0, 0.45F);
        }
        else if (Input.GetKeyDown(KeyCode.S))
        {
            gameObject.GetComponent<Renderer>().material.color = new Color(0, 0, 1, 0.45F);
        }
        if (Input.GetKeyDown(KeyCode.P) && gameObject.GetComponent<Renderer>().enabled)
        {
            gameObject.GetComponent<Renderer>().enabled = false;
        }
        else if (Input.GetKeyDown(KeyCode.P) && !gameObject.GetComponent<Renderer>().enabled)
        {
            gameObject.GetComponent<Renderer>().enabled = true;
        }
    }
}
