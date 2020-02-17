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

#import "MSIDAADAuthority.h"
#import "MSIDAadAuthorityResolver.h"
#import "MSIDAadAuthorityCache.h"
#import "MSIDAADTenant.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDAuthority+Internal.h"
#import "MSIDIntuneEnrollmentIdsCache.h"
#import "MSIDB2CAuthority.h"
#import "MSIDADFSAuthority.h"
#import "NSURL+MSIDAADUtils.h"

@interface MSIDAADAuthority()

@property (nonatomic) MSIDAadAuthorityCache *authorityCache;

@end

@implementation MSIDAADAuthority

- (instancetype)initWithURL:(NSURL *)url
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    self = [super initWithURL:url context:context error:error];
    if (self)
    {
        _url = [self.class normalizedAuthorityUrl:url context:context error:error];
        if (!_url) return nil;
        _tenant = [self.class tenantFromAuthorityUrl:self.url context:context error:error];
        _authorityCache = [MSIDAadAuthorityCache sharedInstance];
    }
    
    return self;
}

- (nullable instancetype)initWithURL:(nonnull NSURL *)url
                           rawTenant:(NSString *)rawTenant
                             context:(nullable id<MSIDRequestContext>)context
                               error:(NSError **)error
{
    self = [self initWithURL:url context:context error:error];
    if (self)
    {
        if (rawTenant)
        {
            _url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [_url msidHostWithPortIfNecessary], rawTenant]];
            
            if (![self.class isAuthorityFormatValid:_url context:context error:error]) return nil;
            
            _tenant = [self.class tenantFromAuthorityUrl:self.url context:context error:error];
            _realm = _tenant.rawTenant;
        }
    }
    
    return self;
}

- (NSURL *)networkUrlWithContext:(id<MSIDRequestContext>)context
{
    return [self.authorityCache networkUrlForAuthority:self context:context];
}

- (NSURL *)cacheUrlWithContext:(id<MSIDRequestContext>)context
{
    __auto_type universalAuthorityURL = [self universalAuthorityURL];
    __auto_type authority = [[MSIDAADAuthority alloc] initWithURL:universalAuthorityURL context:context error:nil];
    if (authority) NSParameterAssert([authority isKindOfClass:MSIDAADAuthority.class]);
    
    return [self.authorityCache cacheUrlForAuthority:authority context:context];
}

- (nonnull NSString *)cacheEnvironmentWithContext:(nullable id<MSIDRequestContext>)context
{
    return [self cacheUrlWithContext:context].msidHostWithPortIfNecessary;
}

- (NSArray<NSURL *> *)legacyAccessTokenLookupAuthorities
{
    __auto_type universalAuthorityURL = [self universalAuthorityURL];
    __auto_type authority = [[MSIDAADAuthority alloc] initWithURL:universalAuthorityURL context:nil error:nil];
    if (authority) NSParameterAssert([authority isKindOfClass:MSIDAADAuthority.class]);
    
    return [self.authorityCache cacheAliasesForAuthority:authority];
}

- (NSArray<NSString *> *)defaultCacheEnvironmentAliases
{
    return [self.authorityCache cacheAliasesForEnvironment:self.environment];
}

- (nonnull NSURL *)universalAuthorityURL
{
//    AAD v1 endpoint supports only "common" path.
//    AAD v2 endpoint supports both common and organizations.
//    For legacy cache lookups we need to use common authority for compatibility purposes.
//    This method returns "common" authority if "organizations" authority was passed.
//    Otherwise, returns original authority.
    
    if (self.tenant.type == MSIDAADTenantTypeOrganizations)
    {
        __auto_type authority = [[MSIDAADAuthority alloc] initWithURL:self.url rawTenant:MSIDAADTenantTypeCommonRawValue context:nil error:nil];
        
        return authority.url;
    }
    
    return self.url;
}

- (nonnull NSArray<NSURL *> *)legacyRefreshTokenLookupAliases
{
    if (self.tenant.type == MSIDAADTenantTypeConsumers)
    {
        // AAD v1 doesn't support consumer authority
        return @[];
    }
    
    NSMutableArray *aliases = [NSMutableArray array];
    
    if (self.tenant.type == MSIDAADTenantTypeIdentifier)
    {
        // If it's a tenanted authority, lookup original authority and common as those are the same, but start with original authority
        [aliases addObjectsFromArray:[self legacyAccessTokenLookupAuthorities]];
        
        __auto_type aadAuthorityCommon = [MSIDAADAuthority aadAuthorityWithEnvironment:[self.url msidHostWithPortIfNecessary] rawTenant:MSIDAADTenantTypeCommonRawValue context:nil error:nil];
        [aliases addObjectsFromArray:[aadAuthorityCommon legacyAccessTokenLookupAuthorities]];
    }
    else
    {
        // If it's a tenantless authority, lookup by universal "common" authority, which is supported by both v1 and v2
        [aliases addObjectsFromArray:[self legacyAccessTokenLookupAuthorities]];
    }
    
    return aliases;
}

+ (BOOL)isAuthorityFormatValid:(NSURL *)url
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{
    if (![super isAuthorityFormatValid:url context:context error:error]) return NO;
    
    __auto_type tenant = [self tenantFromAuthorityUrl:url context:context error:error];
    
    if ([MSIDADFSAuthority isAuthorityFormatValid:url context:context error:nil])
    {
        if (error)
        {
            __auto_type message = [NSString stringWithFormat:@"Trying to initialize AAD authority with ADFS authority url."];
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidDeveloperParameter, message, nil, nil, nil, context.correlationId, nil, YES);
        }
        return NO;
    }
    
    if ([MSIDB2CAuthority isAuthorityFormatValid:url context:context error:nil])
    {
        if (error)
        {
            __auto_type message = [NSString stringWithFormat:@"Trying to initialize AAD authority with B2C authority url."];
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidDeveloperParameter, message, nil, nil, nil, context.correlationId, nil, YES);
        }
        return NO;
    }
    
    return tenant != nil;
}

+ (instancetype)aadAuthorityWithEnvironment:(NSString *)environment
                                   rawTenant:(NSString *)rawTenant
                                     context:(id<MSIDRequestContext>)context
                                       error:(NSError **)error
{
    __auto_type authorityUrl = [NSURL msidAADURLWithEnvironment:environment tenant:rawTenant];
    __auto_type authority = [[MSIDAADAuthority alloc] initWithURL:authorityUrl context:context error:error];
    
    return authority;
}

- (NSString *)enrollmentIdForHomeAccountId:(NSString *)homeAccountId
                              legacyUserId:(NSString *)legacyUserId
                                   context:(id<MSIDRequestContext>)context
                                     error:(NSError **)error
{
    return [[MSIDIntuneEnrollmentIdsCache sharedCache] enrollmentIdForHomeAccountId:homeAccountId
                                                                       legacyUserId:legacyUserId
                                                                            context:context
                                                                              error:error];
}

- (nonnull NSString *)telemetryAuthorityType
{
    return MSID_TELEMETRY_VALUE_AUTHORITY_AAD;
}

- (BOOL)supportsBrokeredAuthentication
{
    if (self.tenant.type == MSIDAADTenantTypeConsumers)
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)supportsMAMScenarios
{
    return YES;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAADAuthority *authority = [super copyWithZone:zone];
    authority->_tenant = [_tenant copyWithZone:zone];
    
    return authority;
}

#pragma mark - Protected

+ (NSString *)realmFromURL:(NSURL *)url
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if ([self isAuthorityFormatValid:url context:context error:error])
    {
        return [self tenantFromAuthorityUrl:url context:context error:error].rawTenant;
    }
    
    // We don't support non standard AAD authority formats
    return nil;
}

- (id<MSIDAuthorityResolving>)resolver
{
    return [MSIDAadAuthorityResolver new];
}

#pragma mark - Private

+ (NSURL *)normalizedAuthorityUrl:(NSURL *)url
                          context:(id<MSIDRequestContext>)context
                            error:(NSError **)error
{
    // Normalization requires url to have at least 1 path and a host.
    // Return nil otherwise.
    if (!url || url.pathComponents.count < 2)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"authority must have a host and a path to be normalized.", nil, nil, nil, context.correlationId, nil, YES);
        }
        return nil;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@", [url msidHostWithPortIfNecessary], url.pathComponents[1]]];
}

+ (MSIDAADTenant *)tenantFromAuthorityUrl:(NSURL *)url
                                  context:(id<MSIDRequestContext>)context
                                    error:(NSError **)error
{
    NSArray *paths = url.pathComponents;
    
    if ([paths count] < 2)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"authority must have AAD tenant.", nil, nil, nil, context.correlationId, nil, YES);
        }
        
        return nil;
    }
    
    NSString *rawTenant = [paths[1] lowercaseString];
    return [[MSIDAADTenant alloc] initWithRawTenant:rawTenant context:context error:error];
}

#pragma mark - Sovereign

- (MSIDAuthority *)authorityWithUpdatedCloudHostInstanceName:(NSString *)cloudHostInstanceName error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:cloudHostInstanceName]) return nil;
    
    NSURL *cloudAuthorityURL = [self.url msidAADAuthorityWithCloudInstanceHostname:cloudHostInstanceName];
    return [[MSIDAADAuthority alloc] initWithURL:cloudAuthorityURL context:nil error:error];
}

@end
