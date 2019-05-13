# Segment-Firebase

[![CircleCI](https://circleci.com/gh/segment-integrations/analytics-ios-integration-firebase.svg?style=svg)](https://circleci.com/gh/segment-integrations/analytics-ios-integration-firebase)
[![Version](https://img.shields.io/cocoapods/v/Segment-Firebase.svg?style=flat)](http://cocoapods.org/pods/Segment-Firebase)
[![License](https://img.shields.io/cocoapods/l/Segment-Firebase.svg?style=flat)](http://cocoapods.org/pods/Segment-Firebase)
[![Platform](https://img.shields.io/cocoapods/p/Segment-Firebase.svg?style=flat)](https://cocoapods.org/pods/Segment-Firebase)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Segment-Firebase is currently only available through [CocoaPods](http://cocoapods.org).

Register your app in the [Firebase console](https://console.firebase.google.com/) and add the `GoogleService-Info.plist` to the root of your Xcode project.

Add the following dependency to your Podfile:

 ```
 pod 'Segment-Firebase'
 ```

After adding the dependency and running `pod install`, import the integration:

```
#import <Segment-Firebase/SEGFirebaseIntegrationFactory.h>
```

Finally, register the dependency with the Segment SDK:

```
[config use:[SEGFirebaseIntegrationFactory instance]];
```

By default, Segment only bundles `Firebase/Core` which is [Firebase's Analytics offering](https://firebase.google.com/docs/analytics/). You can see the other available [Firebase pods and features here](https://firebase.google.com/docs/ios/setup).

## License

Segment-Firebase is available under the MIT license. See the LICENSE file for more info.
