#import "ABKLocationManagerProvider.h"

#if !TARGET_OS_TV
#import <CoreLocation/CoreLocation.h>
#endif

@implementation ABKLocationManagerProvider

+ (BOOL)locationServicesEnabled {
#if !TARGET_OS_TV
  return YES;
#endif
  return NO;
}

@end
