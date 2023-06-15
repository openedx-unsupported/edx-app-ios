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
#import "MSIDWebResponseOperationFactory.h"
#import "MSIDWebviewResponse.h"
#import "MSIDWebResponseBaseOperation.h"

static NSMutableDictionary *s_container = nil;

@implementation MSIDWebResponseOperationFactory

+ (void)registerOperationClass:(nonnull Class)operationClass
              forResponseClass:(nonnull Class)responseClass
{
    if (![operationClass isSubclassOfClass:MSIDWebResponseBaseOperation.class]) return;
    if (![responseClass isSubclassOfClass:MSIDWebviewResponse.class]) return;

    @synchronized(self)
    {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            s_container = [NSMutableDictionary new];
        });

        NSString *operation = [responseClass operation];
        s_container[operation] = operationClass;
    }
}

+ (void)unregisterAll
{
    @synchronized(self)
    {
        [s_container removeAllObjects];
    }
}

+ (void)unRegisterforResponse:(nonnull MSIDWebviewResponse *)response
{
    @synchronized(self)
    {
        [s_container removeObjectForKey:[response.class operation]];
    }
    
}

+ (nullable MSIDWebResponseBaseOperation *)createOperationForResponse:(nonnull MSIDWebviewResponse *)response
                                                                error:(NSError * _Nullable *)error
{
    NSString *operation = [response.class operation];
    Class operationClass = s_container[operation];

    if (!operationClass)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"No operation for response: %@.", response.class);
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, nil, nil, nil, nil, nil, nil, YES);
        }
        return nil;
    }

    return [[(Class)operationClass alloc] initWithResponse:response error:error];
}

@end
