//
//  OEXMetaClassHelpers.m
//  edX
//
//  Created by Akiva Leffert on 4/6/16.
//  Copyright © 2016 edX. All rights reserved.
//

#import "OEXMetaClassHelpers.h"

@implementation OEXMetaClassHelpers

+ (id)instanceOfClassNamed:(NSString*)name {
    Class klass = NSClassFromString(name);
    return [[klass alloc] init];
}

@end
