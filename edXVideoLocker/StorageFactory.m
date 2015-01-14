//
//  StorageFactory.m
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014 Clarice. All rights reserved.
//

#import "StorageFactory.h"
#import "StorageInterface.h"
#import "DBManager.h"

@implementation StorageFactory

+ (id<StorageInterface>)getInstance
{
    return  [DBManager sharedManager];
}

@end
