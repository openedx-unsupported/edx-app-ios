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


#import "MSIDURLFormObject.h"

@implementation MSIDURLFormObject

- (instancetype)init
{
    return [self initWithDictionary:[NSDictionary dictionary] error:nil];
}

- (instancetype)initWithEncodedString:(NSString *)encodedString
                                error:(NSError * __autoreleasing *)error
{
    if (!encodedString)
    {
        if (error)
        {
            NSString *errorDescription = [NSString stringWithFormat:@"Attempt to initialize URL form object (%@) with nil string", NSStringFromClass(self.class)];
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorDescription, nil, nil, nil,nil, nil, YES);
        }
        
        return nil;
    }
    
    NSDictionary *form = [NSDictionary msidDictionaryFromWWWFormURLEncodedString:encodedString];
    
    if (!form)
    {
        if (error)
        {
            NSString *errorDescription = @"Failed to decode input string";
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorDescription, nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    return [self initWithDictionary:form error:error];
}

- (instancetype)initWithDictionary:(NSDictionary *)form
                             error:(NSError * __autoreleasing *)error
{
    if (!form)
    {
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Attempt to initialize URL form object with nil dictionary", nil, nil, nil, nil, nil, YES);
        }
        
        return nil;
    }
    
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _urlForm = [form mutableCopy];
    
    return self;
}

- (NSDictionary *)formDictionary
{
    return _urlForm;
}

- (NSString *)encode
{
    return [_urlForm msidWWWFormURLEncode];
}

@end
