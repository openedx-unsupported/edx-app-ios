//
//  StorageFactory.h
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014-2016 edX, Inc. All rights reserved.
//

#import "OEXStorageInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXStorageFactory : NSObject

+ (id <OEXStorageInterface>)getInstance;

@end

NS_ASSUME_NONNULL_END
