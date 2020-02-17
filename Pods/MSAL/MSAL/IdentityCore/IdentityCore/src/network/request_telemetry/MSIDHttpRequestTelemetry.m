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

#import "MSIDHttpRequestTelemetry.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTelemetryHttpEvent.h"

@implementation MSIDHttpRequestTelemetry

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _telemetry = [MSIDTelemetry sharedInstance];
    }
    return self;
}

- (void)sendRequestEventWithId:(NSString *)telemetryRequestId
{
    [self.telemetry startEvent:telemetryRequestId eventName:MSID_TELEMETRY_EVENT_HTTP_REQUEST];
}

- (void)responseReceivedEventWithContext:(id<MSIDRequestContext>)context
                              urlRequest:(NSURLRequest *)urlRequest
                            httpResponse:(NSHTTPURLResponse *)httpResponse
                                    data:(NSData *)data
                                   error:(NSError *)error
{
    MSIDTelemetryHttpEvent *event = [[MSIDTelemetryHttpEvent alloc] initWithName:MSID_TELEMETRY_EVENT_HTTP_REQUEST
                                                                       requestId:context.telemetryRequestId
                                                                   correlationId:context.correlationId];
    
    [event setHttpMethod:urlRequest.HTTPMethod];
    [event setHttpPath:[NSString stringWithFormat:@"%@://%@/%@", urlRequest.URL.scheme, urlRequest.URL.host, urlRequest.URL.path]];
    
    [event setHttpRequestIdHeader:httpResponse.allHeaderFields[MSID_OAUTH2_CORRELATION_ID_REQUEST_VALUE]];
    [event setClientTelemetry:httpResponse.allHeaderFields[MSID_OAUTH2_CLIENT_TELEMETRY]];
    [event setHttpResponseCode:[NSString stringWithFormat: @"%ld", (long)httpResponse.statusCode]];
    [event setOAuthErrorCodeFromResponseData:data];
    [event setHttpRequestQueryParams:urlRequest.URL.query];
    
    if (error)
    {
        [event setHttpErrorCode:[NSString stringWithFormat: @"%ld", (long)[error code]]];
        [event setHttpErrorDomain:[error domain]];
    }
    
    [self.telemetry stopEvent:context.telemetryRequestId event:event];
}

@end
