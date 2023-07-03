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

#import "MSIDAADTokenResponse.h"
#import "MSIDTokenResponse+Internal.h"
#import "MSIDTelemetryEventStrings.h"

@implementation MSIDAADTokenResponse

- (NSString *)description
{
    NSString *descr = [super description];
    return [NSString stringWithFormat:@"%@, familyID %@, suberror %@, additional user ID %@, clientInfo %@", descr, self.familyId, self.suberror, self.additionalUserId, self.clientInfo.rawClientInfo];
}

- (void)setAdditionalServerInfo:(NSDictionary *)additionalServerInfo
{
    NSArray *knownFields = @[MSID_OAUTH2_CORRELATION_ID_RESPONSE,
                             MSID_OAUTH2_RESOURCE,
                             MSID_OAUTH2_CLIENT_INFO,
                             MSID_FAMILY_ID,
#if !EXCLUDE_FROM_MSALCPP
                             MSID_TELEMETRY_KEY_SPE_INFO,
#endif
                             MSID_OAUTH2_EXT_EXPIRES_IN,
                             MSID_OAUTH2_REFRESH_IN,
                             MSID_OAUTH2_REFRESH_ON,
                             @"url",
                             @"ext_expires_on",
                             MSID_OAUTH2_SUB_ERROR];
    
    NSDictionary *additionalInfo = [additionalServerInfo msidDictionaryByRemovingFields:knownFields];
    
    [super setAdditionalServerInfo:additionalInfo];
}

#pragma mark - Derived properties

- (NSDate *)extendedExpiresOnDate
{
    if (self.extendedExpiresOn) return [NSDate dateWithTimeIntervalSince1970:self.extendedExpiresOn];
    if (self.extendedExpiresIn) return [NSDate dateWithTimeIntervalSinceNow:self.extendedExpiresIn];

    return nil;
}

- (NSDate *)refreshOnDate
{
    if (self.refreshOn) return [NSDate dateWithTimeIntervalSince1970:self.refreshOn];
    if (self.refreshIn) return [NSDate dateWithTimeIntervalSinceNow:self.refreshIn];
    
    return nil;
}
#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    if (self)
    {
        _correlationId = [json msidStringObjectForKey:MSID_OAUTH2_CORRELATION_ID_RESPONSE];
        _familyId = [json msidStringObjectForKey:MSID_FAMILY_ID];
#if !EXCLUDE_FROM_MSALCPP
        _speInfo = [json msidStringObjectForKey:MSID_TELEMETRY_KEY_SPE_INFO];
#endif
        _suberror = [json msidStringObjectForKey:MSID_OAUTH2_SUB_ERROR];
        _additionalUserId = [json msidStringObjectForKey:@"adi"];
        
        NSString *rawClientInfo = [json msidStringObjectForKey:MSID_OAUTH2_CLIENT_INFO];
        if (rawClientInfo) _clientInfo = [[MSIDClientInfo alloc] initWithRawClientInfo:rawClientInfo error:nil];
        
        _extendedExpiresIn = [json msidIntegerObjectForKey:MSID_OAUTH2_EXT_EXPIRES_IN];
        _extendedExpiresOn = [json msidIntegerObjectForKey:@"ext_expires_on"];
        _refreshIn = [json msidIntegerObjectForKey:MSID_OAUTH2_REFRESH_IN];
        _refreshOn = [json msidIntegerObjectForKey:MSID_OAUTH2_REFRESH_ON];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableDeepCopy];
    json[MSID_OAUTH2_CORRELATION_ID_RESPONSE] = self.correlationId;
    json[MSID_FAMILY_ID] = self.familyId;
#if !EXCLUDE_FROM_MSALCPP
    json[MSID_TELEMETRY_KEY_SPE_INFO] = self.speInfo;
#endif
    json[MSID_OAUTH2_SUB_ERROR] = self.suberror;
    json[@"adi"] = self.additionalUserId;
    json[MSID_OAUTH2_CLIENT_INFO] = self.clientInfo.rawClientInfo;
    if (!self.error)
    {
        json[MSID_OAUTH2_EXT_EXPIRES_IN] = [@(self.extendedExpiresIn) stringValue];
        json[@"ext_expires_on"] = [@(self.extendedExpiresOn) stringValue];
        json[MSID_OAUTH2_REFRESH_IN] = [@(self.refreshIn) stringValue];
        json[MSID_OAUTH2_REFRESH_ON] = [@(self.refreshOn) stringValue];
    }
    
    return json;
}

@end
