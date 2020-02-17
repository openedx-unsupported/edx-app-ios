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

#import "MSIDBaseRequestController.h"
#import "MSIDAuthority.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDErrorConverter.h"

@interface MSIDBaseRequestController()

@property (nonatomic, readwrite) MSIDRequestParameters *requestParameters;
@property (nonatomic, readwrite) id<MSIDTokenRequestProviding> tokenRequestProvider;
@property (nonatomic, readwrite) id<MSIDRequestControlling> fallbackController;

@end

@implementation MSIDBaseRequestController

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDRequestParameters *)parameters
                              tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                             error:(NSError * _Nullable * _Nullable)error
{
    self = [super init];

    if (self)
    {
        _requestParameters = parameters;

        NSError *parametersError = nil;

        if (![_requestParameters validateParametersWithError:&parametersError])
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.requestParameters,  @"Request parameters error %@", MSID_PII_LOG_MASKABLE(parametersError));

            if (error)
            {
                *error = parametersError;
            }

            return nil;
        }

        _tokenRequestProvider = tokenRequestProvider;
        _fallbackController = fallbackController;
    }

    return self;
}

#pragma mark - Telemetry

- (MSIDTelemetryAPIEvent *)telemetryAPIEvent
{
    MSIDTelemetryAPIEvent *event = [[MSIDTelemetryAPIEvent alloc] initWithName:MSID_TELEMETRY_EVENT_API_EVENT context:self.requestParameters];

    [event setApiId:self.requestParameters.telemetryApiId];
    [event setCorrelationId:self.requestParameters.correlationId];
    [event setClientId:self.requestParameters.clientId];
    NSString *extExpiresSetting = self.requestParameters.extendedLifetimeEnabled ? MSID_TELEMETRY_VALUE_YES : MSID_TELEMETRY_VALUE_NO;
    [event setExtendedExpiresOnSetting:extExpiresSetting];
    return event;
}

- (void)stopTelemetryEvent:(MSIDTelemetryAPIEvent *)event error:(NSError *)error
{
    if (error)
    {
        [event setErrorCode:error.code];
        [event setErrorDomain:error.domain];
        [event setOauthErrorCode:error.userInfo[MSIDErrorConverter.defaultErrorConverter.oauthErrorKey]];
        [event setResultStatus:MSID_TELEMETRY_VALUE_FAILED];
        [event setIsSuccessfulStatus:MSID_TELEMETRY_VALUE_NO];
    }
    else
    {
        [event setResultStatus:MSID_TELEMETRY_VALUE_SUCCEEDED];
        [event setIsSuccessfulStatus:MSID_TELEMETRY_VALUE_YES];
    }

    [[MSIDTelemetry sharedInstance] stopEvent:self.requestParameters.telemetryRequestId event:event];
    [[MSIDTelemetry sharedInstance] flush:self.requestParameters.telemetryRequestId];
}

@end
