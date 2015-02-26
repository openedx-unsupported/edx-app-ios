//
//  ImageCache.h
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 05/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
static NSString  *OEXImageDownloadCompleteNotification = @"ImageDownloadComplete";

static const NSString  *OEXNotificationUserInfoObjectImageKey = @"image";
static const NSString  *OEXNotificationUserInfoObjectImageURLKey = @"image_url";


@interface OEXImageCache : NSObject
{
}
+ (instancetype)sharedInstance;
-(void)getImage:(NSString *)imageURLString;
-(void)clearImagesFromMainCacheMemory;
@end
