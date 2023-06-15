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

#import "MSIDLegacyTokenResponseValidator.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDTokenResult.h"
#import "MSIDAccount.h"
#import "MSIDOauth2Factory.h"
#import "MSIDTokenResponse.h"
#import "MSIDLegacyAccessToken.h"
#import "MSIDLegacyRefreshToken.h"

@implementation MSIDLegacyTokenResponseValidator

- (BOOL)validateTokenResult:(MSIDTokenResult *)tokenResult
              configuration:(__unused MSIDConfiguration *)configuration
                  oidcScope:(__unused NSString *)oidcScope
              correlationID:(NSUUID *)correlationID
                      error:(NSError **)error
{
    if (!tokenResult.account)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, correlationID, @"No account returned from server.");
        
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"No account identifier returned from server.", nil, nil, nil, correlationID, nil, NO);
        }
        
        return NO;
    }

    return YES;
}

- (MSIDTokenResult *)createTokenResultFromResponse:(MSIDTokenResponse *)tokenResponse
                                      oauthFactory:(MSIDOauth2Factory *)factory
                                     configuration:(MSIDConfiguration *)configuration
                                    requestAccount:(__unused MSIDAccountIdentifier *)accountIdentifier
                                     correlationID:(NSUUID *)correlationID
                                             error:(__unused NSError **)error

{
    MSIDLegacyAccessToken *accessToken = [factory legacyAccessTokenFromResponse:tokenResponse configuration:configuration];
    MSIDLegacyRefreshToken *refreshToken = [factory legacyRefreshTokenFromResponse:tokenResponse configuration:configuration];
    
    MSIDAccount *account = [factory accountFromResponse:tokenResponse configuration:configuration];
    
    MSIDTokenResult *result = [[MSIDTokenResult alloc] initWithAccessToken:accessToken
                                                              refreshToken:refreshToken
                                                                   idToken:tokenResponse.idToken
                                                                   account:account
                                                                 authority:configuration.authority
                                                             correlationId:correlationID
                                                             tokenResponse:tokenResponse];
    
    return result;
}

- (BOOL)validateAccount:(MSIDAccountIdentifier *)accountIdentifier
            tokenResult:(MSIDTokenResult *)tokenResult
          correlationID:(NSUUID *)correlationID
                  error:(NSError **)error
{
    MSID_LOG_WITH_CORR_PII(MSIDLogLevelVerbose, correlationID, @"Checking returned account, Input account id %@, returned account ID %@, local account ID %@", MSID_PII_LOG_MASKABLE(accountIdentifier.maskedDisplayableId), MSID_PII_LOG_MASKABLE(tokenResult.account.accountIdentifier.maskedDisplayableId), MSID_PII_LOG_TRACKABLE(tokenResult.account.localAccountId));
    
    switch (accountIdentifier.legacyAccountIdentifierType)
    {
        case MSIDLegacyIdentifierTypeRequiredDisplayableId:
        {
            if (!accountIdentifier.displayableId
                || [accountIdentifier.displayableId.lowercaseString isEqualToString:tokenResult.account.accountIdentifier.displayableId.lowercaseString])
            {
                return YES;
            }
            break;
        }
            
        case MSIDLegacyIdentifierTypeUniqueNonDisplayableId:
        {
            if (!accountIdentifier.localAccountId
                || [accountIdentifier.localAccountId.lowercaseString isEqualToString:tokenResult.account.localAccountId.lowercaseString])
            {
                return YES;
            }
            break;
        }
        case MSIDLegacyIdentifierTypeOptionalDisplayableId:
        {
            return YES;
        }
            
        default:
            break;
        
    }
    
    MSID_LOG_WITH_CORR(MSIDLogLevelError, correlationID, @"Different user was returned by the server. Original account %@, %@, returned account %@, %@", MSID_PII_LOG_EMAIL(accountIdentifier.displayableId), MSID_PII_LOG_TRACKABLE(accountIdentifier.localAccountId), MSID_PII_LOG_EMAIL(tokenResult.account.accountIdentifier.displayableId), MSID_PII_LOG_TRACKABLE(tokenResult.account.localAccountId));
    
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorMismatchedAccount, @"Different user was returned by the server then specified in the acquireToken call. If this is a new sign in use and ADUserIdentifier is of OptionalDisplayableId type, pass in the userId returned on the initial authentication flow in all future acquireToken calls.", nil, nil, nil, correlationID, nil, NO);
    }
    
    return NO;
}

@end

#endif
