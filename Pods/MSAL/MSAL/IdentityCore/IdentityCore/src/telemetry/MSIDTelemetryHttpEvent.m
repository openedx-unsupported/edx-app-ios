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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDTelemetry.h"
#import "MSIDTelemetryHttpEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDOAuth2Constants.h"
#import "NSString+MSIDTelemetryExtensions.h"
#import "NSJSONSerialization+MSIDExtensions.h"

@implementation MSIDTelemetryHttpEvent

- (id)initWithName:(NSString*)eventName
         requestId:(NSString*)requestId
     correlationId:(NSUUID*)correlationId
{
    if (!(self = [super initWithName:eventName requestId:requestId correlationId:correlationId]))
    {
        return nil;
    }
    
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_REQUEST_ID_HEADER value:@""];
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_RESPONSE_CODE value:@""];
    [self setProperty:MSID_TELEMETRY_KEY_OAUTH_ERROR_CODE value:@""];
    
    return self;
}

- (void)setHttpMethod:(NSString*)method
{
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_METHOD value:method];
}

- (void)setHttpPath:(NSString*)path
{
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_PATH value:path];
}

- (void)setHttpRequestIdHeader:(NSString*)requestIdHeader
{
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_REQUEST_ID_HEADER value:requestIdHeader];
}

- (void)setHttpResponseCode:(NSString*)code
{
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_RESPONSE_CODE value:code];
}

- (void)setHttpErrorCode:(NSString*)code
{
    self.errorInEvent = YES;
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_RESPONSE_CODE value:code];
}

- (void)setOAuthErrorCodeFromResponseData:(NSData *)responseData
{
    if (!responseData)
    {
        return;
    }
    
    NSError* jsonError  = nil;
    
    NSDictionary *jsonObject = [NSJSONSerialization msidNormalizedDictionaryFromJsonData:responseData error:&jsonError];
    
    if (!jsonObject)
    {
        return;
    }
    
    NSString *oauthError = [jsonObject msidStringObjectForKey:MSID_OAUTH2_ERROR];
    [self setProperty:MSID_TELEMETRY_KEY_OAUTH_ERROR_CODE value:oauthError];
    self.errorInEvent = ![NSString msidIsStringNilOrBlank:oauthError];
}

- (void)setHttpResponseMethod:(NSString*)method
{
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_RESPONSE_METHOD value:method];
}

- (void)setHttpRequestQueryParams:(NSString*)params
{
    if ([NSString msidIsStringNilOrBlank:params])
    {
        return;
    }
    
    NSArray *parameterKeys = [[NSDictionary msidDictionaryFromURLEncodedString:params] allKeys];
    
    [self setProperty:MSID_TELEMETRY_KEY_REQUEST_QUERY_PARAMS value:[parameterKeys componentsJoinedByString:@";"]];
}

- (void)setHttpUserAgent:(NSString*)userAgent
{
    [self setProperty:MSID_TELEMETRY_KEY_USER_AGENT value:userAgent];
}

- (void)setHttpErrorDomain:(NSString*)errorDomain
{
    [self setProperty:MSID_TELEMETRY_KEY_HTTP_ERROR_DOMAIN value:errorDomain];
}

- (void)setClientTelemetry:(NSString *)clientTelemetry
{
    [self setProperty:MSID_TELEMETRY_KEY_CLIENT_TELEMETRY_RAW value:clientTelemetry];
    
    if (![NSString msidIsStringNilOrBlank:clientTelemetry])
    {
        [_propertyMap addEntriesFromDictionary:[clientTelemetry msidParsedClientTelemetry]];
    }
}

#pragma mark - MSIDTelemetryBaseEvent

+ (NSArray<NSString *> *)propertiesToAggregate
{
    static dispatch_once_t once;
    static NSMutableArray *names = nil;
    
    dispatch_once(&once, ^{
        names = [[super propertiesToAggregate] mutableCopy];
        
        [names addObjectsFromArray:@[
                                     MSID_TELEMETRY_KEY_OAUTH_ERROR_CODE,
                                     MSID_TELEMETRY_KEY_HTTP_RESPONSE_CODE,
                                     MSID_TELEMETRY_KEY_HTTP_EVENT_COUNT,
                                     MSID_TELEMETRY_KEY_SERVER_ERROR_CODE,
                                     MSID_TELEMETRY_KEY_SERVER_SUBERROR_CODE,
                                     MSID_TELEMETRY_KEY_RT_AGE,
                                     MSID_TELEMETRY_KEY_SPE_INFO,
                                     MSID_TELEMETRY_KEY_CLIENT_TELEMETRY_RAW
                                     ]];
    });
    
    return names;
}

@end

#endif
