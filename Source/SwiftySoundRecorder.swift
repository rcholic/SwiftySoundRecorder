//
//  SwiftySoundRecorder.swift
//  SwiftySoundRecorder
//
//  Created by Guoliang Wang on 8/12/16.
//
//

import UIKit

public protocol SwiftySoundRecorderDelegate: class {
    func doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String)
    func cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder)
}

public class SwiftySoundRecorder: UIViewController {
    
    public weak var delegate: SwiftySoundRecorderDelegate!
    private var statusBarHidden: Bool = false
    
    /*
    init() {
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public convenience init() {
        super.init()
    }
    */
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        print("setting up UI in Sound Recorder")
    }
}

extension SwiftySoundRecorder: SwiftySoundRecorderDelegate {
    public func cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder) {
        delegate?.cancelRecordingDidPress(self)
    }
    
    public func doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String) {
        delegate?.doneRecordingDidPress(self, audioFilePath: audioFilePath)
    }
}
