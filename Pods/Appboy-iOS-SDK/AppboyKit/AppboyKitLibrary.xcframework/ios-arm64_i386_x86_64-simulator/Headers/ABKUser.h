//
//  ABKUser.h
//  AppboySDK

#import <Foundation/Foundation.h>

@class ABKFacebookUser;
@class ABKTwitterUser;
@class ABKAttributionData;

NS_ASSUME_NONNULL_BEGIN
/* ------------------------------------------------------------------------------------------------------
 * Enums
 */

/*!
 * Genders recognized by the SDK.
 */
typedef NS_ENUM(NSInteger, ABKUserGenderType) {
  ABKUserGenderMale,
  ABKUserGenderFemale,
  ABKUserGenderOther,
  ABKUserGenderUnknown,
  ABKUserGenderNotApplicable,
  ABKUserGenderPreferNotToSay
};

/*!
 * Convenience enum to represent notification status, for email and push notifications.
 *
 * OPTED_IN: subscribed, and explicitly opted in.
 * SUBSCRIBED: subscribed, but not explicitly opted in.
 * UNSUBSCRIBED: unsubscribed and/or explicitly opted out.
 */
typedef NS_ENUM(NSInteger, ABKNotificationSubscriptionType) {
  ABKOptedIn,
  ABKSubscribed,
  ABKUnsubscribed
};

/*!
 * When setting the custom attributes with custom keys:
 * 1. The maximum key length is 255 characters; longer keys are truncated.
 * 2. The maximum length for a string value in a custom attribute is 255 characters; longer values are truncated.
 */

/*
 * Braze Public API: ABKUser
 */
@interface ABKUser : NSObject

/*!
 * The User's first name (String)
 */
@property (nonatomic, copy, nullable) NSString *firstName;

/*!
 * The User's last name (String)
 */
@property (nonatomic, copy, nullable) NSString *lastName;

/*!
 * The User's email (String)
 */
@property (nonatomic, copy, nullable) NSString *email;

/*!
 * The User's date of birth (NSDate)
 */
@property (nonatomic, copy, nullable) NSDate *dateOfBirth;

/*!
 * The User's country (String)
 */
@property (nonatomic, copy, nullable) NSString *country;

/*!
 * The User's home city (String)
 */
@property (nonatomic, copy, nullable) NSString *homeCity;

/*!
 * The User's language (String)
 *
 * Language Strings should be valid ISO 639-1 language codes.
 * See https://www.loc.gov/standards/iso639-2/php/code_list.php.
 *
 * If not set here, user language will be inferred from the device language.
 */
@property (nonatomic, copy, nullable) NSString *language;

/*!
 * The User's phone number (String)
 */
@property (nonatomic, copy, nullable) NSString *phone;

@property (nonatomic, copy, nullable, readonly) NSString *userID;

/*!
 * The User's avatar image URL. This URL will be processed by the server and used in their user profile on the
 * dashboard. (String)
 */
@property (nonatomic, copy, nullable) NSString *avatarImageURL;

/*!
 * The User's Facebook account information. For more detail, please refer to ABKFacebookUser.h.
 */
@property (strong, nullable) ABKFacebookUser *facebookUser;

/*!
 * The User's Twitter account information. For more detail, please refer to ABKTwitterUser.h.
 */
@property (strong, nullable) ABKTwitterUser *twitterUser;

/*!
 * Sets the attribution information for the user. For in apps that have an install tracking integration.
 * For more information, please refer to ABKAttributionData.h.
 */
@property (strong, nullable) ABKAttributionData *attributionData;

/*!
 * Adds an an alias for the current user.  Individual (alias, label) pairs can exist on one and only one user.
 * If a different user already has this alias or external user id, the alias attempt will be rejected
 * on the server.
 *
 * @param alias The alias of the current user.
 * @param label The label of the alias; used to differentiate it from other aliases for the user.
 * @return Whether or not the alias and label are valid. Does not guarantee they won't collide with
 *         an existing pair.
 */
- (BOOL)addAlias:(NSString *)alias withLabel:(NSString *)label;

/*!
 * @param gender ABKUserGender enum representing the user's gender.
 * @return YES if the user gender is set properly
 */
- (BOOL)setGender:(ABKUserGenderType)gender;

/*!
 * Sets whether or not the user should be sent email campaigns. Setting it to unsubscribed opts the user out of
 * an email campaign that you create through the Braze dashboard.
 *
 * @param emailNotificationSubscriptionType enum representing the user's email notifications subscription type.
 * @return YES if the field is set successfully, else NO.
 */
- (BOOL)setEmailNotificationSubscriptionType:(ABKNotificationSubscriptionType)emailNotificationSubscriptionType;

/*!
 * Sets the push notification subscription status of the user. Used to collect information about the user.
 *
 * @param pushNotificationSubscriptionType enum representing the user's push notifications subscription type.
 * @return YES if the field is set successfully, else NO.
 */
- (BOOL)setPushNotificationSubscriptionType:(ABKNotificationSubscriptionType)pushNotificationSubscriptionType;

/*!
 * Adds the user to a Subscription Group.
 *
 * @param groupId The string UUID corresponding to the subscription group, provided by the Braze dashboard.
 * @return YES if the user was successfully added, else NO. If not, the groupId might have been nil or invalid.
 */
- (BOOL)addToSubscriptionGroupWithGroupId:(NSString *)groupId;

/*!
 * Removes the user from a Subscription Group.
 *
 * @param groupId The string UUID corresponding to the subscription group, provided by the Braze dashboard.
 * @return YES if the user was successfully removed, else NO. If not, the groupId might have been nil or invalid.
 */
- (BOOL)removeFromSubscriptionGroupWithGroupId:(NSString *)groupId;

/*!
 * @param key The String name of the custom user attribute
 * @param value A boolean value to set as a custom attribute
 * @return whether or not the custom user attribute was set successfully; If not, your key might have been nil or empty,
 *         your value might have been invalid (either nil, or not of the correct type), or you tried to set a value for
 *         one of the reserved keys. Please check the log for more details about the specific failure you encountered.
 */
- (BOOL)setCustomAttributeWithKey:(NSString *)key andBOOLValue:(BOOL)value;

/*!
 * @param key The String name of the custom user attribute
 * @param value An integer value to set as a custom attribute
 * @return whether or not the custom user attribute was set successfully; If not, your key might have been nil or empty,
 *         your value might have been invalid (either nil, or not of the correct type), or you tried to set a value for
 *         one of the reserved keys. Please check the log for more details about the specific failure you encountered.
 */
- (BOOL)setCustomAttributeWithKey:(NSString *)key andIntegerValue:(NSInteger)value;

/*!
 * @param key The String name of the custom user attribute
 * @param value A double value to set as a custom attribute
 * @return whether or not the custom user attribute was set successfully; If not, your key might have been nil or empty,
 *         your value might have been invalid (either nil, or not of the correct type), or you tried to set a value for
 *         one of the reserved keys. Please check the log for more details about the specific failure you encountered.
 */
- (BOOL)setCustomAttributeWithKey:(NSString *)key andDoubleValue:(double)value;

/*!
 * @param key The String name of the custom user attribute
 * @param value An NSString value to set as a custom attribute
 * @return whether or not the custom user attribute was set successfully; If not, your key might have been nil or empty,
 *         your value might have been invalid (either nil, or not of the correct type), or you tried to set a value for
 *         one of the reserved keys. Please check the log for more details about the specific failure you encountered.
 */
- (BOOL)setCustomAttributeWithKey:(NSString *)key andStringValue:(NSString *)value;

/*!
 * @param key The String name of the custom user attribute
 * @param value An NSDate value to set as a custom attribute
 * @return whether or not the custom user attribute was set successfully; If not, your key might have been nil or empty,
 *         your value might have been invalid (either nil, or not of the correct type), or you tried to set a value for
 *         one of the reserved keys. Please check the log for more details about the specific failure you encountered.
 */
- (BOOL)setCustomAttributeWithKey:(NSString *)key andDateValue:(NSDate *)value;

/*!
 * @param key The String name of the custom user attribute to unset
 * @return whether or not the custom user attribute was unset successfully
 */
- (BOOL)unsetCustomAttributeWithKey:(NSString *)key;

/**
   * Increments the value of an custom attribute by one. Only integer and long custom attributes can be incremented.
   * Attempting to increment a custom attribute that is not an integer or a long will be ignored. If you increment a
   * custom attribute that has not previously been set, a custom attribute will be created and assigned a value of one.
   *
   * @param key The identifier of the custom attribute
   * @return YES if the increment for the custom attribute of given key is saved
   */
- (BOOL)incrementCustomUserAttribute:(NSString *)key;

/**
 * Increments the value of an custom attribute by a given amount. Only integer and long custom attributes can be
 * incremented. Attempting to increment a custom attribute that is not an integer or a long will be ignored. If
 * you increment a custom attribute that has not previously been set, a custom attribute will be created and assigned
 * the value of incrementValue. To decrement the value of a custom attribute, use a negative incrementValue.
 *
 * @param key The identifier of the custom attribute
 * @param incrementValue The amount by which to increment the custom attribute
 * @return YES if the increment for the custom attribute of given key is saved
 */
- (BOOL)incrementCustomUserAttribute:(NSString *)key by:(NSInteger)incrementValue;

/**
 * Adds the string value to a custom attribute string array specified by the key. If you add a key that has not
 * previously been set, a custom attribute string array will be created containing the value.
 *
 * @param key The custom attribute key
 * @param value A string to be added to the custom attribute string array
 * @return YES if the operation was successful
 */
- (BOOL)addToCustomAttributeArrayWithKey:(NSString *)key value:(NSString *)value;

/**
 * Removes the string value from a custom attribute string array specified by the key. If you remove a key that has not
 * previously been set, nothing will be changed.
 *
 * @param key The custom attribute key
 * @param value A string to be removed from the custom attribute string array
 * @return YES if the operation was successful
 */
- (BOOL)removeFromCustomAttributeArrayWithKey:(NSString *)key value:(NSString *)value;

/**
 * Sets a string array from a custom attribute specified by the key.
 *
 * @param key The custom attribute key
 * @param valueArray A string array to set as a custom attribute. If this value is nil, then Braze will unset the custom
 *        attribute and remove the corresponding array if there is one.
 * @return YES if the operation was successful
 */
- (BOOL)setCustomAttributeArrayWithKey:(NSString *)key array:(nullable NSArray *)valueArray;

/*!
* Sets the last known location for the user. Intended for use with ABKDisableLocationAutomaticTrackingOptionKey set to YES
* when starting Braze, so that the only locations being set are by the integrating app.  Otherwise, calls to this
* method will be contending with automatic location update events.
*
* @param latitude The latitude of the User's location in degrees, the number should be in the range of [-90, 90]
* @param longitude The longitude of the User's location in degrees, the number should be in the range of [-180, 180]
* @param horizontalAccuracy The accuracy of the User's horizontal location in meters, the number should not be negative
*/
- (BOOL)setLastKnownLocationWithLatitude:(double)latitude longitude:(double)longitude horizontalAccuracy:(double)horizontalAccuracy;

/*!
* Sets the last known location for the user. Intended for use with ABKDisableLocationAutomaticTrackingOptionKey set to YES
* when starting Braze, so that the only locations being set are by the integrating app.  Otherwise, calls to this
* method will be contending with automatic location update events.
*
* @param latitude The latitude of the User's location in degrees, the number should be in the range of [-90, 90]
* @param longitude The longitude of the User's location in degrees, the number should be in the range of [-180, 180]
* @param horizontalAccuracy The accuracy of the User's horizontal location in meters, the number should not be negative
* @param altitude The altitude of the User's location in meters
* @param verticalAccuracy The accuracy of the User's vertical location in meters, the number should not be negative
*/
- (BOOL)setLastKnownLocationWithLatitude:(double)latitude
                               longitude:(double)longitude
                      horizontalAccuracy:(double)horizontalAccuracy
                                altitude:(double)altitude
                        verticalAccuracy:(double)verticalAccuracy;

/*!
 * Adds the location custom attribute for the user.
 *
 * @param key The custom attribute key
 * @param latitude The latitude of the location in degrees, the number should be in the range of [-90, 90]
 * @param longitude The longitude of the location in degrees, the number should be in the range of [-180, 180]
 */
- (BOOL)addLocationCustomAttributeWithKey:(NSString *)key
                                 latitude:(double)latitude
                                longitude:(double)longitude;

/*!
 * Removes the location custom attribute for the user.
 *
 * @param key The custom attribute key
 */
- (BOOL)removeLocationCustomAttributeWithKey:(NSString *)key;

@end
NS_ASSUME_NONNULL_END
