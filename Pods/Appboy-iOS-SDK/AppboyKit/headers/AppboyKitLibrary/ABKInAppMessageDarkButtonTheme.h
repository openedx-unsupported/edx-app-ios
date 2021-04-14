#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ABKInAppMessageDarkButtonTheme : NSObject

/*!
 * Dark theme of the button's background color.
 */
@property (strong) UIColor *buttonBackgroundColor;

/*!
 * Dark theme of the button's border color.
 */
@property (strong) UIColor *buttonBorderColor;

/*!
 * Dark theme of the button's text color.
 */
@property (strong) UIColor *buttonTextColor;

/*!
 * Creates a model containing the dark theme colors for buttons by parsing the dictionary `darkButtonFields`
 */
- (instancetype)initWithFields:(NSDictionary *)darkButtonFields;

@end

NS_ASSUME_NONNULL_END
