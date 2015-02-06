//
//  ImageCache.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 05/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXImageCache.h"
#import "OEXInterface.h"

@interface OEXImageCache()
{
    NSCache *_imageCache;
    CGFloat maxFileSize;
}
@end


@implementation OEXImageCache

+ (instancetype)sharedInstance {
    static OEXImageCache *singletonInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [[self alloc] init];
    });
    return singletonInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _imageCache =[[NSCache alloc]init];
        self.imageQueue = [[NSOperationQueue alloc] init];
        maxFileSize=100*1024;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjectsFromCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}

-(void)removeAllObjectsFromCache
{
    [_imageCache removeAllObjects];
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    self.imageQueue=nil;
    _imageCache=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

}

-(void)getImage:(NSString *)imageURLString completionBlock:(void (^)(UIImage *displayImage))completionBlock
{
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:imageURLString];
   __block UIImage *returnImage = [self getImageFromCacheFromKey:filePath];
    if(returnImage)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // if the cell is visible, then set the image
            completionBlock(returnImage);
            return ;
            
        }];
    }
    else {
        
        [self.imageQueue addOperationWithBlock:^{
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                returnImage = [UIImage imageWithContentsOfFile:filePath];
                if(returnImage)
                {
                    if(returnImage)
                        [self setImageToCache:returnImage withKey:filePath];
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        // if the cell is visible, then set the image
                        completionBlock(returnImage);
                        return ;
                        
                    }];
                }
            }
            else
            {
                OEXInterface * dataInterface=[OEXInterface sharedInterface];
                if(dataInterface.reachable)
                {
                    NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURLString]];
                    if(imageData)
                    {
                        returnImage = [UIImage imageWithData:imageData];
                        if(imageData.length>(maxFileSize))
                        {
                            NSData *compressData=[self compressImage:returnImage];
                            returnImage=nil;
                            returnImage=[UIImage imageWithData:compressData];
                            //write new file
                            if (![compressData writeToFile:filePath atomically:YES]) {
                                //ELog(@"There was a problem saving json to file");
                            }
                        }
                        else
                        {
                            //write new file
                            if (![imageData writeToFile:filePath atomically:YES]) {
                                //ELog(@"There was a problem saving json to file");
                            }
                        }
                        
                        
                        if(returnImage)
                            [self setImageToCache:returnImage withKey:filePath];
                        
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            // if the cell is visible, then set the image
                            completionBlock(returnImage);
                            return ;
                            
                        }];

                        
                    }
                    
                }
                
            }
            
        }];

    }
    
    return;
    
}




-(NSData *)compressImage:(UIImage *)image{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = [UIScreen mainScreen].bounds.size.height;
    float maxWidth = [UIScreen mainScreen].bounds.size.width;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 1.0;
    
    if (actualHeight > maxHeight || actualWidth > maxWidth){
        if(imgRatio < maxRatio){
            //adjust width according to maxHeight
            imgRatio = maxHeight / actualHeight;
            actualWidth = imgRatio * actualWidth;
            actualHeight = maxHeight;
        }
        else if(imgRatio > maxRatio){
            //adjust height according to maxWidth
            imgRatio = maxWidth / actualWidth;
            actualHeight = imgRatio * actualHeight;
            actualWidth = maxWidth;
        }
        else{
            actualHeight = maxHeight;
            actualWidth = maxWidth;
        }
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
    UIGraphicsBeginImageContext(rect.size);
    [image drawInRect:rect];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImageJPEGRepresentation(img, compressionQuality);
    UIGraphicsEndImageContext();
    
    return imageData;
}


-(void)setImageToCache:(UIImage *)image withKey:(NSString *)key
{
    [_imageCache setObject:image forKey:key];
}

-(UIImage *)getImageFromCacheFromKey:(NSString *)imageURLKey
{
    
    return [_imageCache objectForKey:imageURLKey];
}


@end
