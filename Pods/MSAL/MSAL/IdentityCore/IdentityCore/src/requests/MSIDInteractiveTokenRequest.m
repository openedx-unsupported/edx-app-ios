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

#import "MSIDInteractiveTokenRequest+Internal.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDAuthority.h"
#import "MSIDTokenResponseValidator.h"
#import "MSIDTokenResult.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTokenResponseHandler.h"
#import "MSIDAccount.h"
#import "NSError+MSIDServerTelemetryError.h"
#import "MSIDAuthorizationCodeResult.h"
#import "MSIDAuthorizationCodeGrantRequest.h"
#import "MSIDOauth2Factory.h"
#import "MSIDAccountIdentifier.h"

#if TARGET_OS_IPHONE
#import "MSIDAppExtensionUtil.h"
#import "MSIDBackgroundTaskManager.h"
#endif

#if TARGET_OS_OSX && !EXCLUDE_FROM_MSALCPP
#import "MSIDExternalAADCacheSeeder.h"
#endif

@interface MSIDInteractiveTokenRequest()

@property (nonatomic) MSIDTokenResponseHandler *tokenResponseHandler;

@end

@implementation MSIDInteractiveTokenRequest

- (nullable instancetype)initWithRequestParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                      oauthFactory:(nonnull MSIDOauth2Factory *)oauthFactory
                            tokenResponseValidator:(nonnull MSIDTokenResponseValidator *)tokenResponseValidator
                                        tokenCache:(nonnull id<MSIDCacheAccessor>)tokenCache
                              accountMetadataCache:(nullable MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                                extendedTokenCache:(nullable id<MSIDExtendedTokenCacheDataSource>)extendedTokenCache
{
    self = [super initWithRequestParameters:parameters oauthFactory:oauthFactory];

    if (self)
    {
        _tokenResponseValidator = tokenResponseValidator;
        _tokenCache = tokenCache;
        _accountMetadataCache = accountMetadataCache;
        _tokenResponseHandler = [MSIDTokenResponseHandler new];
        _extendedTokenCache = extendedTokenCache;
    }

    return self;
}

- (void)executeRequestWithCompletion:(nonnull MSIDInteractiveRequestCompletionBlock) __unused completionBlock
{
#if !EXCLUDE_FROM_MSALCPP
#if TARGET_OS_IPHONE
    [[MSIDBackgroundTaskManager sharedInstance] startOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
#endif
    
    [super getAuthCodeWithCompletion:^(MSIDAuthorizationCodeResult * _Nullable result, NSError * _Nullable error, MSIDWebWPJResponse * _Nullable installBrokerResponse)
    {
        if (!result)
        {
            completionBlock(nil, error, installBrokerResponse);
            return;
        }
        
        [self.requestParameters updateAppRequestMetadata:result.accountIdentifier];
        
        [self acquireTokenWithCodeResult:result completion:completionBlock];
    }];
#endif
}

#pragma mark - Helpers

- (void)acquireTokenWithCodeResult:(MSIDAuthorizationCodeResult *) __unused authCodeResult
                        completion:(MSIDInteractiveRequestCompletionBlock) __unused completionBlock
{
#if !EXCLUDE_FROM_MSALCPP
    MSIDAuthorizationCodeGrantRequest *tokenRequest = [self.oauthFactory authorizationGrantRequestWithRequestParameters:self.requestParameters
                                                                                                           codeVerifier:authCodeResult.pkceVerifier
                                                                                                               authCode:authCodeResult.authCode
                                                                                                          homeAccountId:authCodeResult.accountIdentifier];

    [tokenRequest sendWithBlock:^(MSIDTokenResponse *tokenResponse, NSError *error)
    {
#if TARGET_OS_IPHONE
    [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
#elif TARGET_OS_OSX
    self.tokenResponseHandler.externalCacheSeeder = self.externalCacheSeeder;
#endif
        [self.tokenResponseHandler handleTokenResponse:tokenResponse
                                     requestParameters:self.requestParameters
                                         homeAccountId:authCodeResult.accountIdentifier
                                tokenResponseValidator:self.tokenResponseValidator
                                          oauthFactory:self.oauthFactory
                                            tokenCache:self.tokenCache
                                  accountMetadataCache:self.accountMetadataCache
                                       validateAccount:self.requestParameters.shouldValidateResultAccount
                                      saveSSOStateOnly:NO
                                                 error:error
                                       completionBlock:^(MSIDTokenResult *result, NSError *localError)
         {
            completionBlock(result, localError, nil);
        }];
    }];
#endif
}

- (void)dealloc
{
#if TARGET_OS_IPHONE
    [[MSIDBackgroundTaskManager sharedInstance] stopOperationWithType:MSIDBackgroundTaskTypeInteractiveRequest];
#endif
}

@end
