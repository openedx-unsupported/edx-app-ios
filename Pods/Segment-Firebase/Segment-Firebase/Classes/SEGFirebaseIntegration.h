//
//  SEGFirebaseIntegration.h
//  Pods
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>


@interface SEGFirebaseIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, strong) Class firebaseClass;

- (id)initWithSettings:(NSDictionary *)settings;
- (id)initWithSettings:(NSDictionary *)settings andFirebase:(id)firebaseClass;


@end
