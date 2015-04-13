//
//  StorageFactory.m
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import "OEXStorageFactory.h"
#import "OEXStorageInterface.h"
#import "OEXDBManager.h"

@implementation OEXStorageFactory

+ (id <OEXStorageInterface>)getInstance {
    return [OEXDBManager sharedManager];
}

@end
