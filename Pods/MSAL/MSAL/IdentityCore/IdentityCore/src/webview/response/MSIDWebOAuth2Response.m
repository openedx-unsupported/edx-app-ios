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

#import "MSIDWebOAuth2Response.h"
#import "NSURL+MSIDExtensions.h"

@implementation MSIDWebOAuth2Response

- (instancetype)initWithURL:(NSURL *)url
               requestState:(NSString *)requestState
         ignoreInvalidState:(BOOL)ignoreInvalidState
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    // state check
    NSError *stateCheckError = nil;

    if (![self.class verifyRequestState:requestState responseURL:url error:&stateCheckError] &&
        !ignoreInvalidState)
    {
        if (error)
        {
            *error = stateCheckError;
        }
        return nil;
    }
    
    return [self initWithURL:url context:context error:error];
}


- (instancetype)initWithURL:(NSURL *)url
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    self = [super initWithURL:url context:context error:error];
    
    if (self)
    {
        NSString *authCode = self.parameters[MSID_OAUTH2_CODE];
        NSError *oauthError = [self.class oauthErrorFromParameters:self.parameters];
        
        if ([NSString msidIsStringNilOrBlank:authCode] && !oauthError)
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDOAuthErrorDomain,
                                         MSIDErrorServerInvalidResponse,
                                         @"Unexpected error has occured. There is no auth code nor an error",
                                         nil, nil, nil, context.correlationId, nil, YES);
            }
            return nil;
        }
        
        // populate auth code
        _authorizationCode = [NSString msidIsStringNilOrBlank:authCode] ? nil : authCode;
        
        // populate oauth error
        _oauthError = oauthError;
    }
    
    return self;
}

+ (NSError *)oauthErrorFromParameters:(NSDictionary *)parameters
{
    NSUUID *correlationId = [parameters objectForKey:MSID_OAUTH2_CORRELATION_ID_RESPONSE] ?
    [[NSUUID alloc] initWithUUIDString:[parameters objectForKey:MSID_OAUTH2_CORRELATION_ID_RESPONSE]]:nil;
    
    NSString *serverOAuth2Error = [parameters objectForKey:MSID_OAUTH2_ERROR];

    if (serverOAuth2Error)
    {
        NSString *errorDescription = parameters[MSID_OAUTH2_ERROR_DESCRIPTION];
        NSString *subError = parameters[MSID_OAUTH2_SUB_ERROR];
        MSIDErrorCode errorCode = MSIDErrorCodeForOAuthError(serverOAuth2Error, MSIDErrorAuthorizationFailed);
        
        MSID_LOG_WITH_CORR_PII(MSIDLogLevelError, correlationId, @"Failed authorization code response with error %@, sub error %@, description %@", serverOAuth2Error, subError, MSID_PII_LOG_MASKABLE(errorDescription));
        
        return MSIDCreateError(MSIDOAuthErrorDomain, errorCode, errorDescription, serverOAuth2Error, subError, nil, correlationId, nil, NO);
    }
    
    return nil;
}

+ (BOOL)verifyRequestState:(NSString *)requestState
               responseURL:(NSURL *)url
                     error:(NSError **)error
{
    // Check for auth response
    // Try both the URL and the fragment parameters:
    NSDictionary *parameters = [self msidWebResponseParametersFromURL:url];
    NSString *stateReceived = parameters[MSID_OAUTH2_STATE];
    
    if (!requestState && !stateReceived)
    {
        return YES;
    }
    
    BOOL result = [requestState isEqualToString:stateReceived.msidBase64UrlDecode];
    
    if (!result)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Missing or invalid state returned state: %@", stateReceived);
        if (error)
        {
            *error = MSIDCreateError(MSIDOAuthErrorDomain,
                                     MSIDErrorServerInvalidState,
                                     [NSString stringWithFormat:@"Missing or invalid state returned state: %@", stateReceived],
                                     nil, nil, nil, nil, nil, NO);
        }
    }
    
    return result;
}

@end

