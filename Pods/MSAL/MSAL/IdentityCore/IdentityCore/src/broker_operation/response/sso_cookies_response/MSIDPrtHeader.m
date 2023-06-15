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


#import "MSIDPrtHeader.h"

static NSString *const MSID_PRT_HEADER_HOME_ACCOUNT_ID = @"home_account_id";
static NSString *const MSID_PRT_HEADER_DISPLAYABLE_ID = @"displayable_id";

@implementation MSIDPrtHeader

#pragma mark - MSIDJsonSerializable

- (instancetype)initWithJSONDictionary:(NSDictionary *)json error:(NSError **)error
{
    self = [super initWithJSONDictionary:json error:error];
    
    if (self)
    {
        _homeAccountId = json[MSID_PRT_HEADER_HOME_ACCOUNT_ID];
        _displayableId = json[MSID_PRT_HEADER_DISPLAYABLE_ID];
    }
    
    return self;
}

- (NSDictionary *)jsonDictionary
{
    NSMutableDictionary *json = [[super jsonDictionary] mutableCopy];
    if(!json) return nil;
    
    if ([NSString msidIsStringNilOrBlank:self.homeAccountId])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"account_identifier is not provided from prt header");
        return nil;
    }
    
    if (![NSString msidIsStringNilOrBlank:self.homeAccountId])
    {
        json[MSID_PRT_HEADER_HOME_ACCOUNT_ID] = self.homeAccountId;
    }
    
    if (![NSString msidIsStringNilOrBlank:self.displayableId])
    {
        json[MSID_PRT_HEADER_DISPLAYABLE_ID] = self.displayableId;
    }
    
    return json;
}

@end
