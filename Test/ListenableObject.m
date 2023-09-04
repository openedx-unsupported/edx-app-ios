//
//  ListenableObject.m
//  edX
//
//  Created by Saeed Bashir on 2/18/19.
//  Copyright © 2019 edX. All rights reserved.
//

#import "ListenableObject.h"

@implementation ListenableObject

- (void) setValue:(NSString *)value {
    self.backing = value;
    [self didChangeValueForKey:@"value"];
}

- (NSString *) value {
    return self.backing;
}

@end
