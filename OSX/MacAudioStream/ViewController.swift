//
//  ViewController.swift
//  MacAudioStream
//
//  Created by MKolesov on 25/12/15.
//  Copyright © 2015 Michael Kolesov. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, AudioStreamEngineDelegate {

    @IBOutlet weak var titleLabel: NSTextField!
    
    var audioStream: AudioStreamEngine!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioStream = AudioStreamEngine.sharedInstance()
        audioStream.delegate = self
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func playAction(sender: AnyObject) {
        
        print("play")
        if(audioStream.playing) {
            return
        }
        
        audioStream.startWithURL("http://air.radiorecord.ru:8101/rr_128")
    }

    @IBAction func stopAction(sender: AnyObject) {
        print("stop")
        audioStream.stop()
    }
    
    //MARK: AudioStreamEngine delegate
    
    func audioStreamEngineDidUpdateTitle(title: String!) {
        
        print(title)
        
        titleLabel.stringValue = title
    }
}

