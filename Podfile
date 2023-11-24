# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

source 'https://cdn.cocoapods.org/'

project 'edX.xcodeproj'

target 'edX' do
  pod 'Analytics', '= 4.1.8'
  pod 'BranchSDK', '= 2.0.0'
  pod 'DateTools', '= 2.0.0'
  pod 'FBSDKCoreKit', '= 16.0.0'
  pod 'FBSDKLoginKit', '= 16.0.0'
  pod 'Firebase', '= 10.5.0', :modular_headers => true
  pod 'FirebaseAnalytics', '= 10.5.0'
  pod 'FirebaseCore', '= 10.5.0', :modular_headers => true
  pod 'FirebaseCoreInternal', '= 10.5.0', :modular_headers => true
  pod 'FirebaseCrashlytics', '= 10.5.0'
  pod 'FirebaseInAppMessaging', '= 10.5.0-beta'
  pod 'FirebaseMessaging', '= 10.5.0'
  pod 'FirebasePerformance', '= 10.5.0'
  pod 'google-cast-sdk-no-bluetooth-xcframework', '~> 4.8.0'
  pod 'GoogleSignIn', '~> 7.0.0'
  pod 'GoogleUtilities', '= 7.11.0', :modular_headers => true
  pod 'Masonry', '= 1.1.0'
  pod 'MSAL', '= 1.2.5', :modular_headers => true
  pod 'NewRelicAgent', '= 7.4.2'
  pod 'Segment-Appboy', '= 4.6.0'
  pod 'Smartling.i18n', '~> 1.0.14'
  pod 'YoutubePlayer-in-WKWebView', '~> 0.3.8'
end

target 'edXTests' do
  use_frameworks!
  pod 'iOSSnapshotTestCase', '= 6.2.0'
  pod 'OHHTTPStubs', '~> 4.0', :modular_headers => true
  pod 'OCMock', '~> 3.9.3', :modular_headers => true
end

dynamic_frameworks = ['MSAL']

pre_install do |installer|
  installer.pod_targets.each do |pod|
    if dynamic_frameworks.include?(pod.name)
      def pod.build_type;
        Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
      end
    end
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end

