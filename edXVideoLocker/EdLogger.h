//
//  EdLogger.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 18/10/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define SR_ENABLE_LOG

static inline void ELog(NSString *format, ...)  {
#ifdef SR_ENABLE_LOG
    __block va_list arg_list;
    va_start (arg_list, format);
    
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:arg_list];
    
    va_end(arg_list);
    
    NSLog(@"[SR] %@", formattedString);
#endif
}
@interface EdLogger : NSObject

@end
