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

#import "MSIDTokenResponseHandler.h"
#import "MSIDTokenResponse.h"
#import "MSIDRequestParameters.h"
#import "MSIDTokenResponseValidator.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"

#if TARGET_OS_OSX && !EXCLUDE_FROM_MSALCPP
#import "MSIDExternalAADCacheSeeder.h"
#endif

@implementation MSIDTokenResponseHandler

- (void)handleTokenResponse:(MSIDTokenResponse *)tokenResponse
          requestParameters:(MSIDRequestParameters *)requestParameters
              homeAccountId:(NSString *)homeAccountId
     tokenResponseValidator:(MSIDTokenResponseValidator *)tokenResponseValidator
               oauthFactory:(MSIDOauth2Factory *)oauthFactory
                 tokenCache:(id<MSIDCacheAccessor>)tokenCache
       accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
            validateAccount:(BOOL)validateAccount
           saveSSOStateOnly:(BOOL)saveSSOStateOnly
                      error:(NSError *)error
            completionBlock:(MSIDRequestCompletionBlock)completionBlock
{
    if (error)
    {
        completionBlock(nil, error);
        return;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Validate and save token response...");
        
    NSError *validationError;
    MSIDTokenResult *tokenResult = [tokenResponseValidator validateAndSaveTokenResponse:tokenResponse
                                                                           oauthFactory:oauthFactory
                                                                             tokenCache:tokenCache
                                                                   accountMetadataCache:accountMetadataCache
                                                                      requestParameters:requestParameters
                                                                       saveSSOStateOnly:saveSSOStateOnly
                                                                                  error:&validationError];
       
    if (!tokenResult)
    {
        // Special case - need to return homeAccountId in case of Intune policies required.
        if (validationError.code == MSIDErrorServerProtectionPoliciesRequired)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Received Protection Policy Required error.");
            
            NSMutableDictionary *updatedUserInfo = [validationError.userInfo mutableCopy];
            if (homeAccountId) updatedUserInfo[MSIDHomeAccountIdkey] = homeAccountId;
            
            validationError = MSIDCreateError(validationError.domain,
                                              validationError.code,
                                              nil,
                                              nil,
                                              nil,
                                              nil,
                                              nil,
                                              updatedUserInfo, YES);
        }
        
        completionBlock(nil, validationError);
        return;
    }
    
    void (^validateAccountAndCompleteBlock)(void) = ^
    {
        if (validateAccount)
        {
            NSError *tokenResponseValidatorError;
            BOOL accountChecked = [tokenResponseValidator validateAccount:requestParameters.accountIdentifier
                                                              tokenResult:tokenResult
                                                            correlationID:requestParameters.correlationId
                                                                    error:&tokenResponseValidatorError];
            
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, requestParameters, @"Validated result account with result %d, old account %@, new account %@", accountChecked, MSID_PII_LOG_TRACKABLE(requestParameters.accountIdentifier.uid), MSID_PII_LOG_TRACKABLE(tokenResult.account.accountIdentifier.uid));
            
            if (!accountChecked)
            {
                completionBlock(nil, tokenResponseValidatorError);
                return;
            }
        }
        
        completionBlock(tokenResult, nil);
    };
    
#if TARGET_OS_OSX && !EXCLUDE_FROM_MSALCPP
    if (self.externalCacheSeeder != nil)
    {
        [self.externalCacheSeeder seedTokenResponse:tokenResponse
                                            factory:oauthFactory
                                  requestParameters:requestParameters
                                    completionBlock:validateAccountAndCompleteBlock];
    }
    else
#endif
    {
        validateAccountAndCompleteBlock();
    }
}

@end
