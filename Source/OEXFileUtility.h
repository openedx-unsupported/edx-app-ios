//
//  OEXFileUtility.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OEXFileUtility : NSObject

/// Returns a path for saving user specific data. This data is not backed up
/// When called it will create the directory if it does not already exist
+ (nullable NSString*)pathForUserNameCreatingIfNecessary:(nullable NSString*)userName;

/// Shortcut for pathForUserNameCreatingIfNecessary: with the current user.
/// Do not add new uses of this. In the future we want to be explicitly passing the user
+ (nullable NSString*)userDirectory;

/// Do not add new uses of this. In the future we want to be explicitly passing the user
+ (nullable NSString*)filePathForRequestKey:(nullable NSString*)key;

+ (nullable NSString*)filePathForVideoURL:(nullable NSString*)videoUrl username:(nullable NSString*)username;
+ (nullable NSString*)filePathForRequestKey:(nullable NSString*)key username:(nullable NSString*)username;
+ (nullable NSURL*)fileURLForRequestKey:(nullable NSString*)key username:(nullable NSString*)username;

+ (void)nukeUserData;
+ (void) nukeUserPIIData;

@end

@interface OEXFileUtility (Testing)

+ (NSString*)t_legacyPathForUserName:(NSString*)userName;
// Unlike the non test version, this does not create the directory
+ (NSString*)t_pathForUserName:(NSString*)userName;

@end

NS_ASSUME_NONNULL_END
