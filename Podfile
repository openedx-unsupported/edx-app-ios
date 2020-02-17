# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

source 'https://github.com/CocoaPods/Specs.git'

project 'edX.xcodeproj'

target 'edX' do
pod 'Analytics', '~> 3.7.0'
pod 'Segment-GoogleAnalytics', '~> 1.2.0'
pod 'Segment-Firebase', '=2.5.0'
pod 'Crashlytics', '~> 3.14.0'
pod 'DateTools', '~> 2.0.0'
pod 'Fabric', '~> 1.10.2'
pod 'GoogleSignIn', '~> 4.4.0'
pod 'Masonry', '~> 1.1.0'
pod 'NewRelicAgent', '~> 6.7.0'
pod 'FBSDKCoreKit', '= 5.5.0'
pod 'FBSDKLoginKit', '= 5.5.0'
pod 'Smartling.i18n', '~> 1.0'
pod 'Firebase/Core', '= 6.8.1'
pod 'Firebase/InAppMessagingDisplay', '= 6.8.1'
pod 'Firebase/Analytics', '= 6.8.1'
pod 'Firebase/Performance', '= 6.8.1'
pod 'Firebase/Messaging', '= 6.8.1'
pod 'Branch', '= 0.28.1'
pod 'YoutubePlayer-in-WKWebView', '~> 0.3.0'
pod 'MSAL'
end

target 'edXTests' do
    use_frameworks!
    pod 'iOSSnapshotTestCase', '= 6.1.0'
    pod 'OHHTTPStubs', '~> 8.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        for i in 0..target.headers_build_phase.files.length - 1
            build_file = target.headers_build_phase.files[i]
            build_file.settings = { 'ATTRIBUTES' => ['Public']}
        end
        target.build_configurations.each do |config|
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
        end
    end
end

