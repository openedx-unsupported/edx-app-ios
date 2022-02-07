# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

source 'https://github.com/CocoaPods/Specs.git'

project 'edX.xcodeproj'

target 'edX' do
  pod 'Analytics', '= 4.1.6'
  pod 'Segment-GoogleAnalytics', '= 1.3.3'
  pod 'DateTools', '= 2.0.0'
  pod 'GoogleSignIn', '~> 6.1.0'
  pod 'Masonry', '= 1.1.0'
  pod 'NewRelicAgent', '= 7.3.3'
  pod 'FBSDKCoreKit', '=  12.0.0'
  pod 'FBSDKLoginKit', '= 12.0.0'
  pod 'Smartling.i18n', '~> 1.0.14'
  pod 'Firebase','= 8.10.0'
  pod 'FirebaseCrashlytics', '=8.10.0'
  pod 'FirebaseCore','= 8.10.0'
  pod 'FirebaseInAppMessaging', '= 8.8.0-beta'
  pod 'FirebaseAnalytics', '= 8.10.0'
  pod 'FirebasePerformance', '= 8.10.0'
  pod 'FirebaseMessaging', '= 8.10.0'
  pod 'Branch', '= 1.40.0'
  pod 'YoutubePlayer-in-WKWebView', '~> 0.3.8'
  pod 'Segment-Appboy', '=4.3.0'
  
end

target 'edXTests' do
  use_frameworks!
  pod 'iOSSnapshotTestCase', '= 6.2.0'
  pod 'OHHTTPStubs', '~> 4.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end

