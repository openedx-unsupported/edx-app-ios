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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDRefreshTokenGrantRequest.h"
#import "MSIDThumbprintCalculator.h"

@interface MSIDRefreshTokenGrantRequest ()

@property (nonatomic) NSMutableDictionary *thumbprintParameters;

@end

@implementation MSIDRefreshTokenGrantRequest

- (instancetype _Nullable)initWithEndpoint:(nonnull NSURL *)endpoint
                                authScheme:(nonnull MSIDAuthenticationScheme *)authScheme
                                  clientId:(nonnull NSString *)clientId
                                     scope:(nullable NSString *)scope
                              refreshToken:(nonnull NSString *)refreshToken
                               redirectUri:(NSString *)redirectUri
                           extraParameters:(nullable NSDictionary *)extraParameters
                                   context:(nullable id<MSIDRequestContext>)context
{
    self = [super initWithEndpoint:endpoint authScheme:authScheme clientId:clientId scope:scope context:context];
    if (self)
    {
        NSParameterAssert(refreshToken);
        
        NSMutableDictionary *parameters = [_parameters mutableCopy];
        parameters[MSID_OAUTH2_GRANT_TYPE] = MSID_OAUTH2_REFRESH_TOKEN;
        parameters[MSID_OAUTH2_REFRESH_TOKEN] = refreshToken;
        parameters[MSID_OAUTH2_REDIRECT_URI] = redirectUri;
        
        if (extraParameters)
        {
            [parameters addEntriesFromDictionary:extraParameters];
        }
        
        _parameters = parameters;
        _thumbprintParameters = [_parameters mutableCopy];
        _thumbprintParameters[MSID_OAUTH2_REQUEST_ENDPOINT] = endpoint;
    }
    
    return self;
}

- (NSString *)fullRequestThumbprint
{
    return [MSIDThumbprintCalculator calculateThumbprint:self.thumbprintParameters
                                            filteringSet:[MSIDRefreshTokenGrantRequest fullRequestThumbprintExcludeParams]
                                       shouldIncludeKeys:NO];
}

- (NSString *)strictRequestThumbprint
{
    return [MSIDThumbprintCalculator calculateThumbprint:self.thumbprintParameters
                                            filteringSet:[MSIDRefreshTokenGrantRequest strictRequestThumbprintIncludeParams]
                                       shouldIncludeKeys:YES];
}

+ (NSSet *)fullRequestThumbprintExcludeParams
{
    static dispatch_once_t once_token;
    static NSSet *excludeSet;
    
    dispatch_once(&once_token, ^{
        excludeSet = [NSSet setWithArray:@[MSID_OAUTH2_GRANT_TYPE]];
    });
    return excludeSet;
    
}

+ (NSSet *)strictRequestThumbprintIncludeParams
{
    static dispatch_once_t once_token;
    static NSSet *includeSet;
    
    dispatch_once(&once_token, ^{
        includeSet = [NSSet setWithArray:@[MSID_OAUTH2_CLIENT_ID,
                                           MSID_OAUTH2_REQUEST_ENDPOINT, //resource + environment
                                           MSID_OAUTH2_REFRESH_TOKEN, //home account id also embedded within RT, albeit decrypted.
                                           MSID_OAUTH2_SCOPE]];
    });
    return includeSet;
    
}

@end

#endif
