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

#import "MSIDAdfsAuthorityResolver.h"
#import "MSIDADFSAuthority.h"
#import "MSIDWebFingerRequest.h"
#import "MSIDDRSDiscoveryRequest.h"
#import "MSIDAuthorityCacheRecord.h"

static NSString *const s_kTrustedRelation = @"http://schemas.microsoft.com/rel/trusted-realm";
static MSIDCache <NSString *, MSIDAuthorityCacheRecord *> *s_cache;

@implementation MSIDAdfsAuthorityResolver

+ (void)initialize
{
    if (self == [MSIDAdfsAuthorityResolver self])
    {
        s_cache = [MSIDCache new];
    }
}

+ (MSIDCache *)cache
{
    return s_cache;
}

- (void)resolveAuthority:(MSIDADFSAuthority *)authority
       userPrincipalName:(NSString *)upn
                validate:(BOOL)validate
                 context:(id<MSIDRequestContext>)context
         completionBlock:(MSIDAuthorityInfoBlock)completionBlock
{
    if (!validate)
    {
        __auto_type openIdConfigurationEndpoint = [self openIdConfigurationEndpointForAuthority:authority.url];
        if (completionBlock) completionBlock(openIdConfigurationEndpoint, NO, nil);
        return;
    }
    
    __auto_type record = [s_cache objectForKey:authority.url.absoluteString.lowercaseString];
    if (record)
    {
        if (completionBlock) completionBlock(record.openIdConfigurationEndpoint, record.validated, nil);
        return;
    }
    
    // Check for upn suffix
    NSString *domain = [self getDomain:upn];
    if ([NSString msidIsStringNilOrBlank:domain])
    {
        __auto_type error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"'upn' is a required parameter and must not be nil or empty.", nil, nil, nil, context.correlationId, nil, YES);
        
        if (completionBlock) completionBlock(nil, NO, error);
        return;
    }
    
    [self sendDrsDiscoveryWithDomain:domain context:context completionBlock:^(NSURL *issuer, NSError *error)
     {
         if (error)
         {
             if (completionBlock) completionBlock(nil, NO, error);
             return;
         }
         
         __auto_type webFingerRequest = [[MSIDWebFingerRequest alloc] initWithIssuer:issuer
                                                                           authority:authority.url
                                                                             context:context];
         [webFingerRequest sendWithBlock:^(id response, NSError *webFingerError)
          {
              if (webFingerError)
              {
                  if (completionBlock) completionBlock(nil, NO, webFingerError);
                  return;
              }
              
              if ([self isRealmTrustedFromWebFingerPayload:response authority:authority.url])
              {
                  __auto_type openIdConfigurationEndpoint = [self openIdConfigurationEndpointForAuthority:authority.url];
                  
                  __auto_type cacheRecord = [MSIDAuthorityCacheRecord new];
                  cacheRecord.validated = YES;
                  cacheRecord.openIdConfigurationEndpoint = openIdConfigurationEndpoint;
                  [s_cache setObject:cacheRecord forKey:authority.url.absoluteString.lowercaseString];
                  
                  if (completionBlock) completionBlock(openIdConfigurationEndpoint, YES, nil);
              }
              else
              {
                  webFingerError = MSIDCreateError(MSIDErrorDomain, MSIDErrorAuthorityValidation, @"WebFinger request was invalid or failed", nil, nil, nil, context.correlationId, nil, YES);
                  if (completionBlock) completionBlock(nil, NO, webFingerError);
              }
          }];
     }];
}

#pragma mark - Private

- (void)sendDrsDiscoveryWithDomain:(NSString *)domain
                           context:(id<MSIDRequestContext>)context
                   completionBlock:(MSIDHttpRequestDidCompleteBlock)completionBlock
{
    __auto_type drsOnPremRequest = [[MSIDDRSDiscoveryRequest alloc] initWithDomain:domain adfsType:MSIDDRSTypeOnPrem context:context];
    [drsOnPremRequest sendWithBlock:^(id drsOnPremResponse, NSError *drsOnPremError)
     {
         if (drsOnPremResponse)
         {
             if (completionBlock) completionBlock(drsOnPremResponse, drsOnPremError);
             return;
         }
         
         __auto_type drsCloudRequest = [[MSIDDRSDiscoveryRequest alloc] initWithDomain:domain adfsType:MSIDDRSTypeInCloud context:context];
        [drsCloudRequest sendWithBlock:^(id drsCloudResponse, NSError *drsCloudError)
          {
              if (completionBlock) completionBlock(drsCloudResponse, drsCloudError);
          }];
     }];
}

- (BOOL)isRealmTrustedFromWebFingerPayload:(id)json
                                 authority:(NSURL *)authority
{
    NSArray *links = [json objectForKey:@"links"];
    for (id link in links)
    {
        NSString *rel = [link objectForKey:@"rel"];
        NSString *target = [link objectForKey:@"href"];
        
        NSURL *targetURL = [NSURL URLWithString:target];
        
        if ([rel caseInsensitiveCompare:s_kTrustedRelation] == NSOrderedSame &&
            [targetURL msidIsEquivalentAuthorityHost:authority])
        {
            return YES;
        }
    }
    return NO;
}

- (NSURL *)openIdConfigurationEndpointForAuthority:(NSURL *)authority
{
    if (!authority) return nil;
    
    return [authority URLByAppendingPathComponent:MSID_OPENID_CONFIGURATION_SUFFIX];
}

- (NSString *)getDomain:(NSString *)upn
{
    if (!upn)
    {
        return nil;
    }
    
    NSArray *array = [upn componentsSeparatedByString:@"@"];
    if (array.count != 2)
    {
        return nil;
    }
    
    return array[1];
}

@end

#endif
