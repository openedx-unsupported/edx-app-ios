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
#import "MSIDSSOExtensionTokenRequestDelegate.h"
#import "MSIDSSOExtensionRequestDelegate+Internal.h"
#import "MSIDBrokerOperationTokenResponse.h"
#import "MSIDJsonSerializableFactory.h"

@implementation MSIDSSOExtensionTokenRequestDelegate

- (void)authorizationController:(__unused ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, self.context, @"Receive response from SSO extension with authorization is nil: %@", authorization ? @"No" : @"Yes");
    
    if (!self.completionBlock) return;
    MSIDSSOExtensionRequestDelegateCompletionBlock completionBlockWrapper = ^(id response, NSError  *error)
    {
        // 2 scenarios return MSIDErrorSSOExtensionUnexpectedError:
        // 1. both response and either is nil (wrong callback is returned)
        // 2. error when parsing data => This should be treated as internal (suberror)
        if (!response)
        {
            NSError *wrapperError = MSIDCreateError(MSIDErrorDomain, MSIDErrorSSOExtensionUnexpectedError, @"Unexpected internal error from SSO", nil, error ? @"data parsing error" : nil, error ? error : nil, nil, nil, NO);
            self.completionBlock(nil, wrapperError);
        }
        else
        {
            self.completionBlock(response, error);
        }
    };
    
    NSError *error;
    __auto_type ssoCredential = [self ssoCredentialFromCredential:authorization.credential error:&error];
    if (!ssoCredential)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.context, @"ssoCredential is nill, error %@", error);
        completionBlockWrapper(nil, error);
        return;
    }
    
    __auto_type json = [self jsonPayloadFromSSOCredential:ssoCredential error:&error];
    if (!json)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.context, @"ssoCredential header is nill, error %@", error);
        completionBlockWrapper(nil, error);
        return;
    }
    
    __auto_type operationResponse = (MSIDBrokerOperationTokenResponse *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_BROKER_OPERATION_RESPONSE_TYPE_JSON_KEY assertKindOfClass:MSIDBrokerOperationTokenResponse.class error:&error];

    if (!operationResponse)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, self.context, @"operationResponse is nill, error %@", error);
        completionBlockWrapper(nil, error);
        return;
    }
    
    completionBlockWrapper(operationResponse, nil);
}

@end
#endif
