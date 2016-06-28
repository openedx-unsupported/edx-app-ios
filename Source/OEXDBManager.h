//
//  OEXDBManager.h
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014-2016 edX, Inc. All rights reserved.
//

#import "OEXStorageInterface.h"
#import "OEXAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXDBManager2 : NSObject <OEXStorageInterface>
{
}
//Singleton method
+ (OEXDBManager2*)sharedManager;
@end

NS_ASSUME_NONNULL_END
