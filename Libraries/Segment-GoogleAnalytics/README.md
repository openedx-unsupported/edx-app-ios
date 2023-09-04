# Analytics

[![CircleCI](https://circleci.com/gh/segment-integrations/analytics-ios-integration-google-analytics.svg?style=svg)](https://circleci.com/gh/segment-integrations/analytics-ios-integration-google-analytics)
[![Version](https://img.shields.io/cocoapods/v/Segment-google-analytics.svg?style=flat)](http://cocoapods.org/pods/Segment-googleanalytics)
[![License](https://img.shields.io/cocoapods/l/Segment-google-analytics.svg?style=flat)](http://cocoapods.org/pods/Segment-googleanalytics)

**WARNING**: This SDK has been deprecated. On September 17th, 2019 this repository will be archived as read-only and no longer actively maintained. [Google is sunsetting their Google Analytics mobile SDKs on October 31st.](https://support.google.com/firebase/answer/9167112?hl=en). Please [see our migration tutorial](https://segment.com/docs/destinations/google-analytics/#migrating-deprecated-google-analytics-mobile-sdks-to-firebase) to learn more about migrating to our Firebase SDKs for iOS. 

Google Analytics integration for analytics-ios.

## Installation

To install the Segment-Google Analytics integration, simply add this line to your [CocoaPods](http://cocoapods.org) `Podfile`:

```ruby
pod "Segment-GoogleAnalytics"
```

## Usage

After adding the dependency, you must register the integration with our SDK.  To do this, import the Google Analytics integration in your `AppDelegate`:

```
#import <Segment-GoogleAnalytics/SEGGoogleAnalyticsIntegrationFactory.h>
```

And add the following lines:

```
NSString *const SEGMENT_WRITE_KEY = @" ... ";
SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];

[config use:[SEGGoogleAnalyticsIntegrationFactory instance]];

[SEGAnalytics setupWithConfiguration:config];

```


## License

```
WWWWWW||WWWWWW
 W W W||W W W
      ||
    ( OO )__________
     /  |           \
    /o o|    MIT     \
    \___/||_||__||_|| *
         || ||  || ||
        _||_|| _||_||
       (__|__|(__|__|

The MIT License (MIT)

Copyright (c) 2014 Segment, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
