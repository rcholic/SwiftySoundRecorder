//
//  ViewController.swift
//  SwiftySoundRecorder
//
//  Created by rcholic on 08/13/2016.
//  Copyright (c) 2016 rcholic. All rights reserved.
//

import UIKit
import SwiftySoundRecorder
import SnapKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("loaded example vC!")
    }

    @IBAction func didTapRecordButton(sender: AnyObject) {
        
        let recordRC = SwiftySoundRecorder()
        recordRC.delegate = self
        presentViewController(recordRC, animated: true, completion: nil)
    }
}

extension ViewController: SwiftySoundRecorderDelegate {
    func doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String) {
        print("done recording button tapped")
    }
    
    func cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder) {
        print("cancelled!")
    }
}

