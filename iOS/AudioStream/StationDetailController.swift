//
//  StationDetailController.swift
//  AudioStream
//
//  Created by Michael Kolesov on 11/01/16.
//  Copyright © 2016 Michael Kolesov. All rights reserved.
//

import UIKit
import Crashlytics


class StationDetailController: UIViewController, AudioStreamEngineDelegate{

    @IBOutlet weak var audioNameLabel: UILabel!
    var streamEngine: AudioStreamEngine!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(type: UIButtonType.roundedRect)
        button.frame = CGRect.init(x: 100, y: 100, width: 100, height: 30)
        button.setTitle("Crash", for: UIControlState(rawValue: UInt(0)))
        button.addTarget(self, action: Selector(("crashButtonTapped:")), for: UIControlEvents.touchUpInside)
        view.addSubview(button)
    }

    @IBAction func crashButtonTapped(sender: AnyObject) {
        Crashlytics.sharedInstance().crash()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playTest(_ sender: AnyObject) {
        
        streamEngine = AudioStreamEngine.sharedInstance()
        streamEngine.delegate = self
        streamEngine.start(withURL: "http://air.radiorecord.ru:8101/rr_128")

    }

    // MARK: - AudioStreamEngine delegate
    func audioStreamEngineDidUpdateTitle(_ title: String!) {
        audioNameLabel.text = title
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
