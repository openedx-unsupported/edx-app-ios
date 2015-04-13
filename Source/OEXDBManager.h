//
//  OEXDBManager.h
//  edXLibrary
//
//  Created by Rahul Varma on 07/11/14.
//  Copyright (c) 2014 edX, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXStorageInterface.h"
#import <CoreData/CoreData.h>
#import "OEXAppDelegate.h"

@interface OEXDBManager : NSObject <OEXStorageInterface>
{
}
//Singleton method
+ (OEXDBManager*)sharedManager;
@end
