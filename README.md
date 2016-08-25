# SwiftySoundRecorder

[![CI Status](http://img.shields.io/travis/rcholic/SwiftySoundRecorder.svg?style=flat)](https://travis-ci.org/rcholic/SwiftySoundRecorder)
[![Version](https://img.shields.io/cocoapods/v/SwiftySoundRecorder.svg?style=flat)](http://cocoapods.org/pods/SwiftySoundRecorder)
[![License](https://img.shields.io/cocoapods/l/SwiftySoundRecorder.svg?style=flat)](http://cocoapods.org/pods/SwiftySoundRecorder)
[![Platform](https://img.shields.io/cocoapods/p/SwiftySoundRecorder.svg?style=flat)](http://cocoapods.org/pods/SwiftySoundRecorder)

## Screenshots
![Light Color Theme]
(https://s3.postimg.org/j9nktqoyb/Screen_Shot_2016_08_20_at_11_57_53_PM.png)
![Dark Color Theme]
(https://s9.postimg.org/osiodktdb/Screen_Shot_2016_08_20_at_11_58_36_PM.png)
![Trimming Audio Clip]
(https://s13.postimg.org/6l0g3rop3/Screen_Shot_2016_08_20_at_11_58_57_PM.png)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

SwiftySoundRecorder is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftySoundRecorder"
```

## Usage Example
To use the recorder, you need to:
1. Create an instance of `SwiftySoundRecorder`: 
```
let recorder = SwiftySoundRecorder()
```
2. Options of the recorder:
- Allow cropping: `recorder.allowCropping = true // or false to disallow`
- Set maximum length of duration (in seconds): `recorder.maxDuration = 10 // 10 seconds`; If not set, the recorder will run forever until user stops it
- Use the theme colors (.Dark and .Light): `recorder.themeType = .Dark` // 

3. Implement the delegate methods:
- doneRecordingDidPress(soundRecorder: SwiftySoundRecorder, audioFilePath: String)
- cancelRecordingDidPress(soundRecorder: SwiftySoundRecorder)

## Author

rcholic, ivytony@gmail.com

## License

SwiftySoundRecorder is available under the MIT license. See the LICENSE file for more info.
