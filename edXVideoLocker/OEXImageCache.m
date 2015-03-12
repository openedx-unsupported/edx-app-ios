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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjectsFromMainCacheMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}

-(void)removeAllObjectsFromMainCacheMemory
{
    [_imageCache removeAllObjects];
    [_requestRecord removeAllObjects];
}

- (void)dealloc {
    self.imageQueue=nil;
    _imageCache=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
}

-(void)postImageCompleteNofificationWithImage:(UIImage *)image imageURL:(NSString *)imageURL
{
    NSDictionary *returnDict= @{OEXNotificationUserInfoObjectImageKey:image,OEXNotificationUserInfoObjectImageURLKey:imageURL};
    [[NSNotificationCenter defaultCenter] postNotificationName:OEXImageDownloadCompleteNotification object:returnDict];
}

-(void)getImage:(NSString *)imageURLString
{
    if(!imageURLString)
    {
        return;
    }
    NSString * filePath = [OEXFileUtility completeFilePathForUrl:imageURLString];
    __block UIImage *returnImage = [self getImageFromCacheFromKey:filePath];
    if(returnImage)
    {
        [self postImageCompleteNofificationWithImage:returnImage imageURL:imageURLString];
    }
    else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            
            [self.imageQueue addOperationWithBlock:^{
                NSData *data=[[NSFileManager defaultManager] contentsAtPath:filePath];
                returnImage = [UIImage imageWithData:data];
                if(data.length > OEXImageCacheMaxFileBytes){
                    NSData *compressData=[self compressImage:returnImage];
                    returnImage=nil;
                    returnImage=[UIImage imageWithData:compressData];
                    [self saveImageToDisk:compressData filePath:filePath];
                    returnImage = [UIImage imageWithData:compressData];
                }
                
                if(returnImage)
                {
                    [self setImageToCache:returnImage withKey:filePath];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self postImageCompleteNofificationWithImage:returnImage imageURL:imageURLString];
                    }];
                }
            }];
        }
        else
        {
            OEXInterface * dataInterface=[OEXInterface sharedInterface];
            if(dataInterface.reachable)
            {
                NSURL *imageURL=[NSURL URLWithString:imageURLString];
                if(imageURL){
                    if([[_requestRecord objectForKey:imageURLString ]boolValue])
                    {
                        ELog(@"Duplicate image download request. Already in progress");
                        return;
                    }
                    else
                    {
                        [_requestRecord setObject:@YES forKey:imageURLString];
                        [self.imageQueue addOperationWithBlock:^{
                            NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
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
                            }
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                
                                [_requestRecord removeObjectForKey:imageURLString];
                                if(returnImage)
                                {
                                    [self postImageCompleteNofificationWithImage:returnImage imageURL:imageURLString];
                                }
                            }];
                            
                        }];
                        
                    }
                }
            }
        }
        
    }
    return;
}
-(void)excludeiCloudImageBackup:(NSString *)path
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
        [self excludeiCloudImageBackup:filePath];
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

-(void)clearImagesFromMainCacheMemory
{
    [self removeAllObjectsFromMainCacheMemory];
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
