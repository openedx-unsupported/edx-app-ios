#import <Foundation/Foundation.h>

/*
 * Braze Public API: ABKTwitterUser
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKTwitterUser : NSObject

/*!
 * The value returned from Twitter's Users API with key "description". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property (copy, nullable) NSString* userDescription;

/*!
 * The value returned from Twitter's Users API with key "name". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property (copy, nullable) NSString* twitterName;

/*!
 * The value returned from Twitter's Users API with key "profile_image_url". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property (copy, nullable) NSString* profileImageUrl;

/*!
 * The value returned from Twitter's Users API with key "screen_name". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property (copy, nullable) NSString* screenName;

/*!
 * The value returned from Twitter's Users API with key "followers_count". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property NSInteger followersCount;

/*!
 * The value returned from Twitter's Users API with key "friends_count". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property NSInteger friendsCount;

/*!
 * The value returned from Twitter's Users API with key "statuses_count". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property NSInteger statusesCount;

/*!
 * The value returned from Twitter's Users API with key "id". Please refer to
 * https://dev.twitter.com/overview/api/users for more information.
 */
@property NSInteger twitterID;

@end
NS_ASSUME_NONNULL_END
