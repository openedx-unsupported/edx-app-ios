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

#import "MSIDAADRefreshTokenGrantRequest.h"
#import "MSIDAADRequestConfigurator.h"
#import "MSIDThumbprintCalculator.h"

@interface MSIDAADRefreshTokenGrantRequest ()

@property (nonatomic) NSMutableDictionary *thumbprintParameters;

@end

@implementation MSIDAADRefreshTokenGrantRequest

- (instancetype)initWithEndpoint:(NSURL *)endpoint
                      authScheme:(MSIDAuthenticationScheme *)authScheme
                        clientId:(NSString *)clientId
                     redirectUri:(NSString *)redirectUri
                    enrollmentId:(NSString *)enrollmentId
                           scope:(NSString *)scope
                    refreshToken:(NSString *)refreshToken
                          claims:(NSString *)claims
                 extraParameters:(NSDictionary *)extraParameters
                         context:(nullable id<MSIDRequestContext>)context
{
    self = [super initWithEndpoint:endpoint authScheme:authScheme clientId:clientId scope:scope refreshToken:refreshToken redirectUri:redirectUri extraParameters:extraParameters context:context];
    if (self)
    {
        __auto_type requestConfigurator = [MSIDAADRequestConfigurator new];
        [requestConfigurator configure:self];
        
        NSMutableDictionary *parameters = [_parameters mutableCopy];
        parameters[MSID_OAUTH2_CLIENT_INFO] = @YES;
        parameters[MSID_OAUTH2_CLAIMS] = claims;
        parameters[MSID_ENROLLMENT_ID] = enrollmentId;
        
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

@end

#endif
