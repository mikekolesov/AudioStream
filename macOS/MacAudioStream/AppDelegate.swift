//
//  AppDelegate.swift
//  MacAudioStream
//
//  Created by MKolesov on 25/12/15.
//  Copyright © 2015 Michael Kolesov. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var statusButton: NSStatusBarButton!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        activateStatusBarItem()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func activateStatusBarItem() {
        
        let statusBar = NSStatusBar.system()
        
        statusItem = statusBar.statusItem(withLength: NSVariableStatusItemLength);
        statusButton = statusItem.button
        statusButton?.title = "Audio!"
        statusButton?.target = self
        statusButton?.action = #selector(statusAction)
    }
    
    func statusAction() {
        print("status!!!")
    }
    
}

