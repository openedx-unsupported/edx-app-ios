//
//  FileUtility.m
//  edXVideoLocker
//
//  Created by Abhishek Bhagat on 14/11/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "FileUtility.h"
#import "UserDetails.h"
#pragma mark JSON Data
@implementation FileUtility


+ (NSData *)dataForURLString:(NSString *)URLString {
    
    NSString * filePath = [FileUtility completeFilePathForUrl:URLString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData * data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    return nil;
}

+ (NSData *)resumeDataForURLString:(NSString *)URLString {
    
    NSString * filePath = [FileUtility completeFilePathForUrl:URLString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData * data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    return nil;
}

+ (void)deleteResumeDataForURLString:(NSString *)URLString {
    
    NSString * filePath = [FileUtility completeFilePathForUrl:URLString];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }

}
    
    
+ (void)updateData:(NSData *)data ForURLString:(NSString *)URLString {
    //File path
    NSString * filePath = [FileUtility completeFilePathForUrl:URLString];
    [FileUtility writeData:data atFilePath:filePath];
}


+(NSString *) documentDir{
     NSString *documentDir=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
     return documentDir;
}

+(NSString *) userDirectory{
   
    NSString* userDirectory = [[FileUtility documentDir] stringByAppendingPathComponent:[UserDetails currentUser].username];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:userDirectory]) {
        NSError * error;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error]) {
        }
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError* error = nil;
        if(![[NSURL fileURLWithPath:userDirectory]
            setResourceValue: @YES forKey: NSURLIsExcludedFromBackupKey error: &error]) {
            ELog(@"ERROR : On disabling backup : %@",[error description]);
        }
    });
   return userDirectory;
    
}

+(NSString *) userDirectoryForUser:(NSString *)userName{
    
    NSString* userDirectory = [[FileUtility documentDir] stringByAppendingPathComponent:userName];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:userDirectory]) {
        NSError * error;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:userDirectory
                                       withIntermediateDirectories:NO
                                                        attributes:nil
                                                             error:&error]) {
        }
    }
    
    return userDirectory;
    
}


+(NSString *)userRelativePathForUrl:(NSString *)url{
    if([UserDetails currentUser].username){
        return  [NSString stringWithFormat:@"%@/Videos/%lu",[UserDetails currentUser].username,(unsigned long)[url hash]];
    }
    return nil;
}

+(NSString *)userRelativePathForUrl:(NSString *)url andUserName:(NSString *)userName{
    
    return  [NSString stringWithFormat:@"%@/Videos/%lu",userName,(unsigned long)[url hash]];
    
}


+(NSString *) relativePathForUrl:(NSString *)url{
    
    if([FileUtility userRelativePathForUrl:url]){
        return [NSString stringWithFormat:@"%@/%@",[[FileUtility documentDir]lastPathComponent],[FileUtility userRelativePathForUrl:url]];
    }
      return nil;
    
}

+(NSString *) completeFilePathForUrl:(NSString *)url{
    
    if([FileUtility userRelativePathForUrl:url]){
        return [NSString stringWithFormat:@"%@/%@",[FileUtility documentDir],[FileUtility userRelativePathForUrl:url]];
    };
    
    return nil;
}


+(NSString *) completeFilePathForRelativePath:(NSString *)relativePath{
    if([UserDetails currentUser].username){
        return  [NSString stringWithFormat:@"%@/%@",[FileUtility documentDir],relativePath];
    }
    return nil;
}


+(NSString *)completeFilePathForUrl:(NSString *)url andUserName:(NSString *)username{
    
    return [NSString stringWithFormat:@"%@/%@",[FileUtility documentDir],[FileUtility userRelativePathForUrl:url andUserName:username]];
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
  
    NSString *filepath=[[FileUtility completeFilePathForUrl:videoUrl] stringByAppendingPathExtension:@"mp4"];
    
    return filepath;
}



@end
