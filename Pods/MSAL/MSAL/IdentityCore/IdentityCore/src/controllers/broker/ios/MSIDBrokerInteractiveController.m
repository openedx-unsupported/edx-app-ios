// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDBrokerInteractiveController.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDBrokerTokenRequest.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDBrokerTokenRequest.h"
#import "MSIDNotifications.h"
#import "MSIDBrokerResponseHandler.h"
#import "MSIDAppExtensionUtil.h"
#import "MSIDKeychainTokenCache.h"
#import "MSIDTelemetryBrokerEvent.h"
#import "MSIDTokenResult.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDAccount.h"
#import "MSIDNotifications.h"
#import "MSIDConstants.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAuthority.h"
#import "MSIDBrokerInvocationOptions.h"
#import "MSIDBrokerKeyProvider.h"
#import "MSIDMainThreadUtil.h"
#import "NSString+MSIDExtensions.h"

static MSIDBrokerInteractiveController *s_currentExecutingController;

@interface MSIDBrokerInteractiveController()

@property (nonatomic, readwrite) MSIDInteractiveTokenRequestParameters *interactiveParameters;
@property (nonatomic, readwrite) MSIDBrokerKeyProvider *brokerKeyProvider;
@property (nonatomic, readonly) NSURL *brokerInstallLink;
@property (atomic, copy) MSIDRequestCompletionBlock requestCompletionBlock;

@end

@implementation MSIDBrokerInteractiveController

#pragma mark - Init

- (nullable instancetype)initWithInteractiveRequestParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                         tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                           fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                                        error:(NSError * _Nullable * _Nullable)error
{
    self = [super initWithRequestParameters:parameters
                       tokenRequestProvider:tokenRequestProvider
                         fallbackController:fallbackController
                                      error:error];

    if (self)
    {
        _interactiveParameters = parameters;
        NSString *accessGroup = parameters.keychainAccessGroup ?: MSIDKeychainTokenCache.defaultKeychainGroup;
        _brokerKeyProvider = [[MSIDBrokerKeyProvider alloc] initWithGroup:accessGroup];
    }

    return self;
}

- (nullable instancetype)initWithInteractiveRequestParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                         tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                            brokerInstallLink:(nonnull NSURL *)brokerInstallLink
                                                        error:(NSError * _Nullable * _Nullable)error
{
    self = [self initWithInteractiveRequestParameters:parameters
                                 tokenRequestProvider:tokenRequestProvider
                                   fallbackController:nil
                                                error:error];

    if (self)
    {
        _brokerInstallLink = brokerInstallLink;
    }

    return self;
}

#pragma mark - MSIDRequestControlling

- (void)acquireToken:(MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Beginning broker flow.");
    
    if (!completionBlock)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"Passed nil completionBlock. End broker flow.");
        return;
    }
    
    NSString *upn = self.interactiveParameters.accountIdentifier.displayableId ?: self.interactiveParameters.loginHint;
    
    [self.interactiveParameters.authority resolveAndValidate:self.interactiveParameters.validateAuthority
                                           userPrincipalName:upn
                                                     context:self.interactiveParameters
                                             completionBlock:^(__unused NSURL *openIdConfigurationEndpoint,
                                                               __unused BOOL validated, NSError *error)
     {
         if (error)
         {
             completionBlock(nil, error);
             return;
         }
         
         [self acquireTokenImpl:completionBlock];
     }];
}

+ (BOOL)canPerformRequest:(MSIDInteractiveTokenRequestParameters *)requestParameters
{
#if AD_BROKER
#pragma unused(requestParameters)
    return YES;
#elif TARGET_OS_IPHONE
    
    if (![NSThread isMainThread])
    {
        __block BOOL brokerInstalled = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            brokerInstalled = [self canPerformRequest:requestParameters];
        });
        
        return brokerInstalled;
    }
    
    if ([MSIDAppExtensionUtil isExecutingInAppExtension]) return NO;
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Checking broker install state for version %@", requestParameters.brokerInvocationOptions.versionDisplayableName);
    
    if (requestParameters.brokerInvocationOptions && requestParameters.brokerInvocationOptions.isRequiredBrokerPresent)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Broker version %@ found installed on device", requestParameters.brokerInvocationOptions.versionDisplayableName);
        return YES;
    }
    
    return NO;
#else
    return NO;
#endif
}

- (void)acquireTokenImpl:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    MSIDRequestCompletionBlock completionBlockWrapper = ^(MSIDTokenResult *result, NSError *error)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Broker flow finished.");
        completionBlock(result, error);
    };

    if ([self.class currentBrokerController])
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractiveSessionAlreadyRunning, @"Broker authentication already in progress", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
        completionBlockWrapper(nil, error);
        return;
    }

    CONDITIONAL_START_EVENT(CONDITIONAL_SHARED_INSTANCE, self.requestParameters.telemetryRequestId, MSID_TELEMETRY_EVENT_API_EVENT);

    self.requestCompletionBlock = completionBlockWrapper;
    
    NSError *brokerError;
    NSString *base64UrlKey = [self.brokerKeyProvider base64BrokerKeyWithContext:self.requestParameters
                                                                          error:&brokerError];
    
    if (!base64UrlKey)
    {
        CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], brokerError);
        completionBlockWrapper(nil, brokerError);
        return;
    }
    
    NSError *appTokenError = nil;
    NSString *applicationToken = [self.brokerKeyProvider getApplicationToken:self.interactiveParameters.clientId error:&appTokenError];
    
    if (!applicationToken)
    {
        /*There can be a case for the initial call to not have an application token saved in the keychain. This is not considered an error condition.
         appTokenError will be filled only if the item exists but there is an internal keychain error while trying to look it up.
         */
        if (appTokenError)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to read broker application token, error: %@", appTokenError);
        }
    }
    
    MSIDBrokerTokenRequest *brokerRequest = [self.tokenRequestProvider brokerTokenRequestWithParameters:self.interactiveParameters
                                                                                              brokerKey:base64UrlKey
                                                                                 brokerApplicationToken:applicationToken
                                                                                        sdkCapabilities:self.sdkBrokerCapabilities
                                                                                                  error:&brokerError];

    if (!brokerRequest)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"Couldn't create broker request");
        CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], brokerError);
        completionBlockWrapper(nil, brokerError);
        return;
    }
    
    NSDictionary *brokerResumeDictionary = brokerRequest.resumeDictionary;
    [[NSUserDefaults standardUserDefaults] setObject:brokerResumeDictionary forKey:MSID_BROKER_RESUME_DICTIONARY_KEY];

    [self callBrokerWithRequest:brokerRequest];
}

- (void)callBrokerWithRequest:(MSIDBrokerTokenRequest *)brokerRequest
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Invoking broker for authentication, correlationId %@", brokerRequest.requestParameters.correlationId.UUIDString);
    
    [self.class setCurrentBrokerController:self];
    [self.class startTrackingAppState];
    CONDITIONAL_START_EVENT(CONDITIONAL_SHARED_INSTANCE, self.requestParameters.telemetryRequestId, MSID_TELEMETRY_EVENT_LAUNCH_BROKER);

    NSURL *brokerRequestURL = brokerRequest.brokerRequestURL;

    NSURL *launchURL = _brokerInstallLink ? _brokerInstallLink : brokerRequestURL;
    BOOL firstTimeInstall = _brokerInstallLink != nil;

    if (firstTimeInstall)
    {
        [self saveToPasteBoard:brokerRequestURL];
    }

    [MSIDMainThreadUtil executeOnMainThreadIfNeeded:^{
        [MSIDNotifications notifyWebAuthWillSwitchToBroker];
        [self openBrokerWithRequestURL:launchURL fallbackToLocalController:!firstTimeInstall];
    }];
}

- (void)openBrokerWithRequestURL:(NSURL *)requestURL
       fallbackToLocalController:(BOOL)shouldFallbackToLocalController
{
    NSDictionary *options = nil;
    
    if (self.interactiveParameters.brokerInvocationOptions.isUniversalLink)
    {
        // Option for openURL:options:CompletionHandler: only open URL if it is a valid universal link with an application configured to open it
        // If there is no application configured, or the user disabled using it to open the link, completion handler called with NO
        if (@available(iOS 10.0, *))
        {
            options = @{UIApplicationOpenURLOptionUniversalLinksOnly : @YES};
        }
    }
    
    [MSIDAppExtensionUtil sharedApplicationOpenURL:requestURL
                                           options:options
                                 completionHandler:^(BOOL success) {
        
                                     if (!success)
                                     {
                                         MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Failed to open broker URL. Falling back to local controller");
                                         
                                         [self handleFailedOpenURL:shouldFallbackToLocalController];
                                     }
    }];
}

- (void)saveToPasteBoard:(NSURL *)url
{
    UIPasteboard *appPasteBoard = [UIPasteboard pasteboardWithName:@"WPJ"
                                                            create:YES];
    NSURL *pasteBoardURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&%@=%@", url.absoluteString, @"sourceApplication", [[NSBundle mainBundle] bundleIdentifier]]];
    [appPasteBoard setURL:pasteBoardURL];
}

+ (BOOL)completeAcquireToken:(nullable NSURL *)resultURL
           sourceApplication:(nullable NSString *)sourceApplication
       brokerResponseHandler:(nonnull MSIDBrokerResponseHandler *)responseHandler
{
    // sourceApplication could be nil or empty, we want to return early if we know for sure response is not from broker
    if (![NSString msidIsStringNilOrBlank:sourceApplication] && ![self isResponseFromBroker:sourceApplication])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Asked to handle non broker response. Skipping request.");
        return NO;
    }
    
    BOOL hasCompletionBlock = [[self.class currentBrokerController] hasCompletionBlock];
    if (![responseHandler canHandleBrokerResponse:resultURL hasCompletionBlock:hasCompletionBlock])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"This broker response cannot be handled. Skipping request.");
        return NO;
    }

    NSError *resultError = nil;
    MSIDTokenResult *result = [responseHandler handleBrokerResponseWithURL:resultURL sourceApplication:sourceApplication error:&resultError];

    [MSIDNotifications notifyWebAuthDidReceiveResponseFromBroker:result];

    BOOL completionResult = result != nil;

    if ([self.class currentBrokerController])
    {
        MSIDBrokerInteractiveController *currentBrokerController = [self.class currentBrokerController];
        completionResult = [currentBrokerController completeAcquireTokenWithResult:result error:resultError];
    }

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MSID_BROKER_RESUME_DICTIONARY_KEY];

    return completionResult;
}

+ (BOOL)isResponseFromBroker:(__unused NSString *)sourceApplication
{
#if AD_BROKER
#pragma unused(sourceApplication)
    return YES;
#else
    BOOL isBrokerResponse = [MSID_BROKER_APP_BUNDLE_ID isEqualToString:sourceApplication]
                            || [MSID_BROKER_APP_BUNDLE_ID_DF isEqualToString:sourceApplication];

    return isBrokerResponse;
#endif
}

#pragma mark - Notifications

+ (void)startTrackingAppState
{
    // If the broker app itself requested a token, we don't care if it goes to background or not - the
    // user should be able to continue the flow regardless
#if !AD_BROKER
    // UIApplicationDidBecomeActive can get hit after the iOS 9 "This app wants to open this other app"
    // dialog is displayed. Because of the multitude of ways that notification can be sent we can't rely
    // merely on it to be able to accurately decide when we need to clean up. According to Apple's
    // documentation on the app lifecycle when receiving a URL we should be able to rely on openURL:
    // occuring between ApplicationWillEnterForeground and ApplicationDidBecomeActive.

    // https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW8
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
#endif
}

#if !AD_BROKER

+ (void)appEnteredForeground:(__unused NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];

    // Now that we know we've just been woken up from having been in the background we can start listening for
    // ApplicationDidBecomeActive without having to worry about something else causing it to get hit between
    // now and openURL:, if we're indeed getting a URL.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkTokenResponse:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

+ (void)checkTokenResponse:(__unused NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];

    if ([self.class currentBrokerController])
    {
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorBrokerResponseNotReceived, @"application did not receive response from broker.", nil, nil, nil, nil, nil, YES);

        MSIDBrokerInteractiveController *brokerController = [self.class currentBrokerController];
        [brokerController completeAcquireTokenWithResult:nil error:error];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MSID_BROKER_RESUME_DICTIONARY_KEY];
    }
}

#endif

+ (void)stopTrackingAppState
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

#pragma mark - Complete request

- (BOOL)completeAcquireTokenWithResult:(MSIDTokenResult *)tokenResult error:(NSError *)error
{
    // TODO: vt handling for older broker (not necessary for MSAL, so can come later)

    [self.class stopTrackingAppState];

#if !EXCLUDE_FROM_MSALCPP
    MSIDTelemetryBrokerEvent *brokerEvent = [[MSIDTelemetryBrokerEvent alloc] initWithName:MSID_TELEMETRY_EVENT_LAUNCH_BROKER requestId:self.requestParameters.telemetryRequestId correlationId:self.requestParameters.correlationId];

    if (error)
    {
        [brokerEvent setResultStatus:MSID_TELEMETRY_VALUE_FAILED];
        [brokerEvent setBrokerAppVersion:error.userInfo[MSIDBrokerVersionKey]];
        CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], error);
    }
    else
    {
        [brokerEvent setResultStatus:MSID_TELEMETRY_VALUE_SUCCEEDED];
    
        if (tokenResult.brokerAppVersion)
        {
            [brokerEvent setBrokerAppVersion:tokenResult.brokerAppVersion];
        }

        MSIDTelemetryAPIEvent *telemetryEvent = [self telemetryAPIEvent];
        [telemetryEvent setUserInformation:tokenResult.account];
        [self stopTelemetryEvent:telemetryEvent error:nil];
    }

    CONDITIONAL_STOP_EVENT(CONDITIONAL_SHARED_INSTANCE, self.requestParameters.telemetryRequestId, brokerEvent);
#endif

    if (self.requestCompletionBlock)
    {
        MSIDRequestCompletionBlock requestCompletion = [self copyAndClearCompletionBlock];
        requestCompletion(tokenResult, error);
        [self.class setCurrentBrokerController:nil];
        return YES;
    }

    [self.class setCurrentBrokerController:nil];
    return NO;
}

- (MSIDRequestCompletionBlock)copyAndClearCompletionBlock
{
    @synchronized (self) {
        MSIDRequestCompletionBlock completionBlock = [self.requestCompletionBlock copy];
        self.requestCompletionBlock = nil;
        return completionBlock;
    }
}

- (BOOL)hasCompletionBlock
{
    BOOL result = NO;
    @synchronized(self)
    {
        result = self.requestCompletionBlock != nil;
    }
    
    return result;
}

#pragma mark - Fallback

- (void)handleFailedOpenURL:(BOOL)shouldFallbackToLocalController
{
#if TARGET_OS_SIMULATOR
    if (!shouldFallbackToLocalController)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Ignoring URL open failure because of simulator target");
        return;
    }
#endif
    
    [self.class stopTrackingAppState];

#if !EXCLUDE_FROM_MSALCPP
    MSIDTelemetryBrokerEvent *brokerEvent = [[MSIDTelemetryBrokerEvent alloc] initWithName:MSID_TELEMETRY_EVENT_LAUNCH_BROKER requestId:self.requestParameters.telemetryRequestId correlationId:self.requestParameters.correlationId];
    
    [brokerEvent setResultStatus:MSID_TELEMETRY_VALUE_FAILED];
    CONDITIONAL_STOP_EVENT(CONDITIONAL_SHARED_INSTANCE, self.requestParameters.telemetryRequestId, brokerEvent);
#endif
    
    [self.class setCurrentBrokerController:nil];
    
    MSIDRequestCompletionBlock completionBlock = [self copyAndClearCompletionBlock];
    
    if (!self.fallbackController || !shouldFallbackToLocalController)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.requestParameters, @"Failed to open broker URL. Should fallback to local controller %d", (int)shouldFallbackToLocalController);
        NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Failed to open broker URL.", nil, nil, nil, nil, nil, NO);
        if (completionBlock) completionBlock(nil, error);
        return;
    }
    
    [self.fallbackController acquireToken:completionBlock];
}

#pragma mark - Current controller

+ (void)setCurrentBrokerController:(MSIDBrokerInteractiveController *)currentBrokerController
{
    @synchronized ([self class]) {
        s_currentExecutingController = currentBrokerController;
    }
}

+ (MSIDBrokerInteractiveController *)currentBrokerController
{
    @synchronized ([self class]) {
        return s_currentExecutingController;
    }
}

#pragma mark - Telemetry

#if !EXCLUDE_FROM_MSALCPP
- (MSIDTelemetryAPIEvent *)telemetryAPIEvent
{
    MSIDTelemetryAPIEvent *event = [super telemetryAPIEvent];

    if (self.interactiveParameters.loginHint)
    {
        [event setLoginHint:self.interactiveParameters.loginHint];
    }

    [event setPromptType:self.interactiveParameters.promptType];

    return event;
}
#endif

@end
