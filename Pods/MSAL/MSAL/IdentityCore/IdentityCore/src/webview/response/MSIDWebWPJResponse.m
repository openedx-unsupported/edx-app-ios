//------------------------------------------------------------------------------
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDWebWPJResponse.h"
#import "MSIDClientInfo.h"
#import "MSIDWebResponseOperationConstants.h"
#import "MSIDWebResponseOperationFactory.h"
#import "MSIDWebResponseBrokerInstallOperation.h"

@implementation MSIDWebWPJResponse

+ (void)load
{
    [MSIDWebResponseOperationFactory registerOperationClass:MSIDWebResponseBrokerInstallOperation.class forResponseClass:self];
}

- (instancetype)initWithURL:(NSURL *)url
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    // Check for WPJ or broker response
    if (![self isBrokerInstallResponse:url])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDOAuthErrorDomain,
                                     MSIDErrorServerInvalidResponse,
                                     @"WPJ response should have msauth as a scheme and wpj/broker as a host",
                                     nil, nil, nil, context.correlationId, nil, NO);
        }
        return nil;
    }
    
    self = [super initWithURL:url context:context error:error];
    if (self)
    {
        _appInstallLink = self.parameters[@"app_link"];
        _upn = self.parameters[@"username"];
        
        NSError *localError;
        _clientInfo = [[MSIDClientInfo alloc] initWithRawClientInfo:self.parameters[@"client_info"]
                                                              error:&localError];
        
        if (localError)
        {
            MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, context, @"Failed to parse client_info, error: %@", MSID_PII_LOG_MASKABLE(localError));
        }
    }
    
    return self;
}

- (BOOL)isBrokerInstallResponse:(NSURL *)url
{
    NSString *scheme = url.scheme;
    NSString *host = url.host;
    
    // For embedded webview, this link will start with msauth scheme and will contain wpj host
    // e.g. msauth://wpj?param=param
    if ([scheme isEqualToString:@"msauth"] && [host isEqualToString:@"wpj"])
    {
        return YES;
    }
    
    NSArray *pathComponents = url.pathComponents;
    
    if ([pathComponents count] < 2)
    {
        return NO;
    }
    
    // For system webview, this link will start with the redirect uri and will have msauth and wpj as path parameters
    // e.g. myscheme://auth/msauth/wpj?param=param
    NSUInteger pathComponentCount = pathComponents.count;
    
    if ([pathComponents[pathComponentCount - 1] isEqualToString:@"wpj"]
        && [pathComponents[pathComponentCount - 2] isEqualToString:@"msauth"])
    {
        return YES;
    }
    
    return NO;
}

+ (NSString *)operation
{
    return MSID_INSTALL_BROKER_OPERATION;
}

@end
