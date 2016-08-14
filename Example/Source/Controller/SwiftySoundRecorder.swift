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
import FDWaveformViewForked
import SnapKit

internal enum SwiftySoundMode {
    case Recording
    case Playing
    case Idling
    case Cropping
}

public protocol SwiftySoundRecorderDelegate: class {
    func doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String)
    func cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder)
}

public class SwiftySoundRecorder: UIViewController {
    
    public weak var delegate: SwiftySoundRecorderDelegate?
    public var navBarButtonLabelsDict = Configuration.navBarButtonLabelsDict
    public var maxDuration: CGFloat = 0
    public var allowCropping: Bool = true
    
    private var statusBarHidden: Bool = false
    private var audioDuration: NSTimeInterval = 0
    private var audioRecorder: AVAudioRecorder? = nil
    private var audioPlayer: AVAudioPlayer? = nil
    private let audioFileType = "m4a" // AVFileTypeAppleM4A --> "com.apple.m4a-audio"
    private var curAudioPathStr: String? = nil
    private var isCroppingEnabled: Bool = false
    private var audioTimer = NSTimer() // used for both recording and playing
    
    private var operationMode: SwiftySoundMode {
        set {
            switch newValue {
            case .Idling:
                print("idling")
            case .Recording:
                print("recording")
            case .Playing:
                print("playing...")
            case .Cropping:
                print("Cropping....")
            default:
                print("idling as default")
            }
        }
        get {
            return operationMode
        }
    }
    
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
        self.operationMode = .Idling
        setupUI()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        statusBarHidden = UIApplication.sharedApplication().statusBarHidden
        UIApplication.sharedApplication().setStatusBarHidden(statusBarHidden, withAnimation: .Fade)
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        audioTimer.invalidate()
        audioPlayer = nil
        audioRecorder = nil
    }
    
    @objc private func playRecording(sender: AnyObject?) {
        guard let pathStr = curAudioPathStr else {return}
        
        let audioFileUrl = NSURL(string: pathStr)!
        if audioPlayer == nil {
            do {
                try audioPlayer = AVAudioPlayer(contentsOfURL: audioFileUrl, fileTypeHint: audioFileType)
            } catch let error {
                print("error in creating audio player: \(error)")
            }
        }
        audioDuration = audioPlayer!.duration
        print("preparing to play! duration: \(audioDuration)")
        audioPlayer!.meteringEnabled = true
        audioPlayer!.delegate = self
        audioPlayer!.rate = 1.0
        audioPlayer!.prepareToPlay()
        
        if audioPlayer!.playing {
            audioPlayer!.pause()
            self.operationMode = .Idling
            playButton.setBackgroundImage(self.playIcon, forState: .Normal)
        } else {
            playButton.setBackgroundImage(self.pauseIcon, forState: .Normal)
            self.operationMode = .Playing
            audioTimer = NSTimer.scheduledTimerWithTimeInterval(waveUpdateInterval, target: self, selector: #selector(self.audioTimerCallback), userInfo: nil, repeats: true)
        }
        self.operationMode = .Playing
    }
    
    @objc private func stopRecording(sender: AnyObject?) {
        self.operationMode = .Idling
        guard let recorder = audioRecorder else { return }
        if recorder.recording {
            recorder.stop()
        // TODO: show scissor on top of the idling status

//            audioTimer.invalidate()
//            self.operationMode = .Idling // this is taken care of by the delegate method

        }
    }
    
    @objc private func toggleRecording(sender: AnyObject?) {
        
        self.operationMode = .Recording
        
        if audioRecorder == nil {
            // initialize audio recorder, remove existing audio file, if any
            do {
                if fileManager.fileExistsAtPath(originalRecordedAudioURL.path!) {
                    try fileManager.removeItemAtURL(originalRecordedAudioURL)
                }
                try audioRecorder = AVAudioRecorder(URL: originalRecordedAudioURL, settings: recorderSettings)
            } catch let error {
                print("error in recording: \(error)")
            }
        }
        
        if audioRecorder!.recording {
            audioRecorder!.pause()
            audioTimer.invalidate()
        } else {
            audioRecorder!.prepareToRecord()
            audioRecorder!.meteringEnabled = true
            audioRecorder!.delegate = self
            audioTimer = NSTimer.scheduledTimerWithTimeInterval(waveUpdateInterval, target: self, selector: #selector(self.audioTimerCallback), userInfo: nil, repeats: true)
            audioRecorder!.record()
            
            print("recorder started")
        }
    }
    
    @objc private func audioTimerCallback() {
        if self.operationMode == .Playing {
            // TODO
        } else if self.operationMode == .Recording {
            // TODO
        }
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
    
    @objc private func didTapDoneButton(sender: UIButton) {
        self.doneRecordingDidPress(self, audioFilePath: curAudioPathStr!)
    }
    
    // MARK: buttons
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 130, height: 30))
        button.setTitle("Cancel", forState: .Normal)
        
        button.tintColor = self.view.tintColor
        button.setTitleColor(self.view.tintColor, forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        
        button.addTarget(self, action: #selector(self.cancelRecordingDidPress(_:)), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(frame: CGRect(x: self.view.bounds.width-130, y: 10, width: 130, height: 30))
        button.setTitle("Done", forState: .Normal)
        button.enabled = false
        button.tintColor = self.view.tintColor
        button.setTitleColor(self.view.tintColor, forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        button.addTarget(self, action: #selector(self.didTapDoneButton), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    private let playIcon = UIImage(named: "ic_play_arrow")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.playIcon, forState: .Normal)
        button.tintColor = self.view.tintColor
        button.setTitleColor(UIColor.redColor(), forState: .Highlighted) // ???
        button.contentMode = .ScaleAspectFit
        button.addTarget(self, action: #selector(self.playRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    let stopIcon = UIImage(named: "ic_stop")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var stopButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.stopIcon, forState: .Normal)
        button.contentMode = .ScaleAspectFit
        button.tintColor = UIColor.redColor()
        button.addTarget(self, action: #selector(self.stopRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    // pauseButton and micButton alternate in the same position
    let pauseIcon = UIImage(named: "ic_pause")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var pauseRecordingButton: UIButton = {
        let button = UIButton(type: .Custom)
        //        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.pauseIcon, forState: .Normal)
        button.tintColor = UIColor.redColor()
        button.contentMode = .ScaleAspectFit
        button.addTarget(self, action: #selector(self.toggleRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    let micIcon = UIImage(named: "ic_mic")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var micButton: UIButton = {
        let button = UIButton(type: .Custom)
        //        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.micIcon, forState: .Normal)
        //        button.setTitleColor(UIColor.redColor(), forState: .Highlighted)
        button.tintColor = UIColor.redColor()
        button.contentMode = .ScaleAspectFit
        button.addTarget(self, action: #selector(self.toggleRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
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
    
    private let recorderSettings = [AVSampleRateKey : NSNumber(float: Float(44100.0)),
                                    AVFormatIDKey : NSNumber(int: Int32(kAudioFormatMPEG4AAC)),
                                    AVNumberOfChannelsKey : NSNumber(int: 2),
                                    AVEncoderAudioQualityKey : NSNumber(int: Int32(AVAudioQuality.Medium.rawValue))]
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

extension SwiftySoundRecorder: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        print("audio player finished playing! succssfully? \(flag)")
        audioTimer.invalidate()
        playButton.setBackgroundImage(self.playIcon, forState: .Normal)
        audioPlayer = nil
        self.operationMode = .Idling
    }
    
    public func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        print("audio player began to be interrupted")
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer) {
        print("audio player ended interruption")
    }
}

extension SwiftySoundRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        //        audioDuration = floor(recorder.currentTime / 60)
        curAudioPathStr = recorder.url.path
        audioTimer.invalidate()
        self.operationMode = .Idling
        audioRecorder = nil
        micButton.setBackgroundImage(micIcon, forState: .Normal)
        print("finished recording: duration: \(audioDuration)")
    }
}



