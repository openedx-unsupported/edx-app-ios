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

#import "NSURL+MSIDExtensions.h"
#import "NSDictionary+MSIDExtensions.h"
#import "NSString+MSIDExtensions.h"

@implementation NSURL (MSIDExtensions)      

// Decodes configuration contained in a URL fragment
- (NSDictionary *)msidFragmentParameters
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    return [NSDictionary msidDictionaryFromURLEncodedString:components.percentEncodedFragment];
}

// Decodes configuration contains in a URL query
- (NSDictionary *)msidQueryParameters
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:YES];
    return [NSDictionary msidDictionaryFromURLEncodedString:components.percentEncodedQuery];
}

- (BOOL)msidIsEquivalentAuthority:(NSURL *)aURL
{
    if (![self msidIsEquivalentAuthorityHost:aURL])
    {
        return NO;
    }
    
    // Check path
    if (self.path || aURL.path)
    {
        if (![self.path isEqual:aURL.path])
        {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)msidIsEquivalentAuthorityHost:(NSURL *)aURL
{
    // Check if equal
    if ([self isEqual:aURL])
    {
        return YES;
    }

    // Check scheme and host
    if (!self.scheme ||
        !aURL.scheme ||
        [self.scheme caseInsensitiveCompare:aURL.scheme] != NSOrderedSame)
    {
        return NO;
    }

    if (!self.host ||
        !aURL.host ||
        [self.host caseInsensitiveCompare:aURL.host] != NSOrderedSame)
    {
        return NO;
    }

    // Check port
    if (self.port || aURL.port)
    {
        if (![self.port isEqual:aURL.port])
        {
            return NO;
        }
    }

    return YES;
}

- (NSString *)msidHostWithPortIfNecessary
{
    NSNumber *port = self.port;
    
    // This assumes we're using https, which is mandatory for all AAD communications.
    if (port == nil || port.intValue == 443)
    {
        return self.host.lowercaseString;
    }
    return [NSString stringWithFormat:@"%@:%d", self.host.lowercaseString, port.intValue];
}

- (NSURL *)msidURLForHost:(NSString *)preferredHost context:(id<MSIDRequestContext>)context error:(NSError **)error
{
    NSURL *url = [self copy];
    
    if (!preferredHost)
    {
        return url;
    }
    
    if ([url.msidHostWithPortIfNecessary isEqualToString:preferredHost])
    {
        return url;
    }
    
    // Otherwise switch the host for the preferred one.
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    @try
    {
        NSArray *hostComponents = [preferredHost componentsSeparatedByString:@":"];
        
        // I hope there's never a case where there's percent encoded characters in the host, but using
        // this setter prevents NSURLComponents from trying to do any further mangling on the string,
        // probably a good thing.
        components.percentEncodedHost = hostComponents[0];
        
        if (hostComponents.count > 1)
        {
            NSScanner *scanner = [NSScanner scannerWithString:hostComponents[1]];
            int port = 0;
            if (![scanner scanInt:&port] || !scanner.isAtEnd || port < 1 )
            {
                // setPercentEncodedHost and setPort both throw if there's an error, so it's okay for
                // us to throw here as well to propogate the error
                @throw [NSException exceptionWithName:@"InvalidNumberFormatException" reason:@"Port is not a valid integer or port" userInfo:nil];
                MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Port is not a valid integer or port.");
            }
            components.port = [NSNumber numberWithInt:port];
        }
        else
        {
            components.port = nil;
        }
    }
    @catch (NSException *ex)
    {
        NSError *msidError = MSIDCreateError(MSIDErrorDomain, MSIDErrorServerInvalidResponse, @"Failed to replace a host in url.", nil, nil, nil, context.correlationId, nil, NO);
        
        if (error) *error = msidError;
        
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Failed to replace a host in url.");
        
        return nil;
    }
    
    return components.URL;
}

- (NSURL *)msidURLWithQueryParameters:(NSDictionary *)queryParameters
{
    if (![queryParameters count])
    {
        return self;
    }

    // Pull apart the request URL
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];

    if (!components)
    {
        return nil;
    }

    NSString *query = [components percentEncodedQuery];

    for (NSString *key in [queryParameters allKeys])
    {
        if (query && [query containsString:key])
        {
            // Don't bother adding it if it's already there
            continue;
        }

        NSString *queryEntry = [NSString stringWithFormat:@"%@=%@", key.msidURLEncode, [queryParameters[key] msidURLEncode]];

        if (query)
        {
            query = [query stringByAppendingFormat:@"&%@", queryEntry];
        }
        else
        {
            query = queryEntry;
        }
    }

    if (query)
    {
        components.percentEncodedQuery = query;
    }

    return [components URL];
}

- (NSURL *)msidPIINullifiedURL
{
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
    
    NSMutableArray *piiQueryItems = [NSMutableArray new];
    
    for (NSURLQueryItem *queryItem in components.queryItems)
    {
        NSString *piiValue = [NSString msidIsStringNilOrBlank:queryItem.value] ? @"(null)" : @"(not-null)";
        NSURLQueryItem *piiQueryItem = [[NSURLQueryItem alloc] initWithName:queryItem.name value:piiValue];
        [piiQueryItems addObject:piiQueryItem];
    }
    
    if ([piiQueryItems count])
    {
        components.queryItems = piiQueryItems;
    }
    
    return components.URL;
}

@end
