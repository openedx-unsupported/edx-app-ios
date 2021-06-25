#import "ABKInAppMessage.h"

@class ABKInAppMessageButton;

/*
 * Braze Public API: ABKInAppMessageImmersive
 */
NS_ASSUME_NONNULL_BEGIN

/*!
 * The ABKInAppMessageImmersiveImageStyle defines the image style of the in-app message
 *
 *   ABKInAppMessageGraphic - The image will make up the entire in-app message, with buttons on the
 *     image(buttons are optional). No icons, headers or message will be displayed in this style.
 *
 *
 *   ABKInAppMessageTopImage - This is the default image style. The image will be on upper top of the
 *     in-app message if there is one, with all other in-app message elements.
 */
typedef NS_ENUM(NSInteger, ABKInAppMessageImmersiveImageStyle) {
  ABKInAppMessageGraphic,
  ABKInAppMessageTopImage
};

@interface ABKInAppMessageImmersive : ABKInAppMessage

/*!
 * header defines the header text of the in-app message.
 * The header will only be displayed in one line on the default Braze in-app messages. If the header is more than one
 * line, it will be truncated at the end.
 */
@property (copy, nullable) NSString *header;

/*!
 * headerTextColor defines the header text color, when there is a header string in the in-app message. The default text color
 * is black.
 */
@property (nonatomic, strong, nullable) UIColor *headerTextColor;

/*!
 * closeButtonColor defines the close button color of the in-app message.
 * When this property is nil, the close button's default color is black.
 */
@property (nonatomic, strong, nullable) UIColor *closeButtonColor;

/*!
 * buttons defines the buttons of the in-app message.
 * Each button must be an instance of ABKInAppMessageButton.
 * When there are more than two buttons in the array, only the first two buttons will be displayed in the in-app message.
 * For more information and setting of ABKInAppMessageButton, please see the documentation in ABKInAppMessageButton.h for additional details.
 */
@property (readonly, copy, nullable) NSArray<ABKInAppMessageButton *> *buttons;

/*!
 * frameColor defines the frame color of an immersive in-app message. This color will fill the
 * screen outside of the in-app message. When the property is nil, the color will be
 * set to the default color, which is black with 90% opacity.
 */
@property (nonatomic, strong, nullable) UIColor *frameColor;

/*!
 * headerTextAlignment defines the preferred text alignment of the header label.
 * The default value is NSTextAlignmentCenter.
 */
@property NSTextAlignment headerTextAlignment;

/*!
 * imageStyle defines the image style of a immersive in-app message. 
 * For more information about the possible image styles, please check the documentation of
 * ABKInAppMessageImmersiveImageStyle above.
 */
@property ABKInAppMessageImmersiveImageStyle imageStyle;

/*!
 * @param buttonId The clicked button's button ID for the in-app message. This number can't be negative.
 * If you're handling in-app messages completely on your own, you should still report
 * clicks on the in-app message button back to Braze with this method so that your campaign reporting features
 * still work in the dashboard.
 *
 * Note: Each in-app message can log at most one button click.
 */
- (void)logInAppMessageClickedWithButtonID:(NSInteger)buttonId;

/*!
 * @param buttonArray The button array for the in-app message. This array should NOT be nil nor empty. Every object in the array
 * must be an instance of ABKInAppMessageButton.
 *
 * This method will set the in-app message buttons.
 */
- (void)setInAppMessageButtons:(NSArray *)buttonArray;

@end
NS_ASSUME_NONNULL_END
