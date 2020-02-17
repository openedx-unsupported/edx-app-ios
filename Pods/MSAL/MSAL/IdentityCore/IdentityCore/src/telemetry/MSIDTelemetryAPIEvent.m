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

#import "MSIDTelemetry.h"
#import "MSIDTelemetryAPIEvent.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDAccount.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAuthority.h"
#import "NSURL+MSIDExtensions.h"
#import "MSIDPromptType_Internal.h"

@implementation MSIDTelemetryAPIEvent

- (void)setCorrelationId:(NSUUID *)correlationId
{
    [self setProperty:MSID_TELEMETRY_KEY_CORRELATION_ID value:[correlationId UUIDString]];
}

- (void)setExtendedExpiresOnSetting:(NSString *)extendedExpiresOnSetting
{
    [self setProperty:MSID_TELEMETRY_KEY_EXTENDED_EXPIRES_ON_SETTING value:extendedExpiresOnSetting];
}

- (void)setUserId:(NSString *)userId
{
    [self setProperty:MSID_TELEMETRY_KEY_USER_ID value:userId];
}

- (void)setClientId:(NSString *)clientId
{
    [self setProperty:MSID_TELEMETRY_KEY_CLIENT_ID value:clientId];
}

- (void)setIsExtendedLifeTimeToken:(NSString *)isExtendedLifeToken
{
    [self setProperty:MSID_TELEMETRY_KEY_IS_EXTENED_LIFE_TIME_TOKEN value:isExtendedLifeToken];
}

- (void)setErrorDomain:(NSString *)errorDomain
{
    [self setProperty:MSID_TELEMETRY_KEY_ERROR_DOMAIN value:errorDomain];
}

- (void)setApiId:(NSString *)apiId
{
    [self setProperty:MSID_TELEMETRY_KEY_API_ID value:apiId];
}

- (void)setWebviewType:(NSString *)webviewType
{
    [self setProperty:MSID_TELEMETRY_KEY_WEBVIEW_TYPE value:webviewType];
}

- (void)setLoginHint:(NSString *)loginHint
{
    [self setProperty:MSID_TELEMETRY_KEY_LOGIN_HINT value:loginHint];
}

- (void)setErrorCode:(NSUInteger)errorCode
{
    self.errorInEvent = YES;
    [self setProperty:MSID_TELEMETRY_KEY_API_ERROR_CODE value:[NSString stringWithFormat:@"%ld", (long)errorCode]];
}

- (void)setPromptType:(MSIDPromptType)promptType
{
    NSString *promptParam = MSIDPromptParamFromType(promptType);
    [self setProperty:MSID_TELEMETRY_KEY_PROMPT_BEHAVIOR value:promptParam];
}

- (void)setIsSuccessfulStatus:(NSString *)successStatus
{
    [self setProperty:MSID_TELEMETRY_KEY_IS_SUCCESSFUL value:successStatus];
}

- (void)setResultStatus:(NSString *)resultStatus
{
    [self setProperty:MSID_TELEMETRY_KEY_RESULT_STATUS value:resultStatus];
}

- (void)setUserInformation:(MSIDAccount *)account
{
    [self setProperty:MSID_TELEMETRY_KEY_USER_ID value:account.accountIdentifier.displayableId];
    [self setProperty:MSID_TELEMETRY_KEY_TENANT_ID value:account.realm];
}

- (void)setOauthErrorCode:(NSString *)oauthErrorCode
{
    [self setProperty:MSID_TELEMETRY_KEY_PROTOCOL_CODE value:oauthErrorCode];
}

#pragma mark - MSIDTelemetryBaseEvent

+ (NSArray<NSString *> *)propertiesToAggregate
{
    static dispatch_once_t once;
    static NSMutableArray *names = nil;
    
    dispatch_once(&once, ^{
        names = [[super propertiesToAggregate] mutableCopy];
        
        [names addObjectsFromArray:@[
                                     MSID_TELEMETRY_KEY_EXTENDED_EXPIRES_ON_SETTING,
                                     MSID_TELEMETRY_KEY_PROMPT_BEHAVIOR,
                                     MSID_TELEMETRY_KEY_RESULT_STATUS,
                                     MSID_TELEMETRY_KEY_TENANT_ID,
                                     MSID_TELEMETRY_KEY_USER_ID,
                                     MSID_TELEMETRY_KEY_RESPONSE_TIME,
                                     MSID_TELEMETRY_KEY_CLIENT_ID,
                                     MSID_TELEMETRY_KEY_API_ID,
                                     MSID_TELEMETRY_KEY_API_ERROR_CODE,
                                     MSID_TELEMETRY_KEY_ERROR_DOMAIN,
                                     MSID_TELEMETRY_KEY_PROTOCOL_CODE,
                                     MSID_TELEMETRY_KEY_IS_SUCCESSFUL
                                     ]];
    });
    
    return names;
}

@end
