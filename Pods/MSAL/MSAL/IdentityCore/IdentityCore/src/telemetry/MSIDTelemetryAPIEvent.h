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

#import "MSIDTelemetryBaseEvent.h"
#import "MSIDConstants.h"

@class MSIDAccount;
@class MSIDAuthority;

@interface MSIDTelemetryAPIEvent : MSIDTelemetryBaseEvent

- (void)setCorrelationId:(NSUUID *)correlationId;
- (void)setExtendedExpiresOnSetting:(NSString *)extendedExpiresOnSetting;
- (void)setUserId:(NSString *)userId;
- (void)setClientId:(NSString *)clientId;
- (void)setIsExtendedLifeTimeToken:(NSString *)isExtendedLifeToken;
- (void)setErrorDomain:(NSString *)errorDomain;

- (void)setApiId:(NSString *)apiId;

- (void)setWebviewType:(NSString *)webviewType;

- (void)setLoginHint:(NSString *)loginHint;
- (void)setErrorCode:(NSUInteger)errorCode;
- (void)setPromptType:(MSIDPromptType)promptType;

- (void)setIsSuccessfulStatus:(NSString *)successStatus;
- (void)setResultStatus:(NSString *)resultStatus;
- (void)setUserInformation:(MSIDAccount *)account;
- (void)setOauthErrorCode:(NSString *)oauthErrorCode;

@end
