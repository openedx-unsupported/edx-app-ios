//
//  ImageCache.m
//  edXVideoLocker
//
//  Created by Prashant Kurhade on 05/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXImageCache.h"
#import "OEXInterface.h"

static const CGFloat OEXImageCacheMaxFileBytes = 100 * 1024;


@interface OEXImageCache()
{
    NSCache *_imageCache;
    
    NSMutableDictionary *_requestRecord;
}
@property (nonatomic, strong) NSOperationQueue *imageQueue;
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
        _requestRecord=[[NSMutableDictionary alloc]init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjectsFromCache) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}

-(void)removeAllObjectsFromCache
{
    [_imageCache removeAllObjects];
    [_requestRecord removeAllObjects];
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
    self.imageQueue=nil;
    _imageCache=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

}

-(void)getImage:(NSString *)imageURLString completionBlock:(void (^)(UIImage *displayImage))completionBlock
{
    if(!imageURLString)
    {
        completionBlock(nil);
        return;
    }
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
                    NSURL *imageURL=[NSURL URLWithString:imageURLString];
                    {
                        if([[_requestRecord valueForKey:imageURLString ]boolValue])
                        {
                            ELog(@"Duplicate image download request. Already in progress");
                            completionBlock(nil);
                            return;
                        }
                        [_requestRecord setValue:[NSNumber numberWithBool:YES] forKey:imageURLString];
                        
                        NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
                        [_requestRecord removeObjectForKey:imageURLString];
                        if(imageData)
                        {
                            returnImage = [UIImage imageWithData:imageData];
                            if(imageData.length>(OEXImageCacheMaxFileBytes))
                            {
                                NSData *compressData=[self compressImage:returnImage];
                                returnImage=nil;
                                returnImage=[UIImage imageWithData:compressData];
                                [self saveImageToDisk:compressData filePath:filePath];
                                
                            }
                            else
                            {
                                [self saveImageToDisk:imageData filePath:filePath];
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
            }
            
        }];
    }
    return;
}
-(void)exludeiCloudImageBackup:(NSString *)path
{
    NSError *err = nil; // Exclude This Image from the iCloud backup system
    NSURL *imageURL=[NSURL fileURLWithPath:path];
    if(imageURL)
    {
        BOOL excluded = [imageURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&err];
        
        if (!excluded) {
            ELog(@"Failed to exclude from backup");
        } else {
            ELog(@"Excluding from backup"); // this works...
        }
    }
}

-(void)saveImageToDisk:(NSData *)imageData filePath:(NSString *)filePath{
    //write new file
    if ([imageData writeToFile:filePath atomically:YES]) {
        [self exludeiCloudImageBackup:filePath];
    }
    else
    {
        ELog(@"Problem while saving image on disk");
    }
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

-(void)clearImageCache
{
    [self removeAllObjectsFromCache];
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
