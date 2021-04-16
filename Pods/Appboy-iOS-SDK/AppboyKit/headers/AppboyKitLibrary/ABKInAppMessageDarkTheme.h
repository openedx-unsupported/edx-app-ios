#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ABKInAppMessageButton;
@class ABKInAppMessageDarkButtonTheme;

NS_ASSUME_NONNULL_BEGIN

@interface ABKInAppMessageDarkTheme : NSObject

/* Properties of all ABKInAppMessages */
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

@property (nonatomic, strong, nullable) UIColor *textColor;

@property (nonatomic, strong, nullable) UIColor *iconColor;

@property (nonatomic, strong, nullable) UIColor *iconBackgroundColor;

/* ABKInAppMessageImmersive only */
@property (nonatomic, strong, nullable) UIColor *headerTextColor;

@property (nonatomic, strong, nullable) UIColor *closeButtonColor;

@property (nonatomic, strong, nullable) UIColor *frameColor;

/*!
 * An array of all the button color properties, in the same order as the buttons object in ABKInAppImmersive
 */
@property (nonatomic, strong, nullable) NSArray<ABKInAppMessageDarkButtonTheme *> *buttons;

/*!
 * Data model storing all the Dark Theme values passed down from the server for an in-app message.
 * This only gets initalized if the campaign is set up to support Dark Theme and has the fields populated.
 */
- (instancetype)initWithFields:(NSDictionary<NSString *, NSString *> *)darkThemeFields;

/*!
 * Returns the dark color variant given a valid key. If the key isn't found, returns nil.
 */
- (UIColor *)getColorForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
