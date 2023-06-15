//------------------------------------------------------------------------------
//
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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDWebviewResponse.h"
#import "NSURL+MSIDExtensions.h"

@implementation MSIDWebviewResponse

- (instancetype)initWithURL:(NSURL *)url
                    context:(id<MSIDRequestContext>)context
                      error:(NSError **)error
{
    if (!url)
    {
        if (error){
            *error = MSIDCreateError(MSIDOAuthErrorDomain,
                                     MSIDErrorServerInvalidResponse,
                                     @"Trying to create a response with nil URL",
                                     nil, nil, nil, context.correlationId, nil, YES);
        }
        return nil;
    }
    
    self = [super init];
    if (self)
    {
        _url = url;
        
        // Check for auth response
        _parameters = [self.class msidWebResponseParametersFromURL:url];
    }
    
    return self;
}

+ (NSDictionary *)msidWebResponseParametersFromURL:(NSURL *)url
{
    NSMutableDictionary *responseParameters = [NSMutableDictionary new];
    
    /*
     Note that here we only really need to look for query parameters, since this SDK operates based on authorization code grant.
     By default, resulting authorization code will be returned in the query parameters for authorization code grant unless request specifies a different response_mode parameter, which it doesn't in this case.
     
     However, the code to check for fragments has been in ADALs since 2014 and this class will be also used by ADALs. There're two possible reasons why this code was necessary:
     1. Clients sent response_mode=fragment in the extra query parameters and it worked because of ADALs handling.
     2. Some older ADFS version didn't correctly implement the default response mode.
     
     Therefore, the code to read fragment contents will be kept for backward compatibility reasons until determined 100% unnecessary by any clients.
     */
    [responseParameters addEntriesFromDictionary:[url msidFragmentParameters]];
    [responseParameters addEntriesFromDictionary:[url msidQueryParameters]];
    return responseParameters;
}

+ (NSString *)operation
{
    return @"";
}

@end
