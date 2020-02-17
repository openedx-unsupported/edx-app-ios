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

#import "MSIDSilentController.h"
#import "MSIDSilentTokenRequest.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"

@interface MSIDSilentController()

@property (nonatomic, readwrite) BOOL forceRefresh;

@end

@implementation MSIDSilentController

#pragma mark - Init

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                              tokenRequestProvider:(id<MSIDTokenRequestProviding>)tokenRequestProvider
                                             error:(NSError * _Nullable * _Nullable)error
{
    return [self initWithRequestParameters:parameters
                              forceRefresh:forceRefresh
                      tokenRequestProvider:tokenRequestProvider
             fallbackInteractiveController:nil
                                     error:error];
}

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                                      forceRefresh:(BOOL)forceRefresh
                              tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                     fallbackInteractiveController:(nullable id<MSIDRequestControlling>)fallbackController
                                             error:(NSError * _Nullable * _Nullable)error
{
    self = [super initWithRequestParameters:parameters
                       tokenRequestProvider:tokenRequestProvider
                         fallbackController:fallbackController
                                      error:error];
    
    if (self)
    {
        _forceRefresh = forceRefresh;
    }
    
    return self;
}

#pragma mark - MSIDRequestControlling

- (void)acquireToken:(nonnull MSIDRequestCompletionBlock)completionBlock
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Beginning silent flow.");
    
    if (!completionBlock)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Passed nil completionBlock");
        return;
    }

    [[MSIDTelemetry sharedInstance] startEvent:self.requestParameters.telemetryRequestId eventName:MSID_TELEMETRY_EVENT_API_EVENT];

    MSIDSilentTokenRequest *silentRequest = [self.tokenRequestProvider silentTokenRequestWithParameters:self.requestParameters
                                                                                           forceRefresh:self.forceRefresh];

    [silentRequest executeRequestWithCompletion:^(MSIDTokenResult * _Nullable result, NSError * _Nullable error)
    {
        MSIDRequestCompletionBlock completionBlockWrapper = ^(MSIDTokenResult * _Nullable result, NSError * _Nullable error)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.requestParameters, @"Silent flow finished result %@, error: %ld error domain: %@", _PII_NULLIFY(result), (long)error.code, error.domain);
            completionBlock(result, error);
        };
        
        if (result || !self.fallbackController)
        {
            MSIDTelemetryAPIEvent *telemetryEvent = [self telemetryAPIEvent];
            [telemetryEvent setUserInformation:result.account];
            [telemetryEvent setIsExtendedLifeTimeToken:result.extendedLifeTimeToken ? MSID_TELEMETRY_VALUE_YES : MSID_TELEMETRY_VALUE_NO];
            [self stopTelemetryEvent:telemetryEvent error:error];
            completionBlockWrapper(result, error);
            return;
        }

        [self.fallbackController acquireToken:completionBlockWrapper];
    }];
}

@end
