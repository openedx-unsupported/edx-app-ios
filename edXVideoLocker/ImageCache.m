//
//  ImageCache.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 05/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "ImageCache.h"
#import "OEXInterface.h"

#define kMaxFileSize 100*1024

@interface ImageCache()
{
 //   NSCache *_imageCache;
}
@end


@implementation ImageCache

+ (id)sharedInstance {
    static ImageCache *singletonInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [[self alloc] init];
    });
    return singletonInstance;
}

- (id)init {
    if (self = [super init]) {
       // _imageCache =[[NSCache alloc]init];
        self.imageQueue = [[NSOperationQueue alloc] init];
        self.imageQueue.maxConcurrentOperationCount = 4;
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjectsFromCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}

-(void)removeAllObjectsFromCache
{
   // [_imageCache removeAllObjects];
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    self.imageQueue=nil;
   // _imageCache=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

}


-(UIImage *)getDiskImage:(NSString *)filePath
{
    UIImage *returnImage = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData * imageData = [[NSData alloc]initWithContentsOfFile:filePath];
        if(imageData)
        {
            returnImage = [UIImage imageWithData:imageData];
            return returnImage;
        }
    }
    return returnImage;
}

-(UIImage *)getImage:(NSString *)imageURLString
{
    
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:imageURLString];
    UIImage *diskImage=[self getDiskImage:filePath];
    if(diskImage)
    {
        return diskImage;
    }
    else
    {
        OEXInterface * dataInterface=[OEXInterface sharedInterface];
        if(dataInterface.reachable)
        {
            NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURLString]];
            if(imageData)
            {
                //check if file already exists, delete it
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    NSError *error;
                    if ([[NSFileManager defaultManager] isDeletableFileAtPath:filePath]) {
                        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                        if (!success) {
                            //ELog(@"Error removing file at path: %@", error.localizedDescription);
                        }
                    }
                }
                 UIImage *returnImage = [UIImage imageWithData:imageData];
                if(imageData.length>(kMaxFileSize))
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
                
               
               // if(returnImage)
                 //  [self setImageToCache:returnImage withKey:filePath];
                return returnImage;
            }

        }
       
    }
    return nil;
}

-(NSData *)compressImage:(UIImage *)image{
    float actualHeight = image.size.height;
    float actualWidth = image.size.width;
    float maxHeight = 600.0;
    float maxWidth = 600.0;
    float imgRatio = actualWidth/actualHeight;
    float maxRatio = maxWidth/maxHeight;
    float compressionQuality = 0.5;//50 percent compression
    
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
    //[_imageCache setObject:image forKey:key];
}

-(UIImage *)getImageFromCacheFromKey:(NSString *)imageURLKey
{
    
    return nil;
    //return [_imageCache objectForKey:imageURLKey];
    
}


@end
