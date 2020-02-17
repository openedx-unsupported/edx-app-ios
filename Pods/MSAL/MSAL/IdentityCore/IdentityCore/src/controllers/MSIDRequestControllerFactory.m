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
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDLocalInteractiveController.h"
#import "MSIDSilentController.h"
#if TARGET_OS_IPHONE
#import "MSIDAppExtensionUtil.h"
#import "MSIDBrokerInteractiveController.h"
#endif
#import "MSIDAuthority.h"

@implementation MSIDRequestControllerFactory

+ (nullable id<MSIDRequestControlling>)silentControllerForParameters:(nonnull MSIDRequestParameters *)parameters
                                                        forceRefresh:(BOOL)forceRefresh
                                                tokenRequestProvider:(nonnull id<MSIDTokenRequestProviding>)tokenRequestProvider
                                                               error:(NSError * _Nullable * _Nullable)error
{
    return [[MSIDSilentController alloc] initWithRequestParameters:parameters
                                                      forceRefresh:forceRefresh
                                              tokenRequestProvider:tokenRequestProvider
                                                             error:error];
}

+ (nullable id<MSIDRequestControlling>)interactiveControllerForParameters:(nonnull MSIDInteractiveRequestParameters *)parameters
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

+ (nullable id<MSIDRequestControlling>)platformInteractiveController:(nonnull MSIDInteractiveRequestParameters *)parameters
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
    
#if TARGET_OS_IPHONE
    if ([self canUseBrokerOnDeviceWithParameters:parameters])
    {
        BOOL brokerInstalled = [self brokerInstalledWithParameters:parameters];
        
        if (brokerInstalled)
        {
            return [[MSIDBrokerInteractiveController alloc] initWithInteractiveRequestParameters:parameters
                                                                            tokenRequestProvider:tokenRequestProvider
                                                                              fallbackController:localController
                                                                                           error:error];
        }
    }

#endif

    return localController;
}

+ (nullable id<MSIDRequestControlling>)localInteractiveController:(nonnull MSIDInteractiveRequestParameters *)parameters
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


+ (BOOL)canUseBrokerOnDeviceWithParameters:(__unused MSIDInteractiveRequestParameters *)parameters
{
#if TARGET_OS_IPHONE

    if (parameters.requestType != MSIDInteractiveRequestBrokeredType)
    {
        return NO;
    }

    if ([MSIDAppExtensionUtil isExecutingInAppExtension])
    {
        return NO;
    }

    if (!parameters.authority.supportsBrokeredAuthentication)
    {
        return NO;
    }

    if (!parameters.validateAuthority)
    {
        return NO;
    }

    return YES;
#else
    return NO;
#endif
}

+ (BOOL)brokerInstalledWithParameters:(__unused MSIDInteractiveRequestParameters *)parameters
{
#if AD_BROKER
    return YES;
#elif TARGET_OS_IPHONE

    if (![NSThread isMainThread])
    {
        __block BOOL brokerInstalled = NO;
        dispatch_sync(dispatch_get_main_queue(), ^{
            brokerInstalled = [self brokerInstalledWithParameters:parameters];
        });

        return brokerInstalled;
    }

    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, parameters, @"Checking broker install state for version %@", parameters.brokerInvocationOptions.versionDisplayableName);
    
    if (parameters.brokerInvocationOptions && parameters.brokerInvocationOptions.isRequiredBrokerPresent)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, parameters, @"Broker version %@ found installed on device", parameters.brokerInvocationOptions.versionDisplayableName);
        return YES;
    }
    
    return NO;
#else
    return NO;
#endif
}

@end
