# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

source 'https://github.com/CocoaPods/Specs.git'

project 'edX.xcodeproj'

target 'edX' do
pod 'Analytics', '= 4.1.4'
pod 'Segment-GoogleAnalytics', '= 1.3.3'
pod 'DateTools', '= 2.0.0'
pod 'GoogleSignIn', '~> 5.0.2'
pod 'Masonry', '= 1.1.0'
pod 'NewRelicAgent', '= 7.3.1'
pod 'FBSDKCoreKit', '=  9.3.0'
pod 'FBSDKLoginKit', '= 9.3.0'
pod 'Smartling.i18n', '~> 1.0'
pod 'Firebase/Crashlytics', '=8.0.0'
pod 'Firebase/Core','= 8.0.0'
pod 'Firebase/InAppMessaging', '= 8.0.0'
pod 'Firebase/Analytics', '= 8.0.0'
pod 'Firebase/Performance', '= 8.0.0'
pod 'Firebase/Messaging', '= 8.0.0'
pod 'Branch', '= 1.39.3'
pod 'YoutubePlayer-in-WKWebView', '~> 0.3.8'
pod 'Segment-Appboy', '=4.1.0'

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
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end

