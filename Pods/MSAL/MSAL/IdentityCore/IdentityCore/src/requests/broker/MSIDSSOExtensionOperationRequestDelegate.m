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

#import "MSIDSSOExtensionOperationRequestDelegate.h"
#import "MSIDSSOExtensionRequestDelegate+Internal.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDBrokerNativeAppOperationResponse.h"

@implementation MSIDSSOExtensionOperationRequestDelegate

- (void)authorizationController:(__unused ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
{
    if (!self.completionBlock) return;
    
    NSError *error;
    __auto_type ssoCredential = [self ssoCredentialFromCredential:authorization.credential error:&error];
    if (!ssoCredential)
    {
        self.completionBlock(nil, error);
        return;
    }
    
    __auto_type json = [self jsonPayloadFromSSOCredential:ssoCredential error:&error];
    if (!json)
    {
        if (!error) error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Received unexpected response from the extension", nil, nil, nil, nil, nil, YES);
        self.completionBlock(nil, error);
        return;
    }
    
    __auto_type operationResponse = (MSIDBrokerNativeAppOperationResponse *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_BROKER_OPERATION_RESPONSE_TYPE_JSON_KEY assertKindOfClass:MSIDBrokerOperationResponse.class error:&error];

    if (!operationResponse)
    {
        self.completionBlock(nil, error);
        return;
    }
    
    self.completionBlock(operationResponse, nil);
}

@end
