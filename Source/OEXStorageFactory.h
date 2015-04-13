//
//  StorageFactory.h
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXStorageInterface.h"

@interface OEXStorageFactory : NSObject

+ (id <OEXStorageInterface>)getInstance;

@end
