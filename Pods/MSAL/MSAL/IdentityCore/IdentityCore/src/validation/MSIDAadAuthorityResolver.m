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

#import "MSIDAadAuthorityResolver.h"
#import "MSIDAADAuthorityMetadataRequest.h"
#import "MSIDAADAuthority.h"
#import "MSIDAadAuthorityCache.h"
#import "MSIDAADNetworkConfiguration.h"
#import "MSIDAadAuthorityCacheRecord.h"
#import "MSIDAADAuthority.h"
#import "MSIDAADAuthorityMetadataResponse.h"
#import "NSError+MSIDExtensions.h"

static dispatch_queue_t s_aadValidationQueue;

@implementation MSIDAadAuthorityResolver

+ (void)initialize
{
    if (self == [MSIDAadAuthorityResolver self])
    {
        // A serial dispatch queue for all authority validation operations. A very common pattern is for
        // applications to spawn a bunch of threads and call acquireToken on them right at the start. Many
        // of those acquireToken calls will be to the same authority. To avoid making the exact same
        // authority validation network call multiple times we throw the requests in this validation
        // queue.
        s_aadValidationQueue = dispatch_queue_create("msid.aadvalidation.queue", DISPATCH_QUEUE_SERIAL);
    }
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _aadCache = [MSIDAadAuthorityCache sharedInstance];
    }
    
    return self;
}

- (void)resolveAuthority:(MSIDAADAuthority *)authority
       userPrincipalName:(__unused NSString *)upn
                validate:(BOOL)validate
                 context:(id<MSIDRequestContext>)context
         completionBlock:(MSIDAuthorityInfoBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    NSParameterAssert([authority isKindOfClass:MSIDAADAuthority.self]);
    
    MSIDAadAuthorityCacheRecord *record = [self.aadCache objectForKey:authority.environment];
    if (record)
    {
        [self handleRecord:record authority:authority completionBlock:completionBlock];
        return;
    }
    
    dispatch_async(s_aadValidationQueue, ^{
        
        // If we didn't have anything in the cache then we need to hold onto the queue until we
        // get a response back from the server, or timeout, or fail for any other reason
        __block dispatch_semaphore_t dsem = dispatch_semaphore_create(0);
        
        [self sendDiscoverRequestWithAuthority:authority validate:validate context:context completionBlock:^(NSURL *openIdConfigurationEndpoint, BOOL validated, NSError *error)
         {
             // Because we're on a serialized queue here to ensure that we don't have more then one
             // validation network request at a time, we want to jump off this queue as quick as
             // possible whenever we hit an error to unblock the queue
             completionBlock(openIdConfigurationEndpoint, validated, error);
             
             dispatch_semaphore_signal(dsem);
         }];
        
        // We're blocking the AAD Validation queue here so that we only process one authority validation
        // request at a time. As an application typically only uses a single AAD authority, this cuts
        // down on the amount of simultaneous requests that go out on multi threaded app launch
        // scenarios.
        if (dispatch_semaphore_wait(dsem, DISPATCH_TIME_NOW) != 0)
        {
            // Only bother logging if we have to wait on the queue.
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Waiting on Authority Validation Queue");
            dispatch_semaphore_wait(dsem, DISPATCH_TIME_FOREVER);
            MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Returned from Authority Validation Queue");
        }
    });
}

#pragma mark - Private

- (void)sendDiscoverRequestWithAuthority:(MSIDAADAuthority *)authority
                                validate:(BOOL)validate
                                 context:(id<MSIDRequestContext>)context
                         completionBlock:(MSIDAuthorityInfoBlock)completionBlock
{
    NSParameterAssert(completionBlock);
    
    // Before we make the request, check the cache again, as these requests happen on a serial queue
    // and it's possible we were waiting on a request that got the information we're looking for.
    MSIDAadAuthorityCacheRecord *record = [self.aadCache objectForKey:authority.environment];
    if (record)
    {
        [self handleRecord:record authority:authority completionBlock:completionBlock];
        return;
    }
    
    __auto_type trustedHost = MSIDTrustedAuthorityWorldWide;
    if ([authority isKnown])
    {
        trustedHost = authority.environment;
    }
    
    __auto_type endpoint = [MSIDAADNetworkConfiguration.defaultConfiguration.endpointProvider aadAuthorityDiscoveryEndpointWithHost:trustedHost];
    
    __auto_type *request = [[MSIDAADAuthorityMetadataRequest alloc] initWithEndpoint:endpoint authority:authority.url context: context];
    [request sendWithBlock:^(MSIDAADAuthorityMetadataResponse *response, NSError *error)
     {
         if (error)
         {
             if ([error.msidOauthError isEqualToString:@"invalid_instance"])
             {
                 [self.aadCache addInvalidRecord:authority oauthError:error context:context];
             }
             
             __auto_type endpoint = validate ? nil : [MSIDAADNetworkConfiguration.defaultConfiguration.endpointProvider openIdConfigurationEndpointWithUrl:authority.url];
             error = validate ? error : nil;
             
             completionBlock(endpoint, NO, error);
             return;
         }
         
         [self.aadCache processMetadata:response.metadata
                   openIdConfigEndpoint:response.openIdConfigurationEndpoint
                              authority:authority
                                context:context
                             completion:^(BOOL result, NSError *error)
         {
             if (result)
             {
                 __auto_type endpoint = [MSIDAADNetworkConfiguration.defaultConfiguration.endpointProvider openIdConfigurationEndpointWithUrl:authority.url];
                 completionBlock(endpoint, YES, nil);
             }
             else
             {
                 completionBlock(nil, NO, error);
             }
         }];
     }];
}

- (void)handleRecord:(MSIDAadAuthorityCacheRecord *)record
           authority:(MSIDAuthority *)authority
     completionBlock:(MSIDAuthorityInfoBlock)completionBlock
{
    NSParameterAssert(completionBlock);

    __auto_type endpoint = [MSIDAADNetworkConfiguration.defaultConfiguration.endpointProvider openIdConfigurationEndpointWithUrl:authority.url];
    
    completionBlock(endpoint, record.validated, record.error);
}

@end
