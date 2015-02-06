//
//  ImageCache.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 05/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXImageCache : NSObject
{
}
@property (nonatomic, strong) NSOperationQueue *imageQueue;
+ (instancetype)sharedInstance;
-(UIImage *)getImage:(NSString *)imageURLString;
-(UIImage *)getImageFromCacheFromKey:(NSString *)imageURLKey;
@end
