//
//  MSIDJsonResponsePreprocessor.m
//  IdentityCore
//
//  Created by Sergey Demchenko on 12/24/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import "MSIDJsonResponsePreprocessor.h"

@implementation MSIDJsonResponsePreprocessor

- (nullable id)responseObjectForResponse:(nullable __unused  NSHTTPURLResponse *)httpResponse
                                    data:(nullable NSData *)data
                                 context:(nullable __unused id<MSIDRequestContext>)context
                                   error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    id jsonObject;
    if (data)
    {
        jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    }
    
    return jsonObject;
}

@end
