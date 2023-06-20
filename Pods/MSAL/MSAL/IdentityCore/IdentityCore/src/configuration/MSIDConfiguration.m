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
#import "MSIDAuthorityFactory.h"
#import "MSIDJsonSerializableFactory.h"
#import "MSIDProviderType.h"
#import "MSIDAuthenticationScheme.h"

NSString *const MSID_REDIRECT_URI_JSON_KEY = @"redirect_uri";
NSString *const MSID_CLIENT_ID_JSON_KEY = @"client_id";
NSString *const MSID_SCOPE_JSON_KEY = @"scope";
NSString *const MSID_TOKEN_TYPE_JSON_KEY = @"token_type";

@interface MSIDConfiguration()

@property (atomic, readwrite) NSString *resource;
@property (atomic, readwrite) NSString *target;
@property (atomic, readwrite) NSOrderedSet<NSString *> *scopes;

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
    configuration.authScheme = [_authScheme copyWithZone:zone];
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
        
        _authScheme = [MSIDAuthenticationScheme new];
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
        _authScheme = [MSIDAuthenticationScheme new];
    }
    
    return self;
}

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    MSIDAuthority *authority = (MSIDAuthority *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_PROVIDER_TYPE_JSON_KEY assertKindOfClass:MSIDAuthority.class error:error];
    if (!authority) return nil;

    if (![json msidAssertType:NSString.class ofKey:MSID_REDIRECT_URI_JSON_KEY required:YES error:error]) return nil;
    NSString *redirectUri = [json msidStringObjectForKey:MSID_REDIRECT_URI_JSON_KEY];

    if (![json msidAssertType:NSString.class ofKey:MSID_CLIENT_ID_JSON_KEY required:YES error:error]) return nil;
    NSString *clientId = json[MSID_CLIENT_ID_JSON_KEY];

    if (![json msidAssertType:NSString.class ofKey:MSID_SCOPE_JSON_KEY required:NO error:error]) return nil;
    NSString *target = [json msidStringObjectForKey:MSID_SCOPE_JSON_KEY];
    
    MSIDConfiguration *config = [self initWithAuthority:authority redirectUri:redirectUri clientId:clientId target:target];
    
    /*
     We pass error as nil in auth scheme creation as token_type key will only be added for MSIDAuthenticationSchemePop.
     */
    MSIDAuthenticationScheme *authScheme = (MSIDAuthenticationScheme *)[MSIDJsonSerializableFactory createFromJSONDictionary:json classTypeJSONKey:MSID_TOKEN_TYPE_JSON_KEY assertKindOfClass:MSIDAuthenticationScheme.class error:nil];
    if (authScheme) config.authScheme = authScheme;
    
    return config;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [NSMutableDictionary new];

    NSDictionary *authorityJson = [self.authority jsonDictionary];
    if (!authorityJson)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, authority json is nil.", self.class);
        return nil;
    }
    [json addEntriesFromDictionary:authorityJson];
    
    if (!self.clientId)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, clientId is nil.", self.class);
        return nil;
    }
    json[MSID_CLIENT_ID_JSON_KEY] = self.clientId;
    
    if (!self.redirectUri)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, redirectUri is nil.", self.class);
        return nil;
    }
    json[MSID_REDIRECT_URI_JSON_KEY] = self.redirectUri;
    json[MSID_SCOPE_JSON_KEY] = self.target;
    
    NSDictionary *authSchemeJson = [self.authScheme jsonDictionary];
    if (!authSchemeJson)
    {
        MSID_LOG_WITH_CORR(MSIDLogLevelError, nil, @"Failed to create json for %@ class, auth scheme json is nil.", self.class);
        return nil;
    }
    
    [json addEntriesFromDictionary:authSchemeJson];
    
    return json;
}

@end
