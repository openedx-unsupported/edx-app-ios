//
//  OEXFileUtility.h
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXFileUtility :NSObject

+ (void)updateData:(NSData *)data ForURLString:(NSString *)URLString;

+(NSString *) documentDir;

+(NSString *) userDirectory;

+(NSString *) relativePathForUrl:(NSString *)url;

+(NSString *) userRelativePathForUrl:(NSString *)url;

+(NSString *) completeFilePathForUrl:(NSString *)url;

+(NSString *) completeFilePathForRelativePath:(NSString *)relativePath;

+(BOOL ) writeData:(NSData *)data atFilePath:(NSString *)filePath;

+ (NSData *)dataForURLString:(NSString *)URLString;

+ (NSData *)resumeDataForURLString:(NSString *)URLString;

+ (void)deleteResumeDataForURLString:(NSString *)URLString;

+(NSString *)localFilePathForVideoUrl:(NSString *)videoUrl;

+(NSString *)completeFilePathForUrl:(NSString *)url andUserName:(NSString *)username;

+(NSString *) userDirectoryForUser:(NSString *)userName;

@end
