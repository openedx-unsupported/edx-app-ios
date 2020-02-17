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

#import "MSIDPKeyAuthHandler.h"
#import "MSIDChallengeHandler.h"
#import "MSIDWorkPlaceJoinConstants.h"
#import "MSIDPkeyAuthHelper.h"
#import "MSIDHelpers.h"
#import "MSIDError.h"
#import "MSIDDeviceId.h"
#import "MSIDConstants.h"
#import "NSDictionary+MSIDExtensions.h"

@implementation MSIDPKeyAuthHandler

+ (BOOL)handleChallenge:(NSString *)challengeUrl
                context:(id<MSIDRequestContext>)context
      completionHandler:(void (^)(NSURLRequest *challengeResponse, NSError *error))completionHandler
{
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, context, @"Handling PKeyAuth Challenge.");
    
    NSArray *parts = [challengeUrl componentsSeparatedByString:@"?"];
    NSString *qp = [parts objectAtIndex:1];
    NSDictionary *queryParamsMap = [NSDictionary msidDictionaryFromURLEncodedString:qp];
    NSString *submitUrl = [queryParamsMap valueForKey:@"SubmitUrl"];
    
    // Fail if the PKeyAuth challenge doesn't contain the required info
    NSError *error = nil;
    if (!queryParamsMap || !submitUrl)
    {
        error = MSIDCreateError(MSIDOAuthErrorDomain, MSIDErrorServerOauth, @"Incomplete PKeyAuth challenge received.", nil, nil, nil, context.correlationId, nil, YES);
        completionHandler(nil, error);
        return YES;
    }
    
    // Extract authority from submit url    
    NSString *authHeader = [MSIDPkeyAuthHelper createDeviceAuthResponse:[NSURL URLWithString:submitUrl]
                                                          challengeData:queryParamsMap
                                                                context:context];
    
    // Attach client version to response url
    NSURLComponents *responseUrlComp = [[NSURLComponents alloc] initWithURL:[NSURL URLWithString:submitUrl] resolvingAgainstBaseURL:NO];
    NSMutableDictionary *queryDict = [NSMutableDictionary new];
    
    for (NSURLQueryItem *item in responseUrlComp.queryItems)
    {
        [queryDict setValue:item.value forKey:item.name];
    }
    [queryDict setValue:MSIDDeviceId.deviceId[MSID_VERSION_KEY] forKey:MSID_VERSION_KEY];
    responseUrlComp.percentEncodedQuery = [queryDict msidURLEncode];
    
    NSMutableURLRequest *responseReq = [[NSMutableURLRequest alloc] initWithURL:responseUrlComp.URL];
    [responseReq setValue:kMSIDPKeyAuthHeaderVersion forHTTPHeaderField:kMSIDPKeyAuthHeader];
    [responseReq setValue:authHeader forHTTPHeaderField:MSID_OAUTH2_AUTHORIZATION];
    completionHandler(responseReq, nil);
    return YES;
}

+ (void)handleWwwAuthenticateHeader:(NSString *)wwwAuthHeaderValue
                         requestUrl:(NSURL *)requestUrl
                            context:(id<MSIDRequestContext>)context
                  completionHandler:(void (^)(NSString *authHeader, NSError *error))completionHandler
{
    NSDictionary *authHeaderParams = [self parseAuthHeader:wwwAuthHeaderValue];
    
    if (!authHeaderParams)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, context, @"Unparseable wwwAuthHeader received %@", MSID_PII_LOG_MASKABLE(wwwAuthHeaderValue));
    }
    
    NSError *error = nil;
    NSString *authHeader = [MSIDPkeyAuthHelper createDeviceAuthResponse:requestUrl
                                                          challengeData:authHeaderParams
                                                                context:context];
    if (completionHandler)
    {
        completionHandler(authHeader, error);
    }
}

// Decodes the parameters that come in the Authorization header. We expect them in the following
// format:
//
// <key>="<value>", key="<value>", key="<value>"
// i.e. version="1.0",CertAuthorities="OU=MyOrganization,CN=MyThingy,DN=windows,DN=net",Context="context!"
//
// This parser is lenient on whitespace, and on the presence of enclosing quotation marks. It also
// will allow commented out quotation marks
+ (NSDictionary *)parseAuthHeader:(NSString *)authHeader
{
    if (!authHeader)
    {
        return nil;
    }
    
    //pkeyauth word length=8 + 1 whitespace
    authHeader = [authHeader substringFromIndex:[kMSIDPKeyAuthName length] + 1];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSUInteger strLength = [authHeader length];
    NSRange currentRange = NSMakeRange(0, strLength);
    NSCharacterSet *whiteChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *alphaNum = [NSCharacterSet alphanumericCharacterSet];
    
    while (currentRange.location < strLength)
    {
        // Eat up any whitepace at the beginning
        while (currentRange.location < strLength && [whiteChars characterIsMember:[authHeader characterAtIndex:currentRange.location]])
        {
            ++currentRange.location;
            --currentRange.length;
        }
        
        if (currentRange.location == strLength)
        {
            return params;
        }
        
        if (![alphaNum characterIsMember:[authHeader characterAtIndex:currentRange.location]])
        {
            // malformed string
            return nil;
        }
        
        // Find the key
        NSUInteger found = [authHeader rangeOfString:@"=" options:0 range:currentRange].location;
        // If there are no keys left then exit out
        if (found == NSNotFound)
        {
            // If there still is string left that means it's malformed
            if (currentRange.length > 0)
            {
                return nil;
            }
            
            // Otherwise we're at the end, return params
            return params;
        }
        NSUInteger length = found - currentRange.location;
        NSString *key = [authHeader substringWithRange:NSMakeRange(currentRange.location, length)];
        
        // don't want the '='
        ++length;
        currentRange.location += length;
        currentRange.length -= length;
        
        NSString *value = nil;
        
        
        if ([authHeader characterAtIndex:currentRange.location] == '"')
        {
            ++currentRange.location;
            --currentRange.length;
            
            found = currentRange.location;
            
            do {
                NSRange range = NSMakeRange(found, strLength - found);
                found = [authHeader rangeOfString:@"\"" options:0 range:range].location;
            } while (found != NSNotFound && [authHeader characterAtIndex:found-1] == '\\');
            
            // If we couldn't find a matching closing quote then we have a malformed string and return NULL
            if (found == NSNotFound)
            {
                return nil;
            }
            
            length = found - currentRange.location;
            value = [authHeader substringWithRange:NSMakeRange(currentRange.location, length)];
            
            ++length;
            currentRange.location += length;
            currentRange.length -= length;
            
            // find the next comma
            found = [authHeader rangeOfString:@"," options:0 range:currentRange].location;
            if (found != NSNotFound)
            {
                length = found - currentRange.location;
            }
            
        }
        else
        {
            found = [authHeader rangeOfString:@"," options:0 range:currentRange].location;
            // If we didn't find the comma that means we're at the end of the list
            if (found == NSNotFound)
            {
                length = currentRange.length;
            }
            else
            {
                length = found - currentRange.location;
            }
            
            value = [authHeader substringWithRange:NSMakeRange(currentRange.location, length)];
        }
        
        NSString *existingValue = [params valueForKey:key];
        if (existingValue)
        {
            [params setValue:[existingValue stringByAppendingFormat:@".%@", value] forKey:key];
        }
        else
        {
            [params setValue:value forKey:key];
        }
        
        ++length;
        currentRange.location += length;
        currentRange.length -= length;
    }
    
    return params;
}

@end
