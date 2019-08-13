using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VisibleIce : MonoBehaviour {

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
        if (Input.GetKeyDown(KeyCode.U) && gameObject.GetComponent<Renderer>().enabled)
        {
            gameObject.GetComponent<Renderer>().enabled = false;
        }
        else if (Input.GetKeyDown(KeyCode.U) && !gameObject.GetComponent<Renderer>().enabled)
        {
            gameObject.GetComponent<Renderer>().enabled = true;
        }
    }
}
