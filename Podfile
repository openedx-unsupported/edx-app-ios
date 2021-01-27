# Uncomment this line to define a global platform for your project
platform :ios, '12.0'

source 'https://github.com/CocoaPods/Specs.git'

project 'edX.xcodeproj'

target 'edX' do
pod 'Analytics', '= 4.1.2'
pod 'Segment-GoogleAnalytics', '= 1.3.2'
pod 'DateTools', '= 2.0.0'
pod 'GoogleSignIn', '~> 5.0.2'
pod 'Masonry'
pod 'NewRelicAgent', '= 7.2.1'
pod 'FBSDKCoreKit', '= 9.0.0'
pod 'FBSDKLoginKit', '= 9.0.0'
pod 'Smartling.i18n', '~> 1.0'
pod 'Firebase/Crashlytics', '=7.4.0'
pod 'Firebase/Core','= 7.4.0'
pod 'Firebase/InAppMessaging', '= 7.4.0'
pod 'Firebase/Analytics', '= 7.4.0'
pod 'Firebase/Performance', '= 7.4.0'
pod 'Firebase/Messaging', '= 7.4.0'
pod 'Branch', '= 0.37.0'
pod 'YoutubePlayer-in-WKWebView', '~> 0.3.5'

end

target 'edXTests' do
    use_frameworks!
    pod 'iOSSnapshotTestCase', '= 6.2.0'
    pod 'OHHTTPStubs', '~> 4.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
#      puts "#{target.name}"
#        for i in 0..target.headers_build_phase.files.length - 1
#            build_file = target.headers_build_phase.files[i]
#            build_file.settings = { 'ATTRIBUTES' => ['Public']}
#        end
        target.build_configurations.each do |config|
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end

