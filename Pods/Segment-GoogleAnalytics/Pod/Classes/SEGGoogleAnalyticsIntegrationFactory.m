#import "SEGGoogleAnalyticsIntegrationFactory.h"
#import "SEGGoogleAnalyticsIntegration.h"


@implementation SEGGoogleAnalyticsIntegrationFactory

+ (instancetype)instance
{
    static dispatch_once_t once;
    static SEGGoogleAnalyticsIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    return self;
}

- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(SEGAnalytics *)analytics
{
    return [[SEGGoogleAnalyticsIntegration alloc] initWithSettings:settings];
}

- (NSString *)key
{
    return @"Google Analytics";
}

@end
