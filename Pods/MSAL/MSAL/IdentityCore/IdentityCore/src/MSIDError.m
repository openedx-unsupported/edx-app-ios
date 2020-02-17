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

#import "MSIDErrorConverter.h"

NSString *MSIDErrorDescriptionKey = @"MSIDErrorDescriptionKey";
NSString *MSIDOAuthErrorKey = @"MSIDOAuthErrorKey";
NSString *MSIDOAuthSubErrorKey = @"MSIDOAuthSubErrorKey";
NSString *MSIDCorrelationIdKey = @"MSIDCorrelationIdKey";
NSString *MSIDHTTPHeadersKey = @"MSIDHTTPHeadersKey";
NSString *MSIDHTTPResponseCodeKey = @"MSIDHTTPResponseCodeKey";
NSString *MSIDDeclinedScopesKey = @"MSIDDeclinedScopesKey";
NSString *MSIDGrantedScopesKey = @"MSIDGrantedScopesKey";
NSString *MSIDUserDisplayableIdkey = @"MSIDUserDisplayableIdkey";
NSString *MSIDHomeAccountIdkey = @"MSIDHomeAccountIdkey";
NSString *MSIDBrokerVersionKey = @"MSIDBrokerVersionKey";
NSString *MSIDServerUnavailableStatusKey = @"MSIDServerUnavailableStatusKey";

NSString *MSIDErrorDomain = @"MSIDErrorDomain";
NSString *MSIDOAuthErrorDomain = @"MSIDOAuthErrorDomain";
NSString *MSIDKeychainErrorDomain = @"MSIDKeychainErrorDomain";
NSString *MSIDHttpErrorCodeDomain = @"MSIDHttpErrorCodeDomain";
NSString *MSIDInvalidTokenResultKey = @"MSIDInvalidTokenResultKey";

NSError *MSIDCreateError(NSString *domain, NSInteger code, NSString *errorDescription, NSString *oauthError, NSString *subError, NSError *underlyingError, NSUUID *correlationId, NSDictionary *additionalUserInfo, BOOL logErrorDescription)
{
    id<MSIDErrorConverting> errorConverter = MSIDErrorConverter.errorConverter;

    if (!errorConverter)
    {
        errorConverter = MSIDErrorConverter.defaultErrorConverter;
    }
    
    if (logErrorDescription)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, correlationId, @"Creating Error with description: %@", errorDescription);
    }

    return [errorConverter errorWithDomain:domain
                                      code:code
                          errorDescription:errorDescription
                                oauthError:oauthError
                                  subError:subError
                           underlyingError:underlyingError
                             correlationId:correlationId
                                  userInfo:additionalUserInfo];
}

MSIDErrorCode MSIDErrorCodeForOAuthError(NSString *oauthError, MSIDErrorCode defaultCode)
{
    if (oauthError && [oauthError caseInsensitiveCompare:@"invalid_request"] == NSOrderedSame)
    {
        return MSIDErrorServerInvalidRequest;
    }
    if (oauthError && [oauthError caseInsensitiveCompare:@"invalid_client"] == NSOrderedSame)
    {
        return MSIDErrorServerInvalidClient;
    }
    if (oauthError && [oauthError caseInsensitiveCompare:@"invalid_scope"] == NSOrderedSame)
    {
        return MSIDErrorServerInvalidScope;
    }
    if (oauthError && [oauthError caseInsensitiveCompare:@"invalid_grant"] == NSOrderedSame)
    {
        return MSIDErrorServerInvalidGrant;
    }
    if (oauthError && [oauthError caseInsensitiveCompare:@"unauthorized_client"] == NSOrderedSame)
    {
        return MSIDErrorServerUnauthorizedClient;
    }
    
    return defaultCode;
}

NSDictionary* MSIDErrorDomainsAndCodes()
{
    return @{ MSIDErrorDomain : @[// General Errors
                      @(MSIDErrorInternal),
                      @(MSIDErrorInvalidInternalParameter),
                      @(MSIDErrorInvalidDeveloperParameter),
                      @(MSIDErrorMissingAccountParameter),
                      @(MSIDErrorUnsupportedFunctionality),
                      @(MSIDErrorInteractionRequired),
                      @(MSIDErrorServerNonHttpsRedirect),
                      @(MSIDErrorMismatchedAccount),
                      
                      // Cache Errors
                      @(MSIDErrorCacheMultipleUsers),
                      @(MSIDErrorCacheBadFormat),
                      
                      // Authority Validation Errors
                      @(MSIDErrorAuthorityValidation),
                      
                      // Interactive flow errors
                      @(MSIDErrorUserCancel),
                      @(MSIDErrorSessionCanceledProgrammatically),
                      @(MSIDErrorInteractiveSessionStartFailure),
                      @(MSIDErrorInteractiveSessionAlreadyRunning),
                      @(MSIDErrorNoMainViewController),
                      @(MSIDErrorAttemptToOpenURLFromExtension),
                      @(MSIDErrorUINotSupportedInExtension),

                      // Broker errors
                      @(MSIDErrorBrokerResponseNotReceived),
                      @(MSIDErrorBrokerNoResumeStateFound),
                      @(MSIDErrorBrokerBadResumeStateFound),
                      @(MSIDErrorBrokerMismatchedResumeState),
                      @(MSIDErrorBrokerResponseHashMissing),
                      @(MSIDErrorBrokerCorruptedResponse),
                      @(MSIDErrorBrokerResponseDecryptionFailed),
                      @(MSIDErrorBrokerResponseHashMismatch),
                      @(MSIDErrorBrokerKeyFailedToCreate),
                      @(MSIDErrorBrokerKeyNotFound),
                      @(MSIDErrorWorkplaceJoinRequired),
                      @(MSIDErrorBrokerUnknown),
                      @(MSIDErrorBrokerApplicationTokenWriteFailed),
                      @(MSIDErrorBrokerApplicationTokenReadFailed),

                      ],
              MSIDOAuthErrorDomain : @[// Server Errors
                      @(MSIDErrorServerOauth),
                      @(MSIDErrorServerInvalidResponse),
                      @(MSIDErrorServerRefreshTokenRejected),
                      @(MSIDErrorServerInvalidRequest),
                      @(MSIDErrorServerInvalidClient),
                      @(MSIDErrorServerInvalidGrant),
                      @(MSIDErrorServerInvalidScope),
                      @(MSIDErrorServerUnauthorizedClient),
                      @(MSIDErrorServerDeclinedScopes),
                      @(MSIDErrorServerInvalidState),
                      @(MSIDErrorServerProtectionPoliciesRequired),
                      @(MSIDErrorAuthorizationFailed),
                      ],
              MSIDHttpErrorCodeDomain : @[
                      @(MSIDErrorServerUnhandledResponse)
                      ]

              // TODO: add new codes here
              };
}

void MSIDFillAndLogError(NSError **error, MSIDErrorCode errorCode, NSString *errorDescription, NSUUID *correlationID)
{
    if (error)
    {
        *error = MSIDCreateError(MSIDErrorDomain, errorCode, errorDescription, nil, nil, nil, correlationID, nil, NO);
    }

    MSID_LOG_WITH_CORR_PII(MSIDLogLevelError, correlationID, @"Encountered error with code %ld, description %@", (long)errorCode, MSID_PII_LOG_MASKABLE(errorDescription));
}
