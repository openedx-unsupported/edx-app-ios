//
//  OEXFileUtility.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFileUtility.h"
#import "OEXUserDetails.h"
#import "OEXSession.h"
#pragma mark JSON Data

@implementation OEXFileUtility


+ (NSData *)dataForURLString:(NSString *)URLString {
    
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:URLString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData * data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    return nil;
}

+ (NSData *)resumeDataForURLString:(NSString *)URLString {
    
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:URLString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData * data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    return nil;
}

+ (void)deleteResumeDataForURLString:(NSString *)URLString {
    
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:URLString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }

}
    
    
+ (void)updateData:(NSData *)data ForURLString:(NSString *)URLString {
    //File path
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:URLString];
    [OEXFileUtility writeData:data atFilePath:filePath];
}


+(NSString *) documentDir{
     NSString *documentDir=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
     return documentDir;
}

+(NSString *) userDirectory{
   
    NSString* userDirectory = [[OEXFileUtility documentDir] stringByAppendingPathComponent:[[OEXSession activeSession] currentUser].username];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:userDirectory]) {
        NSError * error;
        if ([[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error]) {
                    NSError* error = nil;
                    if(![[NSURL fileURLWithPath:userDirectory]
                         setResourceValue: @YES forKey: NSURLIsExcludedFromBackupKey error: &error]) {
                        ELog(@"ERROR : On disabling backup : %@",[error description]);
                    }
            
        }
    }
    
    if(userDirectory){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError* error = nil;
        if(![[NSURL fileURLWithPath:userDirectory]
            setResourceValue: @YES forKey: NSURLIsExcludedFromBackupKey error: &error]) {
            ELog(@"ERROR : On disabling backup : %@",[error description]);
        }
    });
   }
   return userDirectory;
    
}

+(NSString *) userDirectoryPathForUserName:(NSString *)userName{
    
    NSString* userDirectory = [[OEXFileUtility documentDir] stringByAppendingPathComponent:userName];
    return userDirectory;
    
}


+(NSString *)userRelativePathForUrl:(NSString *)url{
    if([[OEXSession activeSession] currentUser].username){
        return  [NSString stringWithFormat:@"%@/Videos/%lu",[[OEXSession activeSession] currentUser].username,(unsigned long)[url hash]];
    }
    return nil;
}

+(NSString *)userRelativePathForUrl:(NSString *)url andUserName:(NSString *)userName{
    
    return  [NSString stringWithFormat:@"%@/Videos/%lu",userName,(unsigned long)[url hash]];
    
}


+(NSString *) relativePathForUrl:(NSString *)url{
    
    if([OEXFileUtility userRelativePathForUrl:url]){
        return [NSString stringWithFormat:@"%@/%@",[[OEXFileUtility documentDir]lastPathComponent],[OEXFileUtility userRelativePathForUrl:url]];
    }
      return nil;
    
}

+(NSString *) completeFilePathForUrl:(NSString *)url{
    
    if([OEXFileUtility userRelativePathForUrl:url]){
        return [NSString stringWithFormat:@"%@/%@",[OEXFileUtility documentDir],[OEXFileUtility userRelativePathForUrl:url]];
    };
    
    return nil;
}


+(NSString *) completeFilePathForRelativePath:(NSString *)relativePath{
    if([[OEXSession activeSession] currentUser].username){
        return  [NSString stringWithFormat:@"%@/%@",[OEXFileUtility documentDir],relativePath];
    }
    return nil;
}


+(NSString *)completeFilePathForUrl:(NSString *)url andUserName:(NSString *)username{
    
    return [NSString stringWithFormat:@"%@/%@",[OEXFileUtility documentDir],[OEXFileUtility userRelativePathForUrl:url andUserName:username]];
}

+(BOOL )writeData:(NSData *)data atFilePath:(NSString *)filePath{
    
   //check if file already exists, delete it
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (!success) {
                //NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }
    
    //write new file
    if (![data writeToFile:filePath atomically:YES]) {
        ELog(@"There was a problem saving resume data to file ==>> %@",filePath);
        return NO;
    }
    
    return YES;
}

+(NSString *)localFilePathForVideoUrl:(NSString *)videoUrl{
  
    NSString *filepath=[[OEXFileUtility completeFilePathForUrl:videoUrl] stringByAppendingPathExtension:@"mp4"];
    
    return filepath;
}



@end
