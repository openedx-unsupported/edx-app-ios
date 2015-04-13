//
//  OEXFileUtility.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXFileUtility : NSObject

+ (void)updateData:(NSData*)data ForURLString:(NSString*)URLString;

/// Returns a path for saving user specific data. This data is not backed up
/// When called it will create the directory if it does not already exist
+ (NSString*)pathForUserNameCreatingIfNecessary:(NSString*)userName;
/// Shortcut for pathForUserNameCreatingIfNecessary: with the current user
+ (NSString*)userDirectory;

+ (NSString*)completeFilePathForUrl:(NSString*)url;

+ (BOOL )writeData:(NSData*)data atFilePath:(NSString*)filePath;

+ (NSData*)dataForURLString:(NSString*)URLString;

+ (NSData*)resumeDataForURLString:(NSString*)URLString;

+ (NSString*)localFilePathForVideoUrl:(NSString*)videoUrl;

+ (NSString*)completeFilePathForUrl:(NSString*)url userName:(NSString*)username;

@end

@interface OEXFileUtility (Testing)

+ (NSString*)t_legacyPathForUserName:(NSString*)userName;
// Unlike the non test version, this does not create the directory
+ (NSString*)t_pathForUserName:(NSString*)userName;

@end