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

#import "MSIDSSOTokenResponseHandler.h"
#import "MSIDBrokerOperationTokenResponse.h"
#import "MSIDRequestParameters.h"
#import "MSIDTokenResponse.h"
#import "MSIDTokenResponseValidator.h"
#import "MSIDDeviceInfo.h"

@implementation MSIDSSOTokenResponseHandler

- (void)handleOperationResponse:(MSIDBrokerOperationTokenResponse *)operationResponse
              requestParameters:(MSIDRequestParameters *)requestParameters
         tokenResponseValidator:(MSIDTokenResponseValidator *)tokenResponseValidator
                   oauthFactory:(MSIDOauth2Factory *)oauthFactory
                     tokenCache:(id<MSIDCacheAccessor>)tokenCache
           accountMetadataCache:(MSIDAccountMetadataCacheAccessor *)accountMetadataCache
                validateAccount:(BOOL)validateAccount
                          error:(NSError *)error
                completionBlock:(MSIDRequestCompletionBlock)completionBlock
{
    if (operationResponse.authority) requestParameters.cloudAuthority = operationResponse.authority;
    
    BOOL saveSSOStateOnly = operationResponse.deviceInfo.deviceMode == MSIDDeviceModeShared;
    
    if (operationResponse.additionalTokenResponse)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Saving additional token response...");
        NSError *localError;
        MSIDRequestParameters *parameters = [requestParameters copy];
        parameters.target = operationResponse.additionalTokenResponse.scope;
        
        [tokenResponseValidator validateAndSaveTokenResponse:operationResponse.additionalTokenResponse
                                                oauthFactory:oauthFactory
                                                  tokenCache:tokenCache
                                        accountMetadataCache:accountMetadataCache
                                           requestParameters:parameters
                                            saveSSOStateOnly:saveSSOStateOnly
                                                       error:&localError];
        
        if (localError)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelWarning, requestParameters, @"Failed to save additional token response, error: %@", MSID_PII_LOG_MASKABLE(localError));
        }
        else
        {
           MSID_LOG_WITH_CTX(MSIDLogLevelInfo, requestParameters, @"Saved additional token response.");
        }
    }
    
    [self handleTokenResponse:operationResponse.tokenResponse
            requestParameters:requestParameters
                homeAccountId:nil
       tokenResponseValidator:tokenResponseValidator
                 oauthFactory:oauthFactory
                   tokenCache:tokenCache
         accountMetadataCache:accountMetadataCache
              validateAccount:validateAccount
             saveSSOStateOnly:saveSSOStateOnly
                        error:error
              completionBlock:completionBlock];
}

@end
