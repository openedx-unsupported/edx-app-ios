//
//  StorageFactory.h
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014 Clarice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StorageInterface.h"

@interface StorageFactory : NSObject

+ (id<StorageInterface>)getInstance;


@end
