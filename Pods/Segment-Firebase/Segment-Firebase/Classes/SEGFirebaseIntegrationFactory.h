#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegrationFactory.h>


@interface SEGFirebaseIntegrationFactory : NSObject <SEGIntegrationFactory>

+ (instancetype)instance;

@end
