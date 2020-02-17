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

#import "MSIDConfiguration.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDPkce.h"
#import "MSIDAuthority.h"

@interface MSIDConfiguration()

@property (readwrite) NSString *resource;
@property (readwrite) NSString *target;
@property (readwrite) NSOrderedSet<NSString *> *scopes;

@end

@implementation MSIDConfiguration

- (instancetype)copyWithZone:(NSZone*)zone
{
    MSIDConfiguration *configuration = [[MSIDConfiguration allocWithZone:zone] init];
    configuration.authority = [_authority copyWithZone:zone];
    configuration.redirectUri = [_redirectUri copyWithZone:zone];
    configuration.target = [_target copyWithZone:zone];
    configuration.clientId = [_clientId copyWithZone:zone];
    configuration.resource = [_resource copyWithZone:zone];
    configuration.scopes = [_scopes copyWithZone:zone];
    configuration.applicationIdentifier = [_applicationIdentifier copyWithZone:zone];
    return configuration;
}


- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                           target:(NSString *)target
{
    self = [super init];
    
    if (self)
    {
        _authority = authority;
        _redirectUri = redirectUri;
        _clientId = clientId;
        _target = target;
        
        if (target)
        {
            _resource = target;
            _scopes = [target msidScopeSet];
        }
    }
    
    return self;
}

- (instancetype)initWithAuthority:(MSIDAuthority *)authority
                      redirectUri:(NSString *)redirectUri
                         clientId:(NSString *)clientId
                         resource:(NSString *)resource
                           scopes:(NSOrderedSet<NSString *> *)scopes
{
    self = [super init];
    
    if (self)
    {
        _authority = authority;
        _redirectUri = redirectUri;
        _clientId = clientId;
        _resource = resource;
        _scopes = scopes;
        _target = _scopes ? [scopes msidToString] : _resource;
    }
    
    return self;
}

@end
