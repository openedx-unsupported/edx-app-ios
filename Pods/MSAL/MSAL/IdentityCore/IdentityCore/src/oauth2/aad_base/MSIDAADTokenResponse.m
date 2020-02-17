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
#import "MSIDTelemetryEventStrings.h"
#import "MSIDAADV1IdTokenClaims.h"
#import "MSIDHelpers.h"
#import "MSIDRefreshableToken.h"
#import "MSIDBaseToken.h"

@interface MSIDAADTokenResponse ()

@property (readonly) NSString *rawClientInfo;

@end

@implementation MSIDAADTokenResponse

// Default properties for an error response
MSID_JSON_ACCESSOR(MSID_OAUTH2_CORRELATION_ID_RESPONSE, correlationId)

// Default properties for a successful response
MSID_JSON_ACCESSOR(MSID_OAUTH2_RESOURCE, resource)
MSID_JSON_RW(MSID_OAUTH2_CLIENT_INFO, rawClientInfo, setRawClientInfo)
MSID_JSON_ACCESSOR(MSID_FAMILY_ID, familyId)
MSID_JSON_ACCESSOR(MSID_TELEMETRY_KEY_SPE_INFO, speInfo)
MSID_JSON_ACCESSOR(MSID_OAUTH2_SUB_ERROR, suberror)
MSID_JSON_ACCESSOR(@"adi", additionalUserId)

- (instancetype)initWithJSONDictionary:(NSDictionary *)json
                          refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                 error:(NSError **)error
{
    self = [super initWithJSONDictionary:json refreshToken:token error:error];
    
    if (self)
    {
        [self initDerivedProperties];
    }
    
    return self;
}

- (id)initWithJSONDictionary:(NSDictionary *)json error:(NSError *__autoreleasing *)error
{
    if (!(self = [super initWithJSONDictionary:json error:error]))
    {
        return nil;
    }
    
    [self initDerivedProperties];
    return self;
}

- (void)initDerivedProperties
{
    if (self.extendedExpiresIn)
    {
        _extendedExpiresOnDate = [NSDate dateWithTimeIntervalSinceNow:self.extendedExpiresIn];
    }
    else if (_json[@"ext_expires_on"] && [MSIDHelpers msidIntegerValue:_json[@"ext_expires_on"]])
    {
        //Broker could send ext_expires_on rather than ext_expires_in
        NSInteger extExpiresOn = [MSIDHelpers msidIntegerValue:_json[@"ext_expires_on"]];
        _extendedExpiresOnDate = [NSDate dateWithTimeIntervalSince1970:extExpiresOn];
    }
    
    if (self.rawClientInfo && !_clientInfo)
    {
        _clientInfo = [[MSIDClientInfo alloc] initWithRawClientInfo:self.rawClientInfo error:nil];
    }
}

- (NSInteger)expiresOn
{
    id expiresOnObj = _json[MSID_OAUTH2_EXPIRES_ON];
    NSInteger expiresOn = [MSIDHelpers msidIntegerValue:expiresOnObj];
    
    if (!expiresOn && expiresOnObj)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Unparsable time - The response value for the access token expiration (expiresOn) cannot be parsed: %@", expiresOnObj);
    }
    
    return expiresOn;
}

- (void)setExpiresOn:(NSInteger)expiresOn
{
    NSString *expiresOnString = [NSString stringWithFormat:@"%ld", (long)expiresOn];
    _json[MSID_OAUTH2_EXPIRES_ON] = expiresOnString;
}

- (NSInteger)extendedExpiresIn
{
    id extExpiresInObj = _json[MSID_OAUTH2_EXT_EXPIRES_IN];
    NSInteger extExpiresIn = [MSIDHelpers msidIntegerValue:extExpiresInObj];
    
    if (!extExpiresIn && extExpiresInObj)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Unparsable time - The response value for the access token expiration (extended expires IN) cannot be parsed: %@", extExpiresInObj);
    }
    
    return extExpiresIn;
}

- (void)setExtendedExpiresIn:(NSInteger)extendedExpiresIn
{
    NSString *extExpiresInString = [NSString stringWithFormat:@"%ld", (long)extendedExpiresIn];
    _json[MSID_OAUTH2_EXT_EXPIRES_IN] = extExpiresInString;
}

- (NSDate *)expiryDate
{
    NSDate *date = [super expiryDate];
    
    if (date)
    {
        return date;
    }
    
    NSInteger expiresOn = self.expiresOn;
    
    if (!expiresOn)
    {
        return nil;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:expiresOn];
}

- (NSDictionary *)additionalServerInfo
{
    NSDictionary *additionalInfo = [super additionalServerInfo];
    
    NSArray *knownFields = @[MSID_OAUTH2_CORRELATION_ID_RESPONSE,
                             MSID_OAUTH2_RESOURCE,
                             MSID_OAUTH2_CLIENT_INFO,
                             MSID_FAMILY_ID,
                             MSID_TELEMETRY_KEY_SPE_INFO,
                             MSID_OAUTH2_EXPIRES_ON,
                             MSID_OAUTH2_EXT_EXPIRES_IN, @"url",
                             MSID_OAUTH2_SUB_ERROR];
    
    additionalInfo = [additionalInfo dictionaryByRemovingFields:knownFields];
    if (additionalInfo.count > 0)
    {
        return additionalInfo;
    }
    return nil;
}

- (NSString *)description
{
    NSString *descr = [super description];
    return [NSString stringWithFormat:@"%@, familyID %@, suberror %@, additional user ID %@, clientInfo %@", descr, self.familyId, self.suberror, self.additionalUserId, self.clientInfo.rawClientInfo];
}

@end
