//
//  ImageCache.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 05/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject
{
}
@property (nonatomic, strong) NSOperationQueue *imageQueue;
+ (id)sharedInstance;
-(UIImage *)getImage:(NSString *)imageURLString;
-(UIImage *)getImageFromCacheFromKey:(NSString *)imageURLKey;
-(UIImage *)getDiskImage:(NSString *)filePath;
@end
