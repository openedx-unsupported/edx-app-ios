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

#import "MSIDTelemetryPiiOiiRules.h"
#import "MSIDTelemetryEventStrings.h"

static NSSet *_piiFields;
static NSSet *_oiiFields;

@implementation MSIDTelemetryPiiOiiRules

+ (void)initialize
{
    _piiFields = [[NSSet alloc] initWithArray:@[MSID_TELEMETRY_KEY_USER_ID,
                                               MSID_TELEMETRY_KEY_DEVICE_ID,
                                               MSID_TELEMETRY_KEY_LOGIN_HINT,
                                               MSID_TELEMETRY_KEY_ERROR_DESCRIPTION,
                                               MSID_TELEMETRY_KEY_REQUEST_QUERY_PARAMS]];
    
    _oiiFields = [[NSSet alloc] initWithArray:@[MSID_TELEMETRY_KEY_TENANT_ID,
                                                MSID_TELEMETRY_KEY_CLIENT_ID,
                                                MSID_TELEMETRY_KEY_HTTP_PATH,
                                                MSID_TELEMETRY_KEY_AUTHORITY,
                                                MSID_TELEMETRY_KEY_IDP,
                                                MSID_TELEMETRY_KEY_APPLICATION_NAME,
                                                MSID_TELEMETRY_KEY_APPLICATION_VERSION]];
}

#pragma mark - Public

+ (BOOL)isPii:(NSString *)propertyName
{
    if (!propertyName)
    {
        return NO;
    }
    
    return [_piiFields containsObject:propertyName];
}

+ (BOOL)isOii:(NSString *)propertyName
{
    if (!propertyName)
    {
        return NO;
    }
    
    return [_oiiFields containsObject:propertyName];
}

+ (BOOL)isPiiOrOii:(NSString *)propertyName
{
    return [self isPii:propertyName] || [self isOii:propertyName];
}

@end

#endif
