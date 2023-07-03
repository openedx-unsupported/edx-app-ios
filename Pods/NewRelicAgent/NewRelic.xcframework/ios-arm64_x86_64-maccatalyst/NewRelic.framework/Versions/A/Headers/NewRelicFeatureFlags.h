//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-monitoring for information
//    https://docs.newrelic.com/docs/release-notes/mobile-release-notes/xcframework-release-notes/ for release notes
//
//  Copyright © 2023 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//

#import <Foundation/Foundation.h>

/*!
 NRMAFeatureFlags
 
 These flags are used to identify New Relic features.

- NRFeatureFlag_InteractionTracing
   Enable (default) or disable interaction tracing.

- NRFeatureFlag_SwiftInteractionTracing
   Disabled by default. Beware: enabling this feature may cause your swift application to crash.
   please read https://docs.newrelic.com/docs/mobile-monitoring/new-relic-mobile/getting-started/enabling-interaction-tracing-swift
   before enabling this feature.

- NRFeatureFlag_CrashReporting 
   Enabled by default. Enable or disable New Relic's crash reporter.

- NRHandledExceptionEvents
   Enabled by default. Controls capture of handled exceptions via 'recordHandledException:' API.

- NRFeatureFlag_NSURLSessionInstrumentation
   Enable (default) flag for instrumentation of NSURLSessions.
   Currently only instruments network activity dispatched with
   NSURLSessionDataTasks and NSURLSessionUploadTasks.

- NRFeatureFlag_HttpResponseBodyCapture
   Enable (default) or disable HTTP response body capture for HTTP errors.
   New Relic only captures the response bodies of HTTP errors.

- NRFeatureFlag_WebViewInstrumentation
   Enable (default) or disable automatic instrumentation of WKWebView.

- NRFeatureFlag_DefaultInteractions
   Enabled by default. This flag is used to only disable the default Interactions
   New Relic will trace. Default interactions are started when a view controller is displayed
   and are titled "Displayed <ViewControllerName>". This flag is associated with
   NRFeatureFlag_InteractionTracing, but acts as a subset of functionality on that feature.

- NRFeatureFlag_ExperimentalNetworkingInstrumentation
   Disabled by default. Enables experimental networking instrumentation. This
   feature may decrease the stability of applications.
 
 - NRFeatureFlag_DistributedTracing
    Enabled by default. Enables distributed tracing support for network
    requests.

 - NRFeatureFlag_GestureInstrumentation
    Disabled by default.

 - NRFeatureFlag_AppStartMetrics
    Enable (default)or disable flag for automatic calculation of app start metrics. Cold and Hot(Resume) start times only.
    Note: App Launch start are not reported when using Simulators or during debugging.
*/



typedef NS_OPTIONS(unsigned long long, NRMAFeatureFlags){
    NRFeatureFlag_InteractionTracing                    = 1 << 1,
    NRFeatureFlag_SwiftInteractionTracing               = 1 << 2, // Disabled by default
    NRFeatureFlag_CrashReporting                        = 1 << 3,
    NRFeatureFlag_NSURLSessionInstrumentation           = 1 << 4,
    NRFeatureFlag_HttpResponseBodyCapture               = 1 << 5,
    NRFeatureFlag_WebViewInstrumentation                = 1 << 7,
    NRFeatureFlag_RequestErrorEvents                    = 1 << 8,
    NRFeatureFlag_NetworkRequestEvents                  = 1 << 9,
    NRFeatureFlag_HandledExceptionEvents                = 1 << 10,
    NRFeatureFlag_DefaultInteractions                   = 1 << 12,
    NRFeatureFlag_ExperimentalNetworkingInstrumentation = 1 << 13, // Disabled by default
    NRFeatureFlag_DistributedTracing                    = 1 << 14,
    NRFeatureFlag_GestureInstrumentation                = 1 << 15, // Disabled by default
    NRFeatureFlag_AppStartMetrics                       = 1 << 16,
};
