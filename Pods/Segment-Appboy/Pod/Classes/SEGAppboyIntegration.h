#import <Foundation/Foundation.h>
#if __has_include(<Segment/SEGIntegration.h>)
#import <Segment/SEGIntegration.h>
#elif __has_include(<Analytics/SEGIntegration.h>)
#import <Analytics/SEGIntegration.h>
#elif __has_include("SEGIntegration.h")
#import "SEGIntegration.h"
#endif

@interface SEGAppboyIntegration : NSObject<SEGIntegration>

@property(nonatomic, strong, nullable) NSDictionary *settings;

- (nullable id)initWithSettings:(nonnull NSDictionary *)settings;
- (nullable id)initWithSettings:(nonnull NSDictionary *)settings appboyOptions:(nullable NSDictionary *)appboyOptions;

@end
