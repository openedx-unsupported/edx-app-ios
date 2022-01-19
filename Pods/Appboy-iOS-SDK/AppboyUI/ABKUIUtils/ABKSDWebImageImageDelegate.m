#import "ABKSDWebImageImageDelegate.h"
#import "ABKSDWebImageProxy.h"
#import <SDWebImage/SDAnimatedImageView+WebCache.h>

@implementation ABKSDWebImageImageDelegate

- (void)setImageForView:(UIImageView *)imageView
  showActivityIndicator:(BOOL)showActivityIndicator
                withURL:(nullable NSURL *)imageURL
       imagePlaceHolder:(nullable UIImage *)placeHolder
              completed:(nullable void (^)(UIImage * _Nullable image, NSError * _Nullable error, NSInteger cacheType, NSURL * _Nullable imageURL))completion {
  [ABKSDWebImageProxy setImageForView:imageView
                showActivityIndicator:showActivityIndicator
                              withURL:imageURL
                     imagePlaceHolder:placeHolder
                            completed:completion];
}

- (void)loadImageWithURL:(nullable NSURL *)url
                 options:(ABKImageOptions)options
               completed:(nullable void(^)(UIImage *image, NSData *data, NSError *error, NSInteger cacheType, BOOL finished, NSURL *imageURL))completion {
  [ABKSDWebImageProxy loadImageWithURL:url
                               options:options
                             completed:completion];
}

- (void)diskImageExistsForURL:(nullable NSURL *)url
                    completed:(nullable void (^)(BOOL isInCache))completion {
  [ABKSDWebImageProxy diskImageExistsForURL:url
                                  completed:completion];
}

- (nullable UIImage *)imageFromCacheForURL:(nullable NSURL *)url {
  return [ABKSDWebImageProxy imageFromCacheForKey:[ABKSDWebImageProxy cacheKeyForURL:url]];
}

- (Class)imageViewClass {
  return [SDAnimatedImageView class];
}

@end
