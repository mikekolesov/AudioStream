//
//  StationDetailController.swift
//  AudioStream
//
//  Created by Michael Kolesov on 11/01/16.
//  Copyright © 2016 Michael Kolesov. All rights reserved.
//

import UIKit

class StationDetailController: UIViewController {

    var streamEngine: AudioStreamEngine!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playTest(sender: AnyObject) {
        
        streamEngine = AudioStreamEngine.sharedInstance()
        streamEngine.startWithURL("http://91.190.117.131:8000/live")

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
