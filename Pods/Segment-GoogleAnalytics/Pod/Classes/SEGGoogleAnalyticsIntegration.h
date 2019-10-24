#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>


@interface SEGGoogleAnalyticsIntegration : NSObject <SEGIntegration>

@property (nonatomic, copy) NSDictionary *settings;
@property (nonatomic, copy) NSDictionary *traits;

- (id)initWithSettings:(NSDictionary *)settings;

@end
