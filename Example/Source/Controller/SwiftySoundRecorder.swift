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
    
    private var waveNormalTintColor = Configuration.recorderWaveNormalTintColor
    private var waveHighlightedTintColor = Configuration.recorderWaveHighlightedTintColor
    private let frostedView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    private let waveUpdateInterval: NSTimeInterval = 0.01
    private let navbarHeight: CGFloat = Configuration.navBarHeight
    private let fileManager = NSFileManager.defaultManager()
    private var leftPanGesture: UIPanGestureRecognizer!
    private var rightPanGesture: UIPanGestureRecognizer!
    private var _operationMode: SwiftySoundMode = .Idling
    
    private var operationMode: SwiftySoundMode = .Idling {
        willSet(newValue) {
            if _operationMode != newValue {
                print("updating UI now")
                self.updateUIForOperation(newValue)
            }
            _operationMode = newValue
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        curAudioPathStr = nil
        operationMode = .Idling
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
        self.operationMode = .Playing
        let audioFileUrl = NSURL(string: pathStr)!
        if audioPlayer == nil {
            do {
                try audioPlayer = AVAudioPlayer(contentsOfURL: audioFileUrl, fileTypeHint: audioFileType)
                audioDuration = 0 // start counting duration for every new player
            } catch let error {
                print("error in creating audio player: \(error)")
            }
        }
//        audioDuration = audioPlayer!.duration
        print("preparing to play! duration: \(audioPlayer!.duration)")
        audioPlayer!.meteringEnabled = true
        audioPlayer!.delegate = self
        audioPlayer!.rate = 1.0
        audioPlayer!.prepareToPlay()
        
        if audioPlayer!.playing {
            audioPlayer!.pause()
            print("audio player paused!")
            audioTimer.invalidate()
//            self.operationMode = .Idling
            playButton.setBackgroundImage(self.playIcon, forState: .Normal)
        } else {
            playButton.setBackgroundImage(self.pauseIcon, forState: .Normal)
//            self.operationMode = .Playing
            audioTimer = NSTimer.scheduledTimerWithTimeInterval(waveUpdateInterval, target: self, selector: #selector(self.audioTimerCallback), userInfo: nil, repeats: true)
            audioPlayer!.play()
            print("player is playing")
        }
    }
    
    @objc private func stopRecording(sender: AnyObject?) {
        self.operationMode = .Idling
        guard let recorder = audioRecorder else { return }
        if recorder.recording {
            recorder.stop()
        }
        print("invalidating audio timer")
        audioTimer.invalidate()
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
                audioDuration = (maxDuration > 0) ? NSTimeInterval(maxDuration) : 0 // if maxDuration > 0 -> count down, otherwise count up
            } catch let error {
                print("error in recording: \(error)")
            }
        }
        
        if audioRecorder!.recording {
            audioRecorder!.pause()
            audioTimer.invalidate()
            micButton.setImage(micIcon, forState: .Normal)
        } else {
            audioRecorder!.prepareToRecord()
            audioRecorder!.meteringEnabled = true
            audioRecorder!.delegate = self
            audioTimer = NSTimer.scheduledTimerWithTimeInterval(waveUpdateInterval, target: self, selector: #selector(self.audioTimerCallback), userInfo: nil, repeats: true)
            audioRecorder!.record()
            micButton.setBackgroundImage(pauseIcon, forState: .Normal)
            print("recorder started")
        }
    }
    
    @objc private func beginAudioCropMode(sender: AnyObject?) {
        
        guard let filePathStr = curAudioPathStr else { return }
        
        if let player = audioPlayer {
            player.stop()
            audioTimer.invalidate()
        }
        
        self.operationMode = .Cropping // TODO: stop audioRecorder, player, buttons etc.
        let fileURL = NSURL(fileURLWithPath: filePathStr)
        self.waveFormView.audioURL = fileURL
        
        if isCroppingEnabled && sender as! UIButton == scissorButton {
            trimAudio(fileURL, startTime: leftCropper._cropTime, endTime: rightCropper._cropTime)
        }
    }
    
    @objc private func audioTimerCallback() {
        var remainingTime: NSTimeInterval = 0
        if self.operationMode == .Playing && audioPlayer != nil {
            audioPlayer!.updateMeters()
            remainingTime = audioPlayer!.currentTime // count up for playing
            audioSiriWaveView.updateWithLevel(CGFloat(pow(10, audioPlayer!.averagePowerForChannel(0)/20)))
            
        } else if self.operationMode == .Recording && audioRecorder != nil {
            audioRecorder!.updateMeters()
            if maxDuration > 0 {

                remainingTime = NSTimeInterval(maxDuration) - audioRecorder!.currentTime  // count down for recording if maxDuration is set

                if audioRecorder!.currentTime >= NSTimeInterval(maxDuration) {
                    self.stopRecording(nil)
                } else if (remainingTime <= 6) {
                    print("remaining: \(remainingTime)")
                    // Give warning when the remaining time is 6 sec or less
                    if Int(remainingTime) % 2 == 1 {
                        // TODO: flash the color every half second rather than 1 sec
                        clockIcon.tintColor = UIColor.redColor()
                        timeLabel.textColor = UIColor.redColor()
                    } else {
                        clockIcon.tintColor = UIColor(white: 1, alpha: 0.9)
                        timeLabel.textColor = UIColor(white: 1, alpha: 0.9)
                    }
                }
            } else {
                remainingTime = audioRecorder!.currentTime // count up
            }
            
            audioSiriWaveView.updateWithLevel(CGFloat(pow(10, audioRecorder!.averagePowerForChannel(0)/20)))
        }
        _updateTimeLabel(remainingTime + 0.15)
    }
    
    @objc private func didTapDoneButton(sender: UIButton) {
        self.doneRecordingDidPress(self, audioFilePath: curAudioPathStr!)
    }
    
    private func _updateTimeLabel(currentTime: NSTimeInterval) {
        let labelText = _formatTime(currentTime)
        timeLabel.text = labelText
    }
    
    private func _formatTime(time: NSTimeInterval) -> String {
        let second = (Int((time % 3600) % 60)).addLeadingZeroAsString()
        let minute = (Int((time % 3600) / 60)).addLeadingZeroAsString()
        let hour = (Int(time / 3600)).addLeadingZeroAsString()
        if hour == "00" {
            return "\(minute):\(second)"
        }
        return "\(hour):\(minute):\(second)"
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
        self.frostedView.addSubview(audioWaveContainerView)
        self.frostedView.addSubview(loadingActivityIndicator)
        
        // navbars, buttons
        _setupTopNavBar()
        _setupBottomNavBar()
    }
    
    // MARK: add audioSiriWaveView to its container view
    private func _loadAudioSiriWaveView() {
        waveFormView.removeFromSuperview()
        
        if !audioWaveContainerView.subviews.contains(audioSiriWaveView) {
            audioWaveContainerView.addSubview(audioSiriWaveView)
            
            audioSiriWaveView.snp_makeConstraints(closure: { (make) in
                make.left.right.top.bottom.equalTo(audioWaveContainerView)
            })
        }
    }
    
    private func _loadWaveFormView() {
        audioSiriWaveView.removeFromSuperview()
        
        if !audioWaveContainerView.subviews.contains(waveFormView) {
            audioWaveContainerView.addSubview(waveFormView)
            waveFormView.snp_makeConstraints(closure: { (make) in
                make.left.right.top.bottom.equalTo(audioWaveContainerView)
            })
        }
    }
    
    private func _setupTopNavBar() {
        
        self.frostedView.addSubview(topNavBar)
        topNavBar.snp_makeConstraints { (make) in
            make.width.equalTo(self.view.bounds.width)
            make.top.equalTo(self.view).offset(20)
            make.height.equalTo(navbarHeight)
            make.left.right.equalTo(self.view)
        }
        
        topNavBar.addSubview(cancelButton)
        cancelButton.snp_makeConstraints { (make) in
            make.top.equalTo(topNavBar).offset(5)
            make.left.equalTo(topNavBar).offset(5)
            make.width.equalTo(70)
            make.height.equalTo(30)
        }
        topNavBar.addSubview(doneButton)
        doneButton.snp_makeConstraints { (make) in
            make.top.equalTo(topNavBar).offset(5)
            make.right.equalTo(topNavBar).offset(5)
            make.width.equalTo(70)
            make.height.equalTo(30)
        }
        
        timeLabel.text = "00:00"
        timeLabel.textColor = UIColor(white: 1, alpha: 0.9)
        topNavBar.addSubview(timeLabel)
        timeLabel.snp_makeConstraints { (make) in
            make.center.equalTo(topNavBar)
            make.height.equalTo(30)
        }
        
        topNavBar.addSubview(clockIcon)
        clockIcon.tintColor = UIColor(white: 1, alpha: 0.9)
        clockIcon.snp_makeConstraints { (make) in
            make.left.equalTo(timeLabel.snp_right).offset(3)
            make.top.equalTo(timeLabel.snp_top)
            make.width.height.equalTo(30)
        }
    }
    
    private func _setupBottomNavBar() {
        self.frostedView.addSubview(bottomNavBar)
        bottomNavBar.snp_makeConstraints { (make) in
            make.width.equalTo(self.view.bounds.width)
            make.height.equalTo(navbarHeight)
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        bottomNavBar.addSubview(micButton) // TODO: toggle recording also toggles the record/pause icon here!
//        micButton.tintColor = UIColor.whiteColor()
//        micButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        micButton.snp_makeConstraints { (make) in
            make.center.equalTo(bottomNavBar)
            make.height.width.equalTo(35)
        }
        
        bottomNavBar.addSubview(stopButton)
        stopButton.snp_makeConstraints { (make) in
            make.top.equalTo(bottomNavBar).offset(5)
            make.left.equalTo(bottomNavBar).offset(5)
            make.width.height.equalTo(35)
        }
        
        bottomNavBar.addSubview(scissorButton)
        scissorButton.snp_makeConstraints { (make) in
            make.top.equalTo(bottomNavBar).offset(5)
            make.right.equalTo(bottomNavBar).offset(-10)
            make.width.height.equalTo(35)
        }
        
        bottomNavBar.addSubview(playButton)
        playButton.snp_makeConstraints { (make) in
            make.top.equalTo(bottomNavBar).offset(5)
            make.left.equalTo(bottomNavBar).offset(5)
            make.width.height.equalTo(35)
        }
        
        bottomNavBar.addSubview(undoTrimmingButton)
        undoTrimmingButton.snp_makeConstraints { (make) in
            make.top.equalTo(scissorButton.snp_top)
            make.right.equalTo(scissorButton.snp_left).offset(-5)
            make.width.height.equalTo(35)
        }
        
//        bottomNavBar.addSubview(pauseRecordingButton)
//        pauseRecordingButton.snp_makeConstraints { (make) in
//            make.center.equalTo(bottomNavBar)
//            make.height.width.equalTo(35)
//        }
    }
    
    private func updateUIForOperation(mode: SwiftySoundMode) {
        switch mode {
        case .Idling:
            undoTrimmingButton.hidden = true
            scissorButton.enabled = curAudioPathStr != nil
//            stopButton.hidden = curAudioPathStr != nil
//            stopButton.enabled = stopButton.hidden
            playButton.hidden = !stopButton.hidden // alternate playButton and stopButton (for recording)
            playButton.enabled = !playButton.hidden
            micButton.enabled = true
            doneButton.enabled = curAudioPathStr != nil
            clockIcon.tintColor = UIColor(white: 1, alpha: 0.9) // restore the original tint
            timeLabel.textColor = UIColor(white: 1, alpha: 0.9) // restore the original tint
        
        case .Recording:
            print("recording")
            _loadAudioSiriWaveView()
            undoTrimmingButton.hidden = true
            playButton.hidden = true
            stopButton.enabled = true
            scissorButton.enabled = false
            doneButton.enabled = false
//            cancelButton.enabled = false
        case .Playing:
            print("playing...")
            _loadAudioSiriWaveView()
            undoTrimmingButton.hidden = true
            playButton.hidden = false
            stopButton.hidden = true
            scissorButton.enabled = true
            micButton.enabled = false
        case .Cropping:
            print("Cropping....")
            _loadWaveFormView()
            undoTrimmingButton.hidden = false
            undoTrimmingButton.enabled = true
            scissorButton.enabled = true
//            playButton.enabled = false
            playButton.setBackgroundImage(playIcon, forState: .Normal) // restore the play icon
            stopButton.enabled = false
            micButton.enabled = false
            doneButton.enabled = false
        default:
            print("default operation mode here")
        }
    }
    
    private func trimAudio(audioFileURL: NSURL, startTime: CGFloat, endTime: CGFloat) {
        print("trimming audio now!")
        let audioAsset = AVAsset(URL: audioFileURL)
        let curAudioTrack = audioAsset.tracksWithMediaType(AVMediaTypeAudio).first
        
        if let exportSession = AVAssetExportSession(asset: audioAsset, presetName: AVAssetExportPresetAppleM4A) {
            
            let cmtDuration = CMTimeGetSeconds(audioAsset.duration)
            print("audio duration from CMT: \(cmtDuration)")
            let timeScale = curAudioTrack?.naturalTimeScale ?? 1
            print("time scale: \(timeScale)")
            let start = CMTimeMake(Int64(NSTimeInterval(startTime) * Double(timeScale)), timeScale)
            let end = CMTimeMake(Int64(NSTimeInterval(endTime) * Double(timeScale)), timeScale)
            let exportTimeRange = CMTimeRangeFromTimeToTime(start, end)
            
            // set up audio mix
            let exportAudioMix = AVMutableAudioMix()
            let exportAudioMixInputParams = AVMutableAudioMixInputParameters(track: curAudioTrack)
            exportAudioMix.inputParameters = NSArray(array: [exportAudioMixInputParams]) as! [AVAudioMixInputParameters]
            
//            let trimmedAudioName = Configuration.trimmedRecordingFileName
//            // NSProcessInfo.processInfo().globallyUniqueString
//            let trimmedAudioURL = docDirectoryPath.URLByAppendingPathComponent("\(trimmedAudioName).m4a")
//            
            if fileManager.fileExistsAtPath(trimmedAudioURL.path!) {
                print("fileManager removing the existing trimmed audio")
                try! fileManager.removeItemAtURL(trimmedAudioURL)
            }
            
            exportSession.outputURL = NSURL(fileURLWithPath: trimmedAudioURL.path!) //
            exportSession.outputFileType = AVFileTypeAppleM4A
            exportSession.timeRange = exportTimeRange
            exportSession.audioMix = exportAudioMix
            
            // execute the export of the trimmed audio
            exportSession.exportAsynchronouslyWithCompletionHandler({
                
                switch exportSession.status {
                case AVAssetExportSessionStatus.Completed:
                    
                    print("audio has been successfully trimed!")
                    self.curAudioPathStr = self.trimmedAudioURL.path!
                    self.waveFormView.audioURL = self.trimmedAudioURL
                    
                case AVAssetExportSessionStatus.Failed:
                    print("audio trimming failed!")
                    NSOperationQueue.mainQueue().addOperationWithBlock({
                        if exportSession.status == AVAssetExportSessionStatus.Completed {
                            let uniqueStr = NSProcessInfo.processInfo().globallyUniqueString
                            let newAudioUrl = self.docDirectoryPath.URLByAppendingPathComponent("\(String(uniqueStr)).m4a")
                            //                        self.audioUrl = NSURL(fileURLWithPath: newFilePath.path!)
                            try! self.fileManager.moveItemAtURL(exportSession.outputURL!, toURL: newAudioUrl)
                            self.curAudioPathStr = newAudioUrl.path
                            self.waveFormView.audioURL = newAudioUrl
                        }
                    })
                    
                case AVAssetExportSessionStatus.Cancelled:
                    print("trimmed was cancelled")
                    
                default:
                    print("trimming and export completed!")
                }
            })
        }
    }
    
    
    // MARK: buttons
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 10, width: 130, height: 30))
        button.setTitle("Cancel", forState: .Normal)
        
        button.tintColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.9) // self.view.tintColor
        button.setTitleColor(UIColor(red: 255, green: 0, blue: 0, alpha: 0.9), forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        
        button.addTarget(self, action: #selector(self.cancelRecordingDidPress(_:)), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(frame: CGRect(x: self.view.bounds.width-130, y: 10, width: 130, height: 30))
        button.setTitle("Done", forState: .Normal)
        button.enabled = false
        button.tintColor = UIColor(white: 1, alpha: 0.9)
        button.setTitleColor(UIColor(white: 1, alpha: 0.9), forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        button.addTarget(self, action: #selector(self.didTapDoneButton), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    private let playIcon = UIImage(named: "ic_play_arrow")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.hidden = true // hidden default
//        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
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
//        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.stopIcon, forState: .Normal)
        button.contentMode = .ScaleAspectFit
        button.tintColor = UIColor.redColor()
        button.enabled = false // default to be disabled
        button.addTarget(self, action: #selector(self.stopRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    // pauseButton and micButton alternate in the same position
    let pauseIcon = UIImage(named: "ic_pause")?.imageWithRenderingMode(.AlwaysTemplate)
    /*
    private lazy var pauseRecordingButton: UIButton = {
        let button = UIButton(type: .Custom)
        //        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.pauseIcon, forState: .Normal)
        button.tintColor = UIColor.redColor()
        button.hidden = true // default to be hidden
        button.contentMode = .ScaleAspectFit
        button.addTarget(self, action: #selector(self.toggleRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    */
    
    let micIcon = UIImage(named: "ic_mic")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var micButton: UIButton = {
        let button = UIButton(type: .Custom)
        //        button.frame = CGRect(x: 0, y: 5, width: 35, height: 35)
        button.setBackgroundImage(self.micIcon, forState: .Normal)
        //        button.setTitleColor(UIColor.redColor(), forState: .Highlighted)
//        button.tintColor = UIColor.redColor()
        
        button.tintColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.9) // self.view.tintColor
        button.setTitleColor(UIColor(red: 255, green: 0, blue: 0, alpha: 0.9), forState: .Normal)
        button.contentMode = .ScaleAspectFit
        button.addTarget(self, action: #selector(self.toggleRecording), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    let scissorIcon = UIImage(named: "ic_content_cut")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var scissorButton: UIButton = {
        let button = UIButton(type: .Custom)
//        button.frame = CGRect(x: self.view.bounds.width - 40, y: 5, width: 30, height: 30)
        button.tintColor = self.view.tintColor
        button.enabled = false
        button.setTitleColor(self.view.tintColor, forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        
        button.setBackgroundImage(self.scissorIcon, forState: .Normal)
        button.contentMode = .ScaleAspectFit
        button.addTarget(self, action: #selector(self.beginAudioCropMode), forControlEvents: .TouchUpInside) // TODO:
        
        return button
    }()
    
    let undoIcon = UIImage(named: "ic_undo")?.imageWithRenderingMode(.AlwaysTemplate)
    private lazy var undoTrimmingButton: UIButton = {
        let button = UIButton(type: .Custom)
        //        button.frame = CGRect(x: self.view.bounds.width - 40, y: 5, width: 30, height: 30)
        button.tintColor = self.view.tintColor
        button.enabled = false
        button.setTitleColor(self.view.tintColor, forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        button.hidden = true // TODO: work on this undo button in next release; hidden temporarily
        button.setBackgroundImage(self.undoIcon, forState: .Normal)
        button.contentMode = .ScaleAspectFit
//        button.addTarget(self, action: #selector(self.undoTrimming), forControlEvents: .TouchUpInside)
        return button
    }()
    
    public lazy var docDirectoryPath: NSURL = {
        let docPath = self.fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        
        return docPath
    }()
    
    private lazy var originalRecordedAudioURL: NSURL = {
        let fileUrl = self.docDirectoryPath.URLByAppendingPathComponent("\(Configuration.originalRecordingFileName)\(self.audioFileType)")
        
        return fileUrl
    }()
    
    private lazy var trimmedAudioURL: NSURL = {
        let fileUrl = self.docDirectoryPath.URLByAppendingPathComponent("\(Configuration.trimmedRecordingFileName)\(self.audioFileType)")
        
        return fileUrl
    }()
    
    private lazy var audioWaveContainerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 200)) // self.view.bounds.height - self.navBar.bounds.height - self.bottomToolbar.bounds.height
        view.clipsToBounds = true
        view.backgroundColor = UIColor.clearColor() // UIColor.whiteColor()
        view.center = self.view.center
        
        return view
    }()
    
    let clockIcon = UIImageView(image: UIImage(named: "ic_av_timer_2x")?.imageWithRenderingMode(.AlwaysTemplate))
    private lazy var timeLabel: UILabel = {
        let label = UILabel() // TODO:
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var loadingActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        indicator.color = UIColor.lightGrayColor()
        indicator.frame = self.audioWaveContainerView.bounds // CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 200)
        indicator.center = self.audioWaveContainerView.center
        indicator.autoresizingMask = [.FlexibleTopMargin, .FlexibleBottomMargin, .FlexibleLeftMargin, .FlexibleRightMargin]
        indicator.hidden = true
        
        return indicator
    }()
    
    private lazy var audioSiriWaveView: SCSiriWaveformView = {
        let flowView = SCSiriWaveformView(frame: self.audioWaveContainerView.bounds)
        flowView.translatesAutoresizingMaskIntoConstraints = false
        flowView.alpha = 1.0 // TODO: change it to 0.0
        flowView.backgroundColor = UIColor.clearColor()
        //        flowView.backgroundColor = UIColor.whiteColor() // TODO: change to UIColor.clearColor()
        flowView.center = self.audioWaveContainerView.center
        flowView.clipsToBounds = false
        flowView.primaryWaveLineWidth = 3.0
        flowView.secondaryWaveLineWidth = 1.0
        flowView.waveColor = Configuration.defaultBlueTintColor
        
        return flowView
    }()
    
    private lazy var waveFormView: FDWaveformView = {
        let formView = FDWaveformView()
        formView.backgroundColor = UIColor.grayColor()
        formView.frame = self.audioWaveContainerView.bounds
        formView.hidden = true
        //        formView.alpha = 0.5
        formView.center = self.audioWaveContainerView.center
        formView.wavesColor = UIColor.whiteColor() // self.waveTintColor
        formView.progressColor = self.waveHighlightedTintColor
        formView.doesAllowScroll = false
        formView.doesAllowScrubbing = false
        formView.doesAllowStretch = false
        formView.progressSamples = 10000 // what is this?
        //        formView.autoresizingMask = UIViewAutoRe
        // TODO: waveLoadiingIndicatorView
        formView.delegate = self
        
        return formView
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
    
    private lazy var topNavBar: UIView = {
        let bar = UIView()
        // UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.navbarHeight))
        bar.backgroundColor = UIColor.grayColor()
//        bar.alpha = 0.5
//        bar.layer.cornerRadius = 4
        bar.layer.borderWidth = 0.5
        bar.layer.borderColor = UIColor(white: 1, alpha: 0.8).CGColor
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        return bar
    }()
    
    private lazy var bottomNavBar: UIView = {
        let bottomBar = UIView()
        // UIView(frame: CGRect(x: 0, y: self.view.bounds.height - self.navbarHeight, width: self.topNavBar.bounds.width, height: self.navbarHeight))
        
        bottomBar.backgroundColor = UIColor.grayColor()
//        bottomBar.alpha = 0.5
        bottomBar.layer.borderWidth = 0.5
        bottomBar.layer.borderColor = UIColor(white: 1, alpha: 0.8).CGColor
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        
        return bottomBar
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
        
        audioRecorder = nil
        micButton.setBackgroundImage(micIcon, forState: .Normal)
        
        // The UI updates in .Idling state cannot update due to the lag of calling this delegate method! // TODO: find a solution for consistent use of the updateUI() method above
        // so that the UI does not
        stopButton.hidden = true
//        stopButton.enabled = false
        playButton.hidden = false // alternate playButton and stopButton (for recording)
        playButton.enabled = true
        
        self.operationMode = .Idling
    }
}

extension SwiftySoundRecorder: FDWaveformViewDelegate {
    public func waveformViewWillRender(waveformView: FDWaveformView!) {
        
        self.audioWaveContainerView.alpha = 0.0
        self.waveFormView.hidden = true
        
        leftCropper.frame = CGRectMake(0, 0, 30, audioWaveContainerView.bounds.height)
        leftCropper.cropTime = 0
        rightCropper.cropTime = CGFloat(self.audioDuration)
        
        rightCropper.frame = CGRect(x: audioWaveContainerView.bounds.width - 30, y: 0, width: 30, height: audioWaveContainerView.bounds.height)
        
        self.audioWaveContainerView.alpha = 0.0
        self.waveFormView.hidden = true
        self.loadingActivityIndicator.superview!.bringSubviewToFront(loadingActivityIndicator)
        
        self.loadingActivityIndicator.hidden = false
        self.loadingActivityIndicator.startAnimating()
    }
    
    public func waveformViewDidRender(waveformView: FDWaveformView!) {
        print("wave form did render, waveFormView.totalSamples: \(waveFormView.totalSamples)")
        
        self.leftCropper.hidden = false
        self.rightCropper.hidden = false
        UIView.animateWithDuration(2) {
            self.audioWaveContainerView.alpha = 1.0
            self.loadingActivityIndicator.stopAnimating()
            self.loadingActivityIndicator.hidden = true
//            self.loadingActivityIndicator.removeFromSuperview()
            self.waveFormView.hidden = false
        }
    }
    
    public func waveformDidBeginPanning(waveformView: FDWaveformView!) {
        print("wave form begin panning")
    }
    
    public func waveformDidEndPanning(waveformView: FDWaveformView!) {
        print("wave form ended panning")
    }
}




