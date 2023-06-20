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

#import "MSIDSSOExtensionGetAccountsRequest.h"
#import "MSIDRequestParameters.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "MSIDSSOExtensionOperationRequestDelegate.h"
#import "ASAuthorizationSingleSignOnProvider+MSIDExtensions.h"
#import "MSIDBrokerNativeAppOperationResponse.h"
#import "MSIDBrokerOperationGetAccountsRequest.h"
#import "NSDictionary+MSIDQueryItems.h"
#import "MSIDBrokerOperationGetAccountsResponse.h"
#import "MSIDDeviceInfo.h"
#import "ASAuthorizationController+MSIDExtensions.h"

// TODO: 1656998 This file can be refactored and use MSIDSSOExtensionGetDataBaseRequest as super class
@interface MSIDSSOExtensionGetAccountsRequest()

@property (nonatomic) ASAuthorizationController *authorizationController;
@property (nonatomic, copy) MSIDGetAccountsRequestCompletionBlock requestCompletionBlock;
@property (nonatomic) MSIDSSOExtensionOperationRequestDelegate *extensionDelegate;
@property (nonatomic) ASAuthorizationSingleSignOnProvider *ssoProvider;
@property (nonatomic) MSIDRequestParameters *requestParameters;
@property (nonatomic) BOOL returnOnlySignedInAccounts;
 
@end

@implementation MSIDSSOExtensionGetAccountsRequest

- (nullable instancetype)initWithRequestParameters:(MSIDRequestParameters *)requestParameters
                        returnOnlySignedInAccounts:(BOOL)returnOnlySignedInAccounts
                                             error:(NSError * _Nullable * _Nullable)error
{
    self = [super init];
    
    if (!requestParameters)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"Unexpected error. Nil request parameter provided", nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    if (self)
    {
        _requestParameters = requestParameters;
        _returnOnlySignedInAccounts = returnOnlySignedInAccounts;
        
        _extensionDelegate = [MSIDSSOExtensionOperationRequestDelegate new];
        _extensionDelegate.context = requestParameters;
        __typeof__(self) __weak weakSelf = self;
        _extensionDelegate.completionBlock = ^(MSIDBrokerNativeAppOperationResponse *operationResponse, NSError *resultError)
        {
            NSArray *resultAccounts = nil;
            BOOL returnBrokerAccountsOnly = NO;
            
            if (!operationResponse.success)
            {
                MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, requestParameters, @"Finished get accounts request with error %@", MSID_PII_LOG_MASKABLE(resultError));
            }
            else if (![operationResponse isKindOfClass:[MSIDBrokerOperationGetAccountsResponse class]])
            {
                resultError = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Received incorrect response type for the get accounts request", nil, nil, nil, nil, nil, YES);
            }
            else
            {
                MSIDBrokerOperationGetAccountsResponse *response = (MSIDBrokerOperationGetAccountsResponse *)operationResponse;
                resultAccounts = response.accounts;
                returnBrokerAccountsOnly = operationResponse.deviceInfo.deviceMode == MSIDDeviceModeShared;
            }
            
            __typeof__(self) strongSelf = weakSelf;
            
            MSIDGetAccountsRequestCompletionBlock completionBlock = strongSelf.requestCompletionBlock;
            strongSelf.requestCompletionBlock = nil;
            
            if (completionBlock) completionBlock(resultAccounts, returnBrokerAccountsOnly, resultError);
        };
        
        _ssoProvider = [ASAuthorizationSingleSignOnProvider msidSharedProvider];
    }
    
    return self;
}

- (void)executeRequestWithCompletion:(nonnull MSIDGetAccountsRequestCompletionBlock)completionBlock
{
    MSIDBrokerOperationGetAccountsRequest *getAccountsRequest = [MSIDBrokerOperationGetAccountsRequest new];
    getAccountsRequest.clientId = self.requestParameters.clientId;
    getAccountsRequest.returnOnlySignedInAccounts = self.returnOnlySignedInAccounts;
    // TODO: pass familyId, will be addressed in a separate PR
    // TODO: pass returnOnlySignedInAccounts == false, will be addressed in a separate PR

    NSError *error;
    ASAuthorizationSingleSignOnRequest *ssoRequest = [self.ssoProvider createSSORequestWithOperationRequest:getAccountsRequest
                                                                                          requestParameters:self.requestParameters
                                                                                                 requiresUI:NO
                                                                                                      error:&error];
    
    if (!ssoRequest)
    {
        completionBlock(nil, NO, error);
        return;
    }
        
    self.authorizationController = [self controllerWithRequest:ssoRequest];
    self.authorizationController.delegate = self.extensionDelegate;
    [self.authorizationController msidPerformRequests];
    
    self.requestCompletionBlock = completionBlock;
}

#pragma mark - AuthenticationServices

- (ASAuthorizationController *)controllerWithRequest:(ASAuthorizationSingleSignOnRequest *)ssoRequest
{
    return [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[ssoRequest]];
}

+ (BOOL)canPerformRequest
{
    return [[ASAuthorizationSingleSignOnProvider msidSharedProvider] canPerformAuthorization];
}

@end

#endif
