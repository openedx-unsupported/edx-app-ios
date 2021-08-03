#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const CORE_VERSION_WARNING = @"Attempting to download image but Braze image utilities not found. Make sure you chose the UI Subspec if you want to use Braze's UI.";

/*
 * This proxy class gives the Braze iOS SDK access to the SDWebImage framework.
 * 
 * NOTE:
 * This class requires SDWebImage version 4.0*.
 */
@interface ABKSDWebImageProxy : NSObject

+ (void)setImageForView:(UIImageView *)imageView
  showActivityIndicator:(BOOL)showActivityIndicator
                withURL:(nullable NSURL *)imageURL
       imagePlaceHolder:(nullable UIImage *)placeHolder
              completed:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error, NSInteger cacheType, NSURL * _Nullable imageURL))completion;
+ (void)loadImageWithURL:(nullable NSURL *)url
                 options:(NSInteger)options
               completed:(nullable void(^)(UIImage *image, NSData *data, NSError *error, NSInteger cacheType, BOOL finished, NSURL *imageURL))completion;
+ (void)diskImageExistsForURL:(nullable NSURL *)url
                   completed:(nullable void (^)(BOOL isInCache))completion;
+ (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url;
+ (void)removeSDWebImageForKey:(nullable NSString *)key;
+ (nullable UIImage *)imageFromCacheForKey:(nullable NSString *)key;
+ (void)clearSDWebImageCache;
+ (BOOL)isSupportedSDWebImageVersion;

@end
NS_ASSUME_NONNULL_END
