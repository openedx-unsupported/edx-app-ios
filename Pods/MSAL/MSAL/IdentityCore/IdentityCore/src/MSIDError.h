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

extern NSString * _Nonnull MSIDErrorDescriptionKey;
extern NSString * _Nonnull MSIDOAuthErrorKey;
extern NSString * _Nonnull MSIDOAuthSubErrorKey;
extern NSString * _Nonnull MSIDCorrelationIdKey;
extern NSString * _Nonnull MSIDHTTPHeadersKey;
extern NSString * _Nonnull MSIDHTTPResponseCodeKey;
extern NSString * _Nonnull MSIDUserDisplayableIdkey;
extern NSString * _Nonnull MSIDHomeAccountIdkey;
extern NSString * _Nonnull MSIDBrokerVersionKey;

/*!
 ADAL and MSID use different error domains and error codes.
 When extracting shared code to common core, we unify those error domains
 and error codes to be MSID error domains/codes and list them below. Besides,
 domain mapping and error code mapping should be added to ADAuthenticationErrorConverter
 and MSIDErrorConveter in corresponding project.
 */
extern NSString * _Nonnull MSIDErrorDomain;
extern NSString * _Nonnull MSIDOAuthErrorDomain;
extern NSString * _Nonnull MSIDKeychainErrorDomain;
extern NSString * _Nonnull MSIDHttpErrorCodeDomain;

extern NSExceptionName const _Nonnull MSIDGenericException;

/*!
 List of scopes that were requested from MSAL, but not granted in the response.

 This can happen in multiple cases:

 * Requested scope is not supported
 * Requested scope is not Recognized (According to OIDC, any scope values used that are not understood by an implementation SHOULD be ignored.)
 * Requested scope is not supported for a particular account (Organizational scopes when it is a consumer account)

 */
extern NSString * _Nonnull MSIDDeclinedScopesKey;

/*!
 List of granted scopes in case some scopes weren't granted (see MSALDeclinedScopesKey for more info)
 */
extern NSString * _Nonnull MSIDGrantedScopesKey;

/*!
 This flag will be set if server is unavailable
 */
extern NSString * _Nonnull MSIDServerUnavailableStatusKey;

/*!
 This flag will be set if we received a valid token response, but returned data mismatched.
 */
extern NSString * _Nonnull MSIDInvalidTokenResultKey;

/*!
 SSO extension failed with underlying error.
 This error defined under ASAuthorizationErrorDomain.
 */
extern NSInteger const MSIDSSOExtensionUnderlyingError;

typedef NS_ENUM(NSInteger, MSIDErrorCode)
{
    /*!
     ====================================================
     General Errors (510xx, 511xx) - MSIDErrorDomain
     ====================================================
     */
    // General internal errors that do not fall into one of the specific type
    // of an error described below.
    MSIDErrorInternal = -51100,
    
    // Parameter errors
    MSIDErrorInvalidInternalParameter   = -51111,
    MSIDErrorInvalidDeveloperParameter  = -51112,
    MSIDErrorMissingAccountParameter    = -51113,
   
    // Unsupported functionality
    MSIDErrorUnsupportedFunctionality   = -51114,

    // Interaction Required
    MSIDErrorInteractionRequired        = -51115,

    // Redirect to non HTTPS detected
    MSIDErrorServerNonHttpsRedirect     = -51116,

    // Different account returned
    MSIDErrorMismatchedAccount          = -51117,
    
    MSIDErrorRedirectSchemeNotRegistered = -51118,

    /*!
    =========================================================
     Cache Errors   (512xx) - MSIDErrorDomain
    =========================================================
     */

    // Multiple users found in cache when one was intended
    MSIDErrorCacheMultipleUsers     = -51200,
    MSIDErrorCacheBadFormat         = -51201,
    
    /*!
     =========================================================
     Server errors  (514xx) - MSIDOAuthErrorDomain
     =========================================================
     */
    
    // Server returned a response indicating an OAuth error
    MSIDErrorServerOauth                = -51400,
    // Server returned an invalid response
    MSIDErrorServerInvalidResponse      = -51401,
    // Server returned a refresh token reject response
    MSIDErrorServerRefreshTokenRejected = -514102,
    // Other specific server response errors
    
    MSIDErrorServerInvalidRequest       = -51410,
    MSIDErrorServerInvalidClient        = -51411,
    MSIDErrorServerInvalidGrant         = -51412,
    MSIDErrorServerInvalidScope         = -51413,
    MSIDErrorServerUnauthorizedClient   = -51414,
    MSIDErrorServerDeclinedScopes       = -51415,
    MSIDErrorServerAccessDenied         = -51416,
    
    // State verification has failed
    MSIDErrorServerInvalidState         = -51420,

    // Intune Protection Policies Required
    MSIDErrorServerProtectionPoliciesRequired = -51430,

    // The user or application failed to authenticate in the interactive flow.
    // Inspect MSALOAuthErrorKey and MSALErrorDescriptionKey in the userInfo
    // dictionary for more detailed information about the specific error.
    MSIDErrorAuthorizationFailed        = -51440,

    /*!
     =========================================================
     HTTP Errors  (515xx) - MSIDHttpErrorCodeDomain
     =========================================================
     */

    MSIDErrorServerUnhandledResponse    = -51500,
    
    /*!
     =========================================================
     Authority Validation  (516xx) - MSIDErrorDomain
     =========================================================
     */
    // Authority validation response failure
    MSIDErrorAuthorityValidation            = -51600,

    /*!
     =========================================================
     Interactive flow errors    (517xx) - MSIDErrorDomain
     =========================================================
     */

    // User has cancelled the interactive flow.
    MSIDErrorUserCancel                 = -51700,
    
    // The interactive flow was cancelled programmatically.
    MSIDErrorSessionCanceledProgrammatically = -51701,
    
    // Interactive authentication session failed to start.
    MSIDErrorInteractiveSessionStartFailure = -51702,
    /*!
     An interactive authentication session is already running.
     Another authentication session can not be launched yet.
     */
    MSIDErrorInteractiveSessionAlreadyRunning = -51710,

    // Embedded webview has failed to find a view controller to display web contents
    MSIDErrorNoMainViewController = - 51720,

    // Attempted to open link while running inside extension
    MSIDErrorAttemptToOpenURLFromExtension = -51730,

    // Tried to open local UI in app extension
    MSIDErrorUINotSupportedInExtension  = -51731,

    /*!
     =========================================================
     Broker flow errors    (518xx and 519xx) - MSIDErrorDomain
     =========================================================
     */

    // Broker response was not received
    MSIDErrorBrokerResponseNotReceived  =   -51800,

    // Resume state was not found in data store, app might have deleted it
    MSIDErrorBrokerNoResumeStateFound   =   -51801,

    // Resume state found in datastore but has some fields missing
    MSIDErrorBrokerBadResumeStateFound  =   -51802,

    // Resume state found in datastore but it doesn't match the response being handled
    MSIDErrorBrokerMismatchedResumeState  =   -51803,

    // Has missing in the broker response
    MSIDErrorBrokerResponseHashMissing  =   -51804,

    // Valid broker response not present
    MSIDErrorBrokerCorruptedResponse    =   -51805,

    // Failed to decrypt broker response
    MSIDErrorBrokerResponseDecryptionFailed     =   -51806,

    // Broker hash mismatched in result after decryption
    MSIDErrorBrokerResponseHashMismatch     =   -51807,

    // Failed to create broker encryption key
    MSIDErrorBrokerKeyFailedToCreate     =   -51808,

    // Couldn't read broker key
    MSIDErrorBrokerKeyNotFound     =   -51809,

    // Workplace join is required to proceed
    MSIDErrorWorkplaceJoinRequired  =   -51810,

    // Unknown broker error returned
    MSIDErrorBrokerUnknown  =   -51811,
    
    // Failed to save broker application token
    MSIDErrorBrokerApplicationTokenWriteFailed     =   -51812,
    
    MSIDErrorBrokerApplicationTokenReadFailed      =   -51813,
    
    MSIDErrorBrokerNotAvailable                    =   -51814,
    
    // SSO Extension internal error
    MSIDErrorSSOExtensionUnexpectedError           =   -51815,
    
    // JIT - Link - Timeout while waiting for server confirmation
    MSIDErrorJITLinkServerConfirmationTimeout      =   -51816,
    
    // JIT - Link - Error while waiting for server confirmation
    MSIDErrorJITLinkServerConfirmationError        =   -51817,
    
    // JIT - Link - Error while acquiring intune token
    MSIDErrorJITLinkAcquireTokenError              =   -51818,
    
    // JIT - Link - Token acquired for wrong tenant
    MSIDErrorJITLinkTokenAcquiredWrongTenant       =   -51819,
    
    // JIT - Link - Error during linking
    MSIDErrorJITLinkError                          =   -51820,
    
    // JIT - Compliance Check - Device not compliant
    MSIDErrorJITComplianceCheckResultNotCompliant  =   -51821,
    
    // JIT - Compliance Check - CP timeout
    MSIDErrorJITComplianceCheckResultTimeout       =   -51822,
    
    // JIT - Compliance Check - Device unknown
    MSIDErrorJITComplianceCheckResultUnknown       =   -51823,
    
    // Throttling errors
    MSIDErrorThrottleCacheNoRecord = -51900,
    MSIDErrorThrottleCacheInvalidSignature = -51901,

};

extern NSError * _Nonnull MSIDCreateError(NSString * _Nonnull domain, NSInteger code, NSString * _Nullable errorDescription, NSString * _Nullable oauthError, NSString * _Nullable subError, NSError * _Nullable underlyingError, NSUUID * _Nullable correlationId, NSDictionary * _Nullable additionalUserInfo, BOOL logErrorDescription);

extern MSIDErrorCode MSIDErrorCodeForOAuthError(NSString * _Nullable oauthError, MSIDErrorCode defaultCode);

extern NSDictionary<NSString *, NSArray *> * _Nonnull MSIDErrorDomainsAndCodes(void);

extern void MSIDFillAndLogError(NSError * _Nullable __autoreleasing * _Nullable error, MSIDErrorCode errorCode, NSString * _Nullable errorDescription, NSUUID * _Nullable correlationID);

#define MSIDException(name, message, info) [NSException exceptionWithName:name reason:[NSString stringWithFormat:@"%@ (function:%s line:%i)", message, __PRETTY_FUNCTION__, __LINE__]  userInfo:info]
