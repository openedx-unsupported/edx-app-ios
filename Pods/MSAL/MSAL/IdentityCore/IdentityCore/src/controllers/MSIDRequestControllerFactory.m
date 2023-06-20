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

#import "MSIDRequestControllerFactory.h"
#import "MSIDInteractiveTokenRequestParameters.h"
#import "MSIDLocalInteractiveController.h"
#import "MSIDSilentController.h"
#if TARGET_OS_IPHONE
#import "MSIDAppExtensionUtil.h"
#import "MSIDBrokerInteractiveController.h"
#endif
#import "MSIDSSOExtensionSilentTokenRequestController.h"
#import "MSIDSSOExtensionSignoutController.h"
#import "MSIDSSOExtensionInteractiveTokenRequestController.h"
#import "MSIDRequestParameters+Broker.h"
#import "MSIDAuthority.h"
#import "MSIDSignoutController.h"

@implementation MSIDRequestControllerFactory

+ (nullable id<MSIDRequestControlling>)silentControllerForParameters:(MSIDRequestParameters *)parameters
                                                        forceRefresh:(BOOL)forceRefresh
                                                tokenRequestProvider:(id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                               error:(NSError **)error
{
    MSIDSilentController *brokerController;
    
    if ([parameters shouldUseBroker])
    {
        if (@available(iOS 13.0, macOS 10.15, *))
        {
            if ([MSIDSSOExtensionSilentTokenRequestController canPerformRequest])
            {
                brokerController = [[MSIDSSOExtensionSilentTokenRequestController alloc] initWithRequestParameters:parameters
                                                                                                      forceRefresh:forceRefresh
                                                                                              tokenRequestProvider:tokenRequestProvider
                                                                                                             error:error];
            }
        }
    }
    
    // TODO: Performance optimization: check account source.
    // if (parameters.accountIdentifier.source == BROKER) return brokerController;
    
    __auto_type localController = [[MSIDSilentController alloc] initWithRequestParameters:parameters
                                                                             forceRefresh:forceRefresh
                                                                     tokenRequestProvider:tokenRequestProvider
                                                            fallbackInteractiveController:brokerController
                                                                                    error:error];
    if (!localController) return nil;
    
    return localController;
}

+ (nullable id<MSIDRequestControlling>)interactiveControllerForParameters:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                                     tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                                    error:(NSError * _Nullable * _Nullable)error
{
    id<MSIDRequestControlling> interactiveController = [self platformInteractiveController:parameters
                                                                      tokenRequestProvider:tokenRequestProvider
                                                                                     error:error];

    if (parameters.uiBehaviorType != MSIDUIBehaviorAutoType)
    {
        return interactiveController;
    }

    return [[MSIDSilentController alloc] initWithRequestParameters:parameters
                                                      forceRefresh:NO
                                              tokenRequestProvider:tokenRequestProvider
                                     fallbackInteractiveController:interactiveController
                                                             error:error];
}

+ (nullable id<MSIDRequestControlling>)platformInteractiveController:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                                tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                               error:(NSError * _Nullable * _Nullable)error
{
    id<MSIDRequestControlling> localController = [self localInteractiveController:parameters
                                                             tokenRequestProvider:tokenRequestProvider
                                                                            error:error];
    
    if (!localController)
    {
        return nil;
    }
    
    if ([parameters shouldUseBroker])
    {
        id<MSIDRequestControlling> brokerController = [self brokerController:parameters
                                                        tokenRequestProvider:tokenRequestProvider
                                                          fallbackController:localController
                                                                       error:error];
        
        if (brokerController)
        {
            return brokerController;
        }
    }

    return localController;
}

#if TARGET_OS_IPHONE
+ (nullable id<MSIDRequestControlling>)brokerController:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                   tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                     fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                                  error:(NSError * _Nullable * _Nullable)error
{
    MSIDBrokerInteractiveController *brokerController = nil;
    
    NSError *brokerControllerError;
    if ([MSIDBrokerInteractiveController canPerformRequest:parameters])
    {
        brokerController = [[MSIDBrokerInteractiveController alloc] initWithInteractiveRequestParameters:parameters
                                                                                    tokenRequestProvider:tokenRequestProvider
                                                                                      fallbackController:fallbackController
                                                                                                   error:&brokerControllerError];
        
        if (brokerControllerError)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Encountered an error creating broker controller %@", MSID_PII_LOG_MASKABLE(brokerControllerError));
        }
    }
    
    if (@available(iOS 13.0, *))
    {
        brokerController.sdkBrokerCapabilities = @[MSID_BROKER_SDK_SSO_EXTENSION_CAPABILITY];
    }
    
    id<MSIDRequestControlling> ssoExtensionController = [self ssoExtensionInteractiveController:parameters
                                                                           tokenRequestProvider:tokenRequestProvider
                                                                             fallbackController:brokerController
                                                                                          error:&brokerControllerError];
    
    if (ssoExtensionController)
    {
        return ssoExtensionController;
    }
    
    if (brokerControllerError)
    {
        if (error) *error = brokerControllerError;
        return nil;
    }
    else if (brokerController)
    {
        return brokerController;
    }
    
    return nil;
}
#else
+ (nullable id<MSIDRequestControlling>)brokerController:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                   tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                     fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                                  error:(NSError * _Nullable * _Nullable)error
{
    return [self ssoExtensionInteractiveController:parameters
                              tokenRequestProvider:tokenRequestProvider
                                fallbackController:fallbackController
                                             error:error];
}
#endif

+ (nullable id<MSIDRequestControlling>)ssoExtensionInteractiveController:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                                    tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                      fallbackController:(nullable id<MSIDRequestControlling>)fallbackController
                                                                   error:(NSError * _Nullable * _Nullable)error
{
    if (@available(iOS 13.0, macOS 10.15, *))
    {
        if ([MSIDSSOExtensionInteractiveTokenRequestController canPerformRequest])
        {
            return [[MSIDSSOExtensionInteractiveTokenRequestController alloc] initWithInteractiveRequestParameters:parameters
                                                                                              tokenRequestProvider:tokenRequestProvider
                                                                                                fallbackController:fallbackController
                                                                                                             error:error];
        }
    }
    
    return nil;
}


+ (nullable id<MSIDRequestControlling>)localInteractiveController:(nonnull MSIDInteractiveTokenRequestParameters *)parameters
                                             tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                            error:(NSError * _Nullable * _Nullable)error
{
#if TARGET_OS_IPHONE
    if ([MSIDAppExtensionUtil isExecutingInAppExtension]
        && !(parameters.webviewType == MSIDWebviewTypeWKWebView && parameters.customWebview))
    {
        // If developer provides us an custom webview, we should be able to use it for authentication in app extension
        BOOL hasSupportedEmbeddedWebView = parameters.webviewType == MSIDWebviewTypeWKWebView && parameters.customWebview;
        BOOL hasSupportedSystemWebView = parameters.webviewType == MSIDWebviewTypeSafariViewController && parameters.parentViewController;
        
        if (!hasSupportedEmbeddedWebView && !hasSupportedSystemWebView)
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorUINotSupportedInExtension, @"Interaction is not supported in an app extension.", nil, nil, nil, parameters.correlationId, nil, YES);
            }
            
            return nil;
        }
    }
#endif
    
    return [[MSIDLocalInteractiveController alloc] initWithInteractiveRequestParameters:parameters
                                                                   tokenRequestProvider:tokenRequestProvider
                                                                                  error:error];
}

+ (nullable MSIDSignoutController *)signoutControllerForParameters:(MSIDInteractiveRequestParameters *)parameters
                                                      oauthFactory:(MSIDOauth2Factory *)oauthFactory
                                          shouldSignoutFromBrowser:(BOOL)shouldSignoutFromBrowser
                                                 shouldWipeAccount:(BOOL)shouldWipeAccount
                                     shouldWipeCacheForAllAccounts:(BOOL)shouldWipeCacheForAllAccounts
                                                             error:(NSError **)error
{
    if ([parameters shouldUseBroker])
    {
        if (@available(iOS 13.0, macos 10.15, *))
        {
            if ([MSIDSSOExtensionSignoutController canPerformRequest])
            {
                return [[MSIDSSOExtensionSignoutController alloc] initWithRequestParameters:parameters
                                                                   shouldSignoutFromBrowser:shouldSignoutFromBrowser
                                                                          shouldWipeAccount:shouldWipeAccount
                                                              shouldWipeCacheForAllAccounts:shouldWipeCacheForAllAccounts
                                                                               oauthFactory:oauthFactory
                                                                                      error:error];
            }
        }
    }
    
    return [[MSIDSignoutController alloc] initWithRequestParameters:parameters
                                           shouldSignoutFromBrowser:shouldSignoutFromBrowser
                                                       oauthFactory:oauthFactory
                                                              error:error];
}

@end
