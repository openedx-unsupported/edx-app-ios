//
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

#import "MSIDSSOExtensionGetSsoCookiesRequest.h"
#import "MSIDBrokerOperationGetSsoCookiesRequest.h"
#import "MSIDBrokerOperationGetSsoCookiesResponse.h"
#import "MSIDSSOExtensionGetDataBaseRequest+Internal.h"

@interface MSIDSSOExtensionGetSsoCookiesRequest()

@property (nonatomic, copy) MSIDGetSsoCookiesRequestCompletionBlock requestCompletionBlock;

@end

@implementation MSIDSSOExtensionGetSsoCookiesRequest

- (instancetype)initWithRequestParameters:(MSIDRequestParameters *)requestParameters
                            headerTypes:(NSArray<NSNumber *>*)headerTypes
                        accountIdentifier:(MSIDAccountIdentifier *)accountIdentifier
                                   ssoUrl:(NSString *)ssoUrl
                            correlationId:(NSUUID *)correlationId
                                    error:(NSError **)error{
    self = [super initWithRequestParameters:requestParameters error:error];
    if (self)
    {
        _accountIdentifier = accountIdentifier;
        _ssoUrl = ssoUrl;
        _correlationId = correlationId;
        _types = [headerTypes componentsJoinedByString:@", "];
        
        __typeof__(self) __weak weakSelf = self;
        self.extensionDelegate.completionBlock = ^(MSIDBrokerNativeAppOperationResponse *operationResponse, NSError *resultError)
        {
            __strong __typeof__(self) strongSelf = weakSelf;
            NSArray *prtHeaders = nil;
            NSArray *deviceHeaders = nil;
            
            if (!operationResponse.success)
            {
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, requestParameters, @"Finished get sso cookies request with error %@", MSID_PII_LOG_MASKABLE(resultError));
            }
            else if (![operationResponse isKindOfClass:[MSIDBrokerOperationGetSsoCookiesResponse class]])
            {
                resultError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Received incorrect response type for the get sso cookies request", nil, nil, nil, nil, nil, YES);
            }
            else
            {
                MSIDBrokerOperationGetSsoCookiesResponse *response = (MSIDBrokerOperationGetSsoCookiesResponse *)operationResponse;
                prtHeaders = response.prtHeaders;
                deviceHeaders = response.deviceHeaders;
            }
            
            MSIDGetSsoCookiesRequestCompletionBlock completionBlock = strongSelf.requestCompletionBlock;
            strongSelf.requestCompletionBlock = nil;
            
            if (completionBlock) completionBlock(prtHeaders, deviceHeaders, resultError);
        };
        
        self.ssoProvider = [ASAuthorizationSingleSignOnProvider msidSharedProvider];
    }
    
    return self;
}

- (void)executeRequestWithCompletion:(MSIDGetSsoCookiesRequestCompletionBlock)completionBlock
{
    MSIDBrokerOperationGetSsoCookiesRequest *getSsoCookiesRequest = [MSIDBrokerOperationGetSsoCookiesRequest new];
    getSsoCookiesRequest.accountIdentifier = self.accountIdentifier;
    getSsoCookiesRequest.ssoUrl = self.ssoUrl;
    getSsoCookiesRequest.correlationId = self.correlationId ?: [NSUUID UUID];
    getSsoCookiesRequest.headerTypes = self.types;
    self.requestCompletionBlock = completionBlock;
    [self executeBrokerOperationRequest:getSsoCookiesRequest requiresUI:NO errorBlock:^(NSError *error) {
        if(completionBlock) completionBlock(nil, nil, error);
    }];
}

@end
