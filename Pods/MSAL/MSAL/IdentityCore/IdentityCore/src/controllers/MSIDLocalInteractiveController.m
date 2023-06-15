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

#import "MSIDLocalInteractiveController+Internal.h"
#import "MSIDInteractiveTokenRequest+Internal.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"
#import "MSIDClientInfo.h"
#if TARGET_OS_IPHONE
#import "MSIDBrokerInteractiveController.h"
#endif
#import "MSIDWebWPJResponse.h"
#import "MSIDThrottlingService.h"

@interface MSIDLocalInteractiveController()

@property (nonatomic, readwrite) MSIDInteractiveTokenRequestParameters *interactiveRequestParamaters;
@property (nonatomic) MSIDInteractiveTokenRequest *currentRequest;

@end

@implementation MSIDLocalInteractiveController

#pragma mark - Init

- (nullable instancetype)initWithInteractiveRequestParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                         tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                        error:(NSError * _Nullable * _Nullable)error
{
    self = [super initWithRequestParameters:parameters
                       tokenRequestProvider:tokenRequestProvider
                         fallbackController:nil
                                      error:error];

    if (self)
    {
        _interactiveRequestParamaters = parameters;
    }

    return self;
}

#pragma mark - MSIDRequestControlling

- (void)acquireToken:(MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Beginning interactive flow.");
    
    MSIDInteractiveTokenRequest *request = [self.tokenRequestProvider interactiveTokenRequestWithParameters:self.interactiveRequestParamaters];

    MSIDRequestCompletionBlock completionBlockWrapper = ^(MSIDTokenResult * _Nullable result, NSError * _Nullable error)
    {
        NSString *ssoNonce = [error.userInfo valueForKey:MSID_SSO_NONCE_QUERY_PARAM_KEY];
        if ([NSString msidIsStringNilOrBlank:ssoNonce])
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Interactive flow finished. Result %@, error: %ld error domain: %@", _PII_NULLIFY(result), (long)error.code, error.domain);
        }
        if (!error)
        {
            /**
             Throttling service: when an interactive token succeed, we update the last refresh time of the throttling service
             */
            [MSIDThrottlingService updateLastRefreshTimeDatasource:request.extendedTokenCache
                                                               context:self.interactiveRequestParamaters
                                                                 error:nil];
        }
        
        completionBlock(result, error);
    };

    [self acquireTokenWithRequest:request completionBlock:completionBlockWrapper];
}

- (void)handleWebMSAuthResponse:(MSIDWebWPJResponse *)response completion:(MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Handling msauth response.");
    
    if (![NSString msidIsStringNilOrBlank:response.appInstallLink])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Prompt broker install.");
        [self promptBrokerInstallWithResponse:response completionBlock:completionBlock];
        return;
    }

    if (![NSString msidIsStringNilOrBlank:response.upn])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Workplace join is required.");
        
        NSMutableDictionary *additionalInfo = [NSMutableDictionary new];
        additionalInfo[MSIDUserDisplayableIdkey] = response.upn;
        additionalInfo[MSIDHomeAccountIdkey] = response.clientInfo.accountIdentifier;
        
        NSError *registrationError = MSIDCreateError(MSIDErrorDomain, MSIDErrorWorkplaceJoinRequired, @"Workplace join is required", nil, nil, nil, self.requestParameters.correlationId, additionalInfo, NO);
#if !EXCLUDE_FROM_MSALCPP
        MSIDTelemetryAPIEvent *telemetryEvent = [self telemetryAPIEvent];
        [telemetryEvent setLoginHint:response.upn];
        [self stopTelemetryEvent:telemetryEvent error:registrationError];
#endif
        completionBlock(nil, registrationError);
        return;
    }

    NSError *appInstallError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"App install link is missing. Incorrect URL returned from server", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
    CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], appInstallError);
    completionBlock(nil, appInstallError);
}

- (void)promptBrokerInstallWithResponse:(__unused MSIDWebWPJResponse *)response completionBlock:(MSIDRequestCompletionBlock)completion
{
#if TARGET_OS_IPHONE
    if ([NSString msidIsStringNilOrBlank:response.appInstallLink])
    {
        NSError *appInstallError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"App install link is missing. Incorrect URL returned from server", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
        CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], appInstallError);
        completion(nil, appInstallError);
        return;
    }

    NSError *brokerError = nil;
    MSIDBrokerInteractiveController *brokerController = [[MSIDBrokerInteractiveController alloc] initWithInteractiveRequestParameters:self.interactiveRequestParamaters
                                                                                                                 tokenRequestProvider:self.tokenRequestProvider
                                                                                                                    brokerInstallLink:[NSURL URLWithString:response.appInstallLink]
                                                                                                                                error:&brokerError];

    if (!brokerController)
    {
        CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], brokerError);
        completion(nil, brokerError);
        return;
    }

    [brokerController acquireToken:completion];
#else
    NSError *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Trying to install broker on macOS, where it's not currently supported", nil, nil, nil, self.requestParameters.correlationId, nil, YES);
    CONDITIONAL_STOP_TELEMETRY_EVENT([self telemetryAPIEvent], error);
    completion(nil, error);
#endif
}

#if !EXCLUDE_FROM_MSALCPP
- (MSIDTelemetryAPIEvent *)telemetryAPIEvent
{
    MSIDTelemetryAPIEvent *event = [super telemetryAPIEvent];

    if (self.interactiveRequestParamaters.loginHint)
    {
        [event setLoginHint:self.interactiveRequestParamaters.loginHint];
    }

    [event setWebviewType:self.interactiveRequestParamaters.telemetryWebviewType];
    [event setPromptType:self.interactiveRequestParamaters.promptType];

    return event;
}
#endif

#pragma mark - Protected

- (void)acquireTokenWithRequest:(MSIDInteractiveTokenRequest *)request
                completionBlock:(MSIDRequestCompletionBlock)completionBlock
{
    if (!completionBlock)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.requestParameters, @"Passed nil completionBlock.");
        return;
    }

    CONDITIONAL_START_EVENT(CONDITIONAL_SHARED_INSTANCE, self.interactiveRequestParamaters.telemetryRequestId, MSID_TELEMETRY_EVENT_API_EVENT);

    self.currentRequest = request;
    
    [request executeRequestWithCompletion:^(MSIDTokenResult *result, NSError *error, MSIDWebWPJResponse *msauthResponse)
    {
        if (msauthResponse)
        {
            self.currentRequest = nil;
            [self handleWebMSAuthResponse:msauthResponse completion:completionBlock];
            return;
        }
#if !EXCLUDE_FROM_MSALCPP
        MSIDTelemetryAPIEvent *telemetryEvent = [self telemetryAPIEvent];
        [telemetryEvent setUserInformation:result.account];
        [self stopTelemetryEvent:telemetryEvent error:error];
#endif
        self.currentRequest = nil;
        
        completionBlock(result, error);
    }];
}

@end
