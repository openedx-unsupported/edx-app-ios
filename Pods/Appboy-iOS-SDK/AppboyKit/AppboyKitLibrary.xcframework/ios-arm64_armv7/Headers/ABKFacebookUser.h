#import <Foundation/Foundation.h>
#import "ABKUser.h"

NS_ASSUME_NONNULL_BEGIN
extern NSInteger const DefaultNumberOfFriends;

/*
 * Braze Public API: ABKFacebookUser
 */
@interface ABKFacebookUser : NSObject

/*!
 * @param facebookUserDictionary The dictionary returned from facebook with facebook graph api endpoint "/me". Please
 * refer to https://developers.facebook.com/docs/graph-api/reference/v4.0/user for more information.
 * @param numberOfFriends The length of the friends array from facebook. You can get the array from the dictionary returned
 * from facebook with facebook graph api endpoint "/me/friends", under the key "data". Please refer to
 * https://developers.facebook.com/docs/graph-api/reference/v4.0/user/friends for more information.
 * @param likes The array of user's facebook likes from facebook. You can get the array from the dictionary returned
 * from facebook with facebook graph api endpoint "/me/likes", under the key "data"; Please refer to
 * https://developers.facebook.com/docs/graph-api/reference/v4.0/user/likes for more information.
 *
 * @discussion: This method is to generate a ABKFacebookUser so you can pass the user's facebook account data to Braze.
 * After a ABKFacebookUser object is generated, you can check the value of properties but you cannot change it.
 * If you want to update the user's facebook data, you need to generate a new ABKFacebookUser instance and set it as
 * [Appboy sharedInstance].user.facebookUser.
 */
- (instancetype)initWithFacebookUserDictionary:(nullable NSDictionary *)facebookUserDictionary
                     numberOfFriends:(NSInteger)numberOfFriends
                               likes:(nullable NSArray *)likes;

@property (readonly, nullable) NSDictionary *facebookUserDictionary;
@property (readonly) NSInteger numberOfFriends;
@property (readonly, nullable) NSArray *likes;

@end
NS_ASSUME_NONNULL_END
