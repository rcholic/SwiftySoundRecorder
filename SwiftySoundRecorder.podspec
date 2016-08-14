Pod::Spec.new do |s|
  s.name             = 'SwiftySoundRecorder'
  s.version          = '0.0.1'
  s.summary          = 'A Swift ySound Recorder with Sound Wave Views.'
  s.homepage         = 'https://github.com/rcholic/SwiftySoundRecorder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rcholic' => 'ivytony@gmail.com' }
  s.source           = { :git => 'https://github.com/rcholic/SwiftySoundRecorder.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'Source/**/*'

  s.ios.deployment_target = '8.0'

  
   s.resource_bundles = {
     'SwiftySoundRecorder' => ['Images/*.{png}']
   }

#  s.source_files = 'SwiftySoundRecorder/Classes/**/*'
  
#  s.resource_bundles = {
#     'SwiftySoundRecorder' => ['SwiftySoundRecorder/Assets/*.png']
#  }

  s.frameworks = 'UIKit', 'AVFoundation'
  s.dependency 'SnapKit', '~> 0.22.0'
  s.dependency 'SCSiriWaveformView', '~> 1.0.3'
  s.dependency 'FDWaveformView', '~> 1.0.1'
#  s.dependency  'FDWaveformView', :git => 'https://github.com/hackiftekhar/FDWaveformView.git', :commit => '65369f6729bec964db984b7f7439a915342237de'
end
