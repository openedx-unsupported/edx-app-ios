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

#import "NSURL+MSIDAADUtils.h"

@implementation NSURL (MSIDAADUtils)

- (NSString *)msidAADTenant
{
    NSArray *pathComponents = [self pathComponents];
    
    if ([pathComponents count] <= 1)
    {
        return nil;
    }
    
    if ([pathComponents[1] caseInsensitiveCompare:@"tfp"] == NSOrderedSame)
    {
        if ([pathComponents count] < 3)
        {
            return nil;
        }
        
        /* TODO: verify if policy should be also part of the cache key
         Currently, for B2C, there'll be different refresh tokens and access tokens per policy
         This should be controled by different clientInfo returned for different B2C policies
         For AAD it will be:
         
         {
         "uid" :"oid_in_directory"
         "utid" :"tenant id"
         }
         
         For B2C it should be:
         
         {
         "uid" :"oid_in_directory+policy"
         "utid" :"tenant id"
         }
         
         So, there should be already policy identifier as part of the cache key through client info and adding additional policy identifier would mean special client side handling for B2C. Instead, this should be handled by the server side.
         
         */
        
        return pathComponents[2];
    }
    
    return pathComponents[1];
}

- (NSURL *)msidAADAuthorityWithCloudInstanceHostname:(NSString *)cloudInstanceHostName
{
    if ([NSString msidIsStringNilOrBlank:cloudInstanceHostName])
    {
        return self;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];
    
    // Invalid URL
    if ([NSString msidIsStringNilOrBlank:urlComponents.host])
    {
        return self;
    }
    
    urlComponents.host = cloudInstanceHostName;
    
    return urlComponents.URL;
}

+ (NSURL *)msidAADURLWithEnvironment:(NSString *)environment tenant:(NSString *)tenant
{
    if ([NSString msidIsStringNilOrBlank:environment])
    {
        return nil;
    }
    
    if ([NSString msidIsStringNilOrBlank:tenant])
    {
        return [self msidAADURLWithEnvironment:environment];
    }
    
    NSString *authorityString = [NSString stringWithFormat:@"https://%@/%@", environment, tenant];
    return [NSURL URLWithString:authorityString];
}

+ (NSURL *)msidAADURLWithEnvironment:(NSString *)environment
{
    return [self msidAADURLWithEnvironment:environment tenant:@"common"];
}

@end
