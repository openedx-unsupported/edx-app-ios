# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

project 'edX.xcodeproj'

target 'edX' do
pod 'Analytics', '~> 3.0.0'
pod 'Segment-GoogleAnalytics', '~> 1.0.0'
pod 'Crashlytics', '~> 3.2'
pod 'DateTools', '~> 1.6.1'
pod 'Fabric', '~> 1.5'
pod 'GoogleSignIn', '~> 2.4'
pod 'Masonry', '~> 0.6'
pod 'NewRelicAgent', '~> 4.1'
pod 'FBSDKCoreKit', '~> 4.31.1'
pod 'FBSDKLoginKit', '~> 4.31.1'
pod 'Parse', '~> 1.7'
pod 'Smartling.i18n', '~> 1.0'
pod 'Firebase/Core', '= 3.11.0'
pod 'Branch’, '= 0.17.9'
end

target 'edXTests' do
    pod 'FBSnapshotTestCase/Core', '= 2.0.1'
    pod 'OCMock', '~> 3.1'
    pod 'OHHTTPStubs', '~> 4.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
        end
    end
end 

