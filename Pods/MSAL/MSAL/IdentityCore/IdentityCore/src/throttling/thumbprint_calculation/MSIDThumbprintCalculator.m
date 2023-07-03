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

#import <Foundation/Foundation.h>
#import "MSIDThumbprintCalculator.h"


//Exclude List:
//1) Client ID - same across all requests
//2) Grant type - fixed as @"refresh_token"
@implementation MSIDThumbprintCalculator

+ (NSString *)calculateThumbprint:(NSDictionary *)requestParameters
                     filteringSet:(NSSet *)filteringSet
                shouldIncludeKeys:(BOOL)shouldIncludeKeys
{
    if (!requestParameters.count || !filteringSet.count)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"MSIDThumbprintCalculator: invalid input(s) found. empty request parameters and/or filtering set provided.");
        return nil;
    }
    NSArray *sortedThumbprintRequestList = [self sortRequestParametersUsingFilteredSet:requestParameters
                                                                          filteringSet:filteringSet
                                                                     shouldIncludeKeys:shouldIncludeKeys];
    if (sortedThumbprintRequestList)
    {
        NSUInteger thumbprintKey = [self hash:sortedThumbprintRequestList];
        if (thumbprintKey == 0)
        {
            MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"MSIDThumbprintCalculator: hash operation unsuccessful. Input should be an array of NSString objects");
            return nil;
        }
        
        else
        {
            return [NSString stringWithFormat:@"%lu", thumbprintKey];
        }
    }
    MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"MSIDThumbprintCalculator: sorting operation unsuccessful. Input should be a dictionary with key-values of NSString type");
    return nil;
}

+ (NSArray *)sortRequestParametersUsingFilteredSet:(NSDictionary *)requestParameters
                                      filteringSet:(NSSet *)filteringSet
                                 shouldIncludeKeys:(BOOL)shouldIncludeKeys
{
    
    NSMutableArray *arrayList = [NSMutableArray new];
    [requestParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, __unused BOOL * _Nonnull stop) {
        if ([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]])
        {
            if ([filteringSet containsObject:key] == shouldIncludeKeys)
            {
                [arrayList addObject:[NSString stringWithFormat:@"%@:%@", key, obj]];
            }
        }
    }];
    
    NSArray *sortedArray = [arrayList sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2)
                            {
        return [obj1 caseInsensitiveCompare:obj2];
    }];
    
    return sortedArray;
}

+ (NSUInteger)hash:(NSArray<NSString *> *)thumbprintRequestList
{
    if (!thumbprintRequestList || !thumbprintRequestList.count) return 0;
    
    NSUInteger hash = 0;
    for (int i = 0; (unsigned)i < thumbprintRequestList.count; i++)
    {
        hash = hash * 31 + thumbprintRequestList[i].hash;
    }
    return hash;
}

@end
