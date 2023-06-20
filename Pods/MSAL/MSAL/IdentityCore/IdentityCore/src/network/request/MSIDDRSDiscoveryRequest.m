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

#import "MSIDDRSDiscoveryRequest.h"
#import "MSIDDRSDiscoveryResponseSerializer.h"
#import "MSIDAADRequestConfigurator.h"
#import "MSIDAADNetworkConfiguration.h"

@interface MSIDDRSDiscoveryRequest()

@property (nonatomic) NSString *domain;
@property (nonatomic) MSIDDRSType adfsType;

@end

@implementation MSIDDRSDiscoveryRequest

- (instancetype)initWithDomain:(NSString *)domain
                      adfsType:(MSIDDRSType)adfsType
                       context:(id<MSIDRequestContext>)context
{
    self = [super init];
    if (self)
    {
        NSParameterAssert(domain);
        
        _domain = domain;
        _adfsType = adfsType;
        _context = context;
        
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        parameters[@"api-version"] = MSIDAADNetworkConfiguration.defaultConfiguration.drsDiscoveryApiVersion;
        _parameters = parameters;

        NSMutableURLRequest *urlRequest = [NSMutableURLRequest new];
        urlRequest.URL = [self endpointWithDomain:domain adfsType:adfsType];
        urlRequest.HTTPMethod = @"GET";
        _urlRequest = urlRequest;
        
        __auto_type requestConfigurator = [MSIDAADRequestConfigurator new];
        [requestConfigurator configure:self];
        
        _responseSerializer = [MSIDDRSDiscoveryResponseSerializer new];
    }
    
    return self;
}

- (NSURL *)endpointWithDomain:(NSString *)domain adfsType:(MSIDDRSType)type
{
    if (type == MSIDDRSTypeOnPrem)
    {
        return [NSURL URLWithString:
                [NSString stringWithFormat:@"https://enterpriseregistration.%@/enrollmentserver/contract", domain.lowercaseString]];
    }
    else if (type == MSIDDRSTypeInCloud)
    {
        return [NSURL URLWithString:
                [NSString stringWithFormat:@"https://enterpriseregistration.windows.net/%@/enrollmentserver/contract", domain.lowercaseString]];
    }
    
    return nil;
}

@end

#endif
