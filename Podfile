# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

project 'edX.xcodeproj'

target 'edX' do
pod 'Analytics', '~> 3.6.10'
pod 'Segment-GoogleAnalytics', '~> 1.2.0'
pod 'Segment-Firebase', '=2.4.0'
pod 'Crashlytics', '~> 3.10.1'
pod 'DateTools', '~> 1.6.1'
pod 'Fabric', '~> 1.7.6'
pod 'GoogleSignIn', '~> 4.4.0'
pod 'Masonry', '~> 0.6'
pod 'NewRelicAgent', '~> 4.1'
pod 'FBSDKCoreKit', '~> 4.42.0'
pod 'FBSDKLoginKit', '~> 4.42.0'
pod 'Smartling.i18n', '~> 1.0'
pod 'Firebase/Core', '= 5.20.2'
pod 'Firebase/InAppMessagingDisplay'
pod 'Firebase/Analytics'
pod 'Firebase/Performance'
pod 'Branch', '= 0.25.5'
end

target 'edXTests' do
    use_frameworks!
    pod 'iOSSnapshotTestCase', '= 5.0.2'
    pod 'OHHTTPStubs', '~> 4.0'
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

