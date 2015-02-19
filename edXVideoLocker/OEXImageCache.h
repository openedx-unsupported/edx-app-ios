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
+ (instancetype)sharedInstance;
-(void)getImage:(NSString *)imageURLString completionBlock:(void (^)(UIImage *displayImage, NSError *error))completionBlock;
-(void)clearImagesFromMainCacheMemory;
@end
