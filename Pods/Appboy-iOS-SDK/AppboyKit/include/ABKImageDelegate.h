#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/*
 * This delegate protocol gives the Braze iOS SDK access to the image framework.
 */

typedef NS_OPTIONS(NSUInteger, ABKImageOptions ) {
   ABKImageOptionsRetryFailed = 1 << 0,
   ABKImageOptionsLowPriority = 1 << 1,
   ABKImageOptionsCacheMemoryOnly = 1 << 2,
   ABKImageOptionsProgressiveDownload = 1 << 3,
   ABKImageOptionsRefreshCached = 1 << 4,
   ABKImageOptionsContinueInBackground = 1 << 5,
   ABKImageOptionsHandleCookies = 1 << 6,
};

@protocol ABKImageDelegate

- (void)setImageForView:(UIImageView *)imageView
  showActivityIndicator:(BOOL)showActivityIndicator
                withURL:(nullable NSURL *)imageURL
       imagePlaceHolder:(nullable UIImage *)placeHolder
              completed:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error, NSInteger cacheType, NSURL * _Nullable imageURL))completion;

- (void)loadImageWithURL:(nullable NSURL *)url
                 options:(ABKImageOptions)options
               completed:(nullable void(^)(UIImage *image, NSData *data, NSError *error, NSInteger cacheType, BOOL finished, NSURL *imageURL))completion;

- (void)diskImageExistsForURL:(nullable NSURL *)url
                   completed:(nullable void (^)(BOOL isInCache))completion;

- (nullable UIImage *)imageFromCacheForURL:(nullable NSURL *)url;

/*!
 * @discussion Returns a class that is UIImageView or a subclass of UIImageView to allow the implementor to bring their own
 * implementation of animated image support.
 */
- (Class)imageViewClass;

@end
NS_ASSUME_NONNULL_END
