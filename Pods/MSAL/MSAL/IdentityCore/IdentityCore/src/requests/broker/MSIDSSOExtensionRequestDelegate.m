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

#if MSID_ENABLE_SSO_EXTENSION
#import "MSIDSSOExtensionRequestDelegate.h"
#import "MSIDSSOExtensionRequestDelegate+Internal.h"
#import "MSIDJsonSerializer.h"
#import "MSIDError.h"

@implementation MSIDSSOExtensionRequestDelegate

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _jsonSerializer = [MSIDJsonSerializer new];
    }
    
    return self;
}

#pragma mark - ASAuthorizationControllerDelegate

- (void)authorizationController:(__unused ASAuthorizationController *)controller didCompleteWithAuthorization:(__unused ASAuthorization *)authorization
{
    NSAssert(NO, @"Abstract method. Should be implemented in a subclass");
}

 - (void)authorizationController:(__unused ASAuthorizationController *)controller didCompleteWithError:(NSError *)error
 {
     MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, self.context, @"Received error from SSO extension: %@", MSID_PII_LOG_MASKABLE(error));
     
     assert(self.completionBlock);
     if (!self.completionBlock) return;
     
     NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
     
     BOOL isSSOExtensionError = [error.domain isEqualToString:ASAuthorizationErrorDomain];
     BOOL isSSOExtensionInteractionRequiredError = NO;
     
 #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 150000 || __MAC_OS_X_VERSION_MAX_ALLOWED >= 120000
     if (@available(iOS 15.0, macOS 12.0, *))
     {
         isSSOExtensionInteractionRequiredError = isSSOExtensionError && error.code == ASAuthorizationErrorNotInteractive;
     }
 #endif
     
     if (isSSOExtensionError && error.code == MSIDSSOExtensionUnderlyingError)
     {
         if (underlyingError)
         {
             self.completionBlock(nil, underlyingError);
         }
         else
         {
             NSError *unexpectedError = MSIDCreateError(MSIDErrorDomain, MSIDErrorBrokerCorruptedResponse, @"SSO extension returned corrupted error. Please upload Microsoft Authenticator logs to investigate.", nil, nil, nil, nil, nil, YES);
             self.completionBlock(nil, unexpectedError);
         }
     }
     else if (isSSOExtensionError && error.code == ASAuthorizationErrorCanceled)
     {
         NSError *cancelledError = MSIDCreateError(MSIDErrorDomain, MSIDErrorUserCancel, @"SSO extension authorization was canceled", nil, nil, nil, nil, nil, YES);
         self.completionBlock(nil, cancelledError);
     }
     else if (isSSOExtensionInteractionRequiredError)
     {
         NSError *interactionRequiredError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInteractionRequired, @"SSO extension authorization requires interaction", nil, nil, nil, nil, nil, YES);
         self.completionBlock(nil, interactionRequiredError);
     }
     else
     {
         self.completionBlock(nil, error);
     }
 }

#pragma mark - Protected

- (ASAuthorizationSingleSignOnCredential *)ssoCredentialFromCredential:(id <ASAuthorizationCredential>)credential
                                                                 error:(NSError **)error
{
    if (![credential isKindOfClass:ASAuthorizationSingleSignOnCredential.class])
    {
        NSString *message = [NSString stringWithFormat:@"Received %@ credential, which doesn't subclass ASAuthorizationSingleSignOnCredential", credential.class];
        
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, self.context, @"%@", message);
        
        if (error) *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorBrokerCorruptedResponse, message, nil, nil, nil, self.context.correlationId, nil, YES);
        
        return nil;
    }
    
    return (ASAuthorizationSingleSignOnCredential *)credential;
}

- (NSDictionary *)jsonPayloadFromSSOCredential:(ASAuthorizationSingleSignOnCredential *)ssoCredential
                                         error:(__unused NSError **)error
{
    return ssoCredential.authenticatedResponse.allHeaderFields;
}

@end
#endif
