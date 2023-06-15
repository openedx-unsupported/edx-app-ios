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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.  


#import "MSIDCredentialInfo.h"
#import "NSString+MSIDExtensions.h"

@implementation MSIDCredentialInfo

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super init];
    
    if (self)
    {
        if (json.allKeys.count != 1)
        {
            // This is not a valid case, but leave it just in case
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Jwt is not correctly presented from credential header", nil, nil, nil, nil, nil, YES);
            }
            
            return nil;
        }
        
        if ([json.allKeys.firstObject isKindOfClass:[NSString class]])
        {
            _name = json.allKeys.firstObject;
        }
        else
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Unexpected type for credential header name", nil, nil, nil, nil, nil, YES);
            }
            
            return nil;
        }
         
        if ([json[_name] isKindOfClass:[NSString class]])
        {
            _value = json[_name];
        }
        else
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Unexpected type for credential header value", nil, nil, nil, nil, nil, YES);
            }
            
            return nil;
        }
        
        if ([NSString msidIsStringNilOrBlank:_value])
        {
            if (error)
            {
                *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"No jwt was found from credential header.", nil, nil, nil, nil, nil, YES);
            }
            
            return nil;
        }
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    
    // Map to credentialInfo dictionary
    if ([NSString msidIsStringNilOrBlank:self.name] || [NSString msidIsStringNilOrBlank:self.value]) return nil;
    json[self.name] = self.value;
    
    return json;
}

@end
