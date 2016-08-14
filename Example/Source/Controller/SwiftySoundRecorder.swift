//
//  SwiftySoundRecorder.swift
//  SwiftySoundRecorder
//
//  Created by Guoliang Wang on 8/12/16.
//
//

import UIKit

import AVFoundation
import SCSiriWaveformView
import FDWaveformView
import SnapKit

public protocol SwiftySoundRecorderDelegate: class {
    func doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String)
    func cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder)
}

public class SwiftySoundRecorder: UIViewController {
    
    public weak var delegate: SwiftySoundRecorderDelegate?
    
    private var statusBarHidden: Bool = false
    
    public var maxDuration: CGFloat = 0
    private var audioDuration: NSTimeInterval = 0
    private var audioRecorder: AVAudioRecorder? = nil
    private var audioPlayer: AVAudioPlayer? = nil
    private let audioFileType = "m4a" // AVFileTypeAppleM4A --> "com.apple.m4a-audio"
    private var curAudioPathStr: String? = nil
    private var isCroppingEnabled = false
    private var audioTimer = NSTimer() // used for both recording and playing
    
    public var navBarButtonLabelsDict = Configuration.navBarButtonLabelsDict
    
    private var waveNormalTintColor = Configuration.recorderWaveNormalTintColor
    
    private var waveHighlightedTintColor = Configuration.recorderWaveHighlightedTintColor
    
    private let frostedView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    
    private let waveUpdateInterval: NSTimeInterval = 0.01
    private let navbarHeight: CGFloat = Configuration.navBarHeight
    
    
    private let fileManager = NSFileManager.defaultManager()
    private var leftPanGesture: UIPanGestureRecognizer!
    private var rightPanGesture: UIPanGestureRecognizer!
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        print("audioFileType: \(audioFileType)")
        setupUI()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        statusBarHidden = UIApplication.sharedApplication().statusBarHidden
        UIApplication.sharedApplication().setStatusBarHidden(statusBarHidden, withAnimation: .Fade)
    }
    
    private func setupUI() {
        let bounds = self.view.bounds
        
        leftPanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.didMoveLeftCropper(_:)))
        rightPanGesture = UIPanGestureRecognizer(target: self, action: #selector(self.didMoveRightCropper(_:)))
        
        print("setting up UI in Sound Recorder")
//        self.view.backgroundColor = Configuration.defaultBlueTintColor
        self.view.addSubview(backgroundImageView)
        frostedView.frame = bounds
        self.view.addSubview(frostedView)
        
    }
    
    public lazy var docDirectoryPath: NSURL = {
        let docPath = self.fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        
        return docPath
    }()
    
    private lazy var originalRecordedAudioURL: NSURL = {
        let fileUrl = self.docDirectoryPath.URLByAppendingPathComponent(Configuration.originalRecordingFileName)
        
        return fileUrl
    }()
    
    private lazy var trimmedAudioURL: NSURL = {
        let fileUrl = self.docDirectoryPath.URLByAppendingPathComponent(Configuration.trimmedRecordingFileName)
        
        return fileUrl
    }()
    
    private lazy var audioWaveContainerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 200)) // self.view.bounds.height - self.navBar.bounds.height - self.bottomToolbar.bounds.height
        view.clipsToBounds = true
        view.backgroundColor = UIColor.clearColor() // UIColor.whiteColor()
        view.center = self.view.center
        
        return view
    }()
    
    private lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: Configuration.milkyWayImage)
        
        return imageView
    }()
    
    private lazy var leftCropper: Cropper = {
        let cropper = Cropper(cropperType: .Left, lineThickness: 3, lineColor: UIColor.redColor())
        cropper.addGestureRecognizer(self.leftPanGesture)
        cropper.hidden = true
        
        return cropper
    }()
    
    private lazy var rightCropper: Cropper = {
        let cropper = Cropper(cropperType: .Right, lineThickness: 3, lineColor: UIColor.redColor())
        cropper.addGestureRecognizer(self.rightPanGesture)
        cropper.hidden = true
        
        return cropper
    }()
}

extension SwiftySoundRecorder: SwiftySoundRecorderDelegate {
    public func cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder) {
        delegate?.cancelRecordingDidPress(self)
    }
    
    public func doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String) {
        delegate?.doneRecordingDidPress(self, audioFilePath: audioFilePath)
    }
}

// Pan Gestures here
extension SwiftySoundRecorder {
    
    @objc func didMoveLeftCropper(panRecognizer: UIPanGestureRecognizer) {
        // TODO:
        print("did move left cropper")
    }
    
    @objc func didMoveRightCropper(panRecognizer: UIPanGestureRecognizer) {
        // TODO:
        print("not implemented yet! right move cropper")
    }
}


