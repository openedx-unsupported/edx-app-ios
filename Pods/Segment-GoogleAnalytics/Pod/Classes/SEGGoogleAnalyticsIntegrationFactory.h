#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegrationFactory.h>


@interface SEGGoogleAnalyticsIntegrationFactory : NSObject <SEGIntegrationFactory>

+ (instancetype)instance;

@end
