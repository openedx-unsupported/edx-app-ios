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

#import "MSIDUrlRequestSerializer.h"
#import "NSDictionary+MSIDExtensions.h"

@implementation MSIDUrlRequestSerializer

- (NSURLRequest *)serializeWithRequest:(NSURLRequest *)request parameters:(NSDictionary *)parameters headers:(NSDictionary *)headers
{
    NSParameterAssert(request);
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSMutableDictionary *requestHeaders = [NSMutableDictionary new];
    
    if ([headers count])
    {
        [requestHeaders addEntriesFromDictionary:headers];
    }
    
    if ([parameters count])
    {
       if ([self shouldEncodeParametersInURL:request])
       {
           NSAssert(mutableRequest.URL, NULL);
           
           NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:mutableRequest.URL resolvingAgainstBaseURL:NO];
           NSMutableDictionary *urlParameters = [[mutableRequest.URL msidQueryParameters] mutableCopy] ?: [NSMutableDictionary new];
           [urlParameters addEntriesFromDictionary:parameters];
           urlComponents.percentEncodedQuery = [urlParameters msidURLEncode];
           mutableRequest.URL = urlComponents.URL;
       }
       else
       {
           mutableRequest.HTTPBody = [[parameters msidWWWFormURLEncode] dataUsingEncoding:NSUTF8StringEncoding];
           [requestHeaders setObject:@"application/x-www-form-urlencoded" forKey:@"Content-Type"];
       }
    }
    
    mutableRequest.allHTTPHeaderFields = requestHeaders;
    return mutableRequest;
}

#pragma mark - Private

- (BOOL)shouldEncodeParametersInURL:(NSURLRequest *)request
{
    __auto_type urlMethods = @[@"GET", @"HEAD", @"DELETE"];
    
    return [urlMethods containsObject:request.HTTPMethod.uppercaseString];
}

@end
