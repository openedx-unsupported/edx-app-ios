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

#import "MSIDAuthority.h"
#import "MSIDAuthority+Internal.h"
#import "MSIDAuthorityResolving.h"
#import "MSIDAadAuthorityResolver.h"
#import "MSIDAADAuthorityMetadataRequest.h"
#import "MSIDDRSDiscoveryRequest.h"
#import "MSIDWebFingerRequest.h"
#import "MSIDAuthorityResolving.h"
#import "MSIDAadAuthorityResolver.h"
#import "MSIDB2CAuthorityResolver.h"
#import "MSIDAdfsAuthorityResolver.h"
#import "MSIDOpenIdConfigurationInfoRequest.h"
#import "MSIDAADNetworkConfiguration.h"
#import "MSIDOpenIdProviderMetadata.h"
#import "MSIDTelemetry+Internal.h"
#import "MSIDTelemetryEventStrings.h"
#import "MSIDTelemetryAuthorityValidationEvent.h"

static MSIDCache <NSString *, MSIDOpenIdProviderMetadata *> *s_openIdConfigurationCache;

@implementation MSIDAuthority

+ (void)initialize
{
    if (self == [MSIDAuthority self])
    {
        s_openIdConfigurationCache = [MSIDCache new];
    }
}

+ (MSIDCache *)openIdConfigurationCache
{
    return s_openIdConfigurationCache;
}

- (instancetype)initWithURL:(NSURL *)url
             validateFormat:(BOOL)validateFormat
                    context:(nullable id<MSIDRequestContext>)context
                      error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    self = [super init];
    if (self)
    {
        if (validateFormat)
        {
            BOOL isValid = [self.class isAuthorityFormatValid:url context:context error:error];
            if (!isValid) return nil;
        }
        _url = url;
        _environment = url.msidHostWithPortIfNecessary;
        
        NSError *realmError = nil;
        _realm = [self.class realmFromURL:url context:context error:&realmError];
        
        if (realmError && validateFormat)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,context, @"Failed to extract realm for authority");
            if (error) *error = realmError;
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    return [self initWithURL:url validateFormat:YES context:context error:error];
}

- (void)resolveAndValidate:(BOOL)validate
         userPrincipalName:(__unused NSString *)upn
                   context:(id<MSIDRequestContext>)context
           completionBlock:(MSIDAuthorityInfoBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    id <MSIDAuthorityResolving> resolver = [self resolver];
    NSParameterAssert(resolver);

    [[MSIDTelemetry sharedInstance] startEvent:context.telemetryRequestId eventName:MSID_TELEMETRY_EVENT_AUTHORITY_VALIDATION];
    
    MSID_LOG_WITH_CTX_PII(MSIDLogLevelInfo, context, @"Resolving authority: %@, upn: %@", MSID_PII_LOG_TRACKABLE(self.url), MSID_PII_LOG_EMAIL(upn));
    
    [resolver resolveAuthority:self
             userPrincipalName:upn
                      validate:validate
                       context:context
               completionBlock:^(NSURL *openIdConfigurationEndpoint, BOOL validated, NSError *error)
     {
         self.openIdConfigurationEndpoint = openIdConfigurationEndpoint;

         MSIDTelemetryAuthorityValidationEvent *validationEvent = [[MSIDTelemetryAuthorityValidationEvent alloc] initWithName:MSID_TELEMETRY_EVENT_AUTHORITY_VALIDATION context:context];
         [validationEvent setAuthorityValidationStatus:validated ? MSID_TELEMETRY_VALUE_YES : MSID_TELEMETRY_VALUE_NO];
         [validationEvent setAuthority:self];
         [[MSIDTelemetry sharedInstance] stopEvent:context.telemetryRequestId event:validationEvent];
         
         MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Resolved authority, validated: %@, error: %ld", validated ? @"YES" : @"NO", (long)error.code);
         
         if (completionBlock) completionBlock(openIdConfigurationEndpoint, validated, error);
     }];
}

- (NSURL *)networkUrlWithContext:(__unused id<MSIDRequestContext>)context
{
    return self.url;
}

- (NSURL *)cacheUrlWithContext:(__unused id<MSIDRequestContext>)context
{
    return self.url;
}

- (nonnull NSString *)cacheEnvironmentWithContext:(nullable id<MSIDRequestContext> __unused)context
{
    return self.url.msidHostWithPortIfNecessary;
}

- (NSArray<NSURL *> *)legacyAccessTokenLookupAuthorities
{
    return @[self.url];
}

- (NSURL *)universalAuthorityURL
{
    return self.url;
}

- (NSArray<NSURL *> *)legacyRefreshTokenLookupAliases
{
     return @[self.url];
}

- (NSArray<NSString *> *)defaultCacheEnvironmentAliases
{
    return @[self.environment];
}

- (NSString *)enrollmentIdForHomeAccountId:(__unused NSString *)homeAccountId
                              legacyUserId:(__unused NSString *)legacyUserId
                                   context:(__unused id<MSIDRequestContext>)context
                                     error:(__unused NSError **)error
{
    return nil;
}

- (BOOL)isKnown
{
    // TODO: Can we move it out from here? What about ADFS & B2C?
    return [MSIDAADNetworkConfiguration.defaultConfiguration isAADPublicCloud:self.url.host.lowercaseString];
}

- (BOOL)supportsBrokeredAuthentication
{
    return NO;
}

- (BOOL)supportsClientIDAsScope
{
    return NO;
}

- (BOOL)supportsMAMScenarios
{
    return NO;
}

- (nonnull NSString *)telemetryAuthorityType
{
    NSAssert(NO, @"Abstract method.");
    
    return @"";
}

- (void)loadOpenIdMetadataWithContext:(nullable id<MSIDRequestContext>)context
                      completionBlock:(nonnull MSIDOpenIdConfigurationInfoBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    if (self.openIdConfigurationEndpoint == nil)
    {
        __auto_type error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInvalidInternalParameter, @"openIdConfigurationEndpoint is nil.", nil, nil, nil, context.correlationId, nil, YES);
        completionBlock(nil, error);
        return;
    }
    
    __auto_type cacheKey = self.openIdConfigurationEndpoint.absoluteString.lowercaseString;
    __auto_type metadata = [s_openIdConfigurationCache objectForKey:cacheKey];
    
    if (metadata)
    {
        self.metadata = metadata;
        completionBlock(metadata, nil);
        return;
    }
    
    __auto_type request = [[MSIDOpenIdConfigurationInfoRequest alloc] initWithEndpoint:self.openIdConfigurationEndpoint context:context];
    [request sendWithBlock:^(MSIDOpenIdProviderMetadata *metadata, NSError *error)
     {
         if (cacheKey && metadata)
         {
             [s_openIdConfigurationCache setObject:metadata forKey:cacheKey];
         }
         
         if (!error) self.metadata = metadata;
         
         completionBlock(metadata, error);
     }];
}

+ (BOOL)isAuthorityFormatValid:(NSURL *)url
                       context:(id<MSIDRequestContext>)context
                         error:(NSError **)error
{
    if ([NSString msidIsStringNilOrBlank:url.absoluteString])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"'authority' is a required parameter and must not be nil or empty.", nil, nil, nil, context.correlationId, nil, YES);
        }
        return NO;
    }
    
    if (![url.scheme isEqualToString:@"https"])
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"authority must use HTTPS.", nil, nil, nil, context.correlationId, nil, YES);
        }
        return NO;
    }
    
    return YES;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDAuthority.class])
    {
        return NO;
    }
    
    return [self isEqualToItem:(MSIDAuthority *)object];
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = hash * 31 + self.url.hash;
    hash = hash * 31 + self.openIdConfigurationEndpoint.hash;
    hash = hash * 31 + self.metadata.hash;
    return hash;
}

- (BOOL)isEqualToItem:(MSIDAuthority *)authority
{
    if (!authority)
    {
        return NO;
    }
    
    BOOL result = YES;
    result &= (!self.url && !authority.url) || [self.url isEqual:authority.url];
    result &= (!self.openIdConfigurationEndpoint && !authority.openIdConfigurationEndpoint) || [self.openIdConfigurationEndpoint isEqual:authority.openIdConfigurationEndpoint];
    result &= (!self.metadata && !authority.metadata) || [self.metadata isEqual:authority.metadata];
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", self.url.absoluteString];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDAuthority *authority = [[self.class allocWithZone:zone] initWithURL:_url context:nil error:nil];
    authority.openIdConfigurationEndpoint = [_openIdConfigurationEndpoint copyWithZone:zone];
    authority.metadata = _metadata;
    authority.url = [_url copyWithZone:zone];
    return authority;
}

#pragma mark - Protected

+ (NSString *)realmFromURL:(NSURL *)url
                   context:(__unused id<MSIDRequestContext>)context
                     error:(__unused NSError **)error
{
    return url.path;
}

- (id<MSIDAuthorityResolving>)resolver
{
    NSAssert(NO, @"Abstract method");
    return nil;
}

#pragma mark - Sovereign

- (MSIDAuthority *)authorityWithUpdatedCloudHostInstanceName:(__unused NSString *)cloudHostInstanceName
                                                           error:(__unused NSError **)error
{
    return nil;
}

@end

