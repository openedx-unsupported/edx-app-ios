#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ABKInAppMessageDarkTheme;

/*!
 * The ABKInAppMessageClickActionType defines the action that will be performed when the in-app message is clicked.
 *
 *   ABKInAppMessageDisplayNewsFeed - This is the default behavior. It will open a modal view of Braze news feed.
 *
 *   ABKInAppMessageRedirectToURI - The in-app message will try to redirect to the uri defined by the uri property. Only when the uri
 *    is an HTTP URL, a modal web view will be displayed. If the uri is a protocol uri, the in-app message will redirect to the
 *    protocol uri.
 *
 *   ABKInAppMessageNoneClickAction - The in-app message will do nothing but dismiss itself.
 */
typedef NS_ENUM(NSInteger, ABKInAppMessageClickActionType) {
  ABKInAppMessageDisplayNewsFeed,
  ABKInAppMessageRedirectToURI,
  ABKInAppMessageNoneClickAction
};

/*!
 * The ABKInAppMessageDismissType defines how the in-app message can be dismissed.
 *
 *   ABKInAppMessageDismissAutomatically - This is the default behavior for ABKInAppMessageSlideup.
 *     It will dismiss after the length of time defined by the duration property. 
 *     ABKInAppMessageSlideup of this type can also be dismissed by swiping.
 *
 *   ABKInAppMessageDismissManually - This is the default behavior for ABKInAppMessageImmersive. The
 *     in-app message will stay on the screen indefinitely unless dismissed by swiping or a click on
 *     the close button.
 */
typedef NS_ENUM(NSInteger, ABKInAppMessageDismissType) {
  ABKInAppMessageDismissAutomatically,
  ABKInAppMessageDismissManually
};

/*!
 * The ABKInAppMessageOrientation defines preferred screen orientation for the in-app message.
 *
 *   ABKInAppMessageOrientationAny - This is the default value for an in-app message's orientation. This
 *     value allows the in-app message display in any orientation.
 *
 *   ABKInAppMessageOrientationPortrait - This value will limit the in-app message to only display in
 *     protrait and portrait upside down orientation.
 *
 *   ABKInAppMessageOrientationLandscape - This value will limit the in-app message to only display in
 *     landscape orientation, including landscape left and landscape right.
 */
typedef NS_ENUM(NSInteger, ABKInAppMessageOrientation) {
  ABKInAppMessageOrientationAny,
  ABKInAppMessageOrientationPortrait,
  ABKInAppMessageOrientationLandscape
};

/*!
 * Default icon and in-app message button background colors.
 * These are used in the in-app message view controllers.
 */
static CGFloat const RedValueOfDefaultIconColorAndButtonBgColor = 0.0f;
static CGFloat const GreenValueOfDefaultIconColorAndButtonBgColor = 115.0f / 255.0f;
static CGFloat const BlueValueOfDefaultIconColorAndButtonBgColor = 213.0f / 255.0f;
static CGFloat const AlphaValueOfDefaultIconColorAndButtonBgColor = 1.0f;

/*
 * Braze Public API: ABKInAppMessage
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessage : NSObject

/*!
 * This property defines the message displayed within the in-app message.
 */
@property (copy) NSString *message;

/*!
 * This property carries extra data in the form of an NSDictionary which can be sent down via the Braze Dashboard.
 * You may want to design and implement a custom handler to access this data depending on your use-case.
 */
@property (strong, nullable) NSDictionary *extras;

/*!
 * This property defines the number of seconds before the in-app message is automatically dismissed.
 */
@property (nonatomic) NSTimeInterval duration;

/*!
 * This property defines the action that will be performed when the in-app message is clicked.
 * See the ABKInAppMessageClickActionType enum documentation above offers additional details.
 */
@property (readonly) ABKInAppMessageClickActionType inAppMessageClickActionType;

/*!
 * When the in-app message's inAppMessageClickActionType is ABKInAppMessageRedirectToURI, clicking on the in-app message will redirect to the uri defined
 * in this property.
 *
 * This property can be a HTTP URI or a protocol URI.
 */
@property (readonly, copy, nullable) NSURL *uri;

/*!
 * When the in-app message's inAppMessageClickActionType is ABKInAppMessageRedirectToURI, if the property is set to YES, 
 * the URI will be opened in a modal WKWebView inside the app. If this property is set to NO, the URI will be opened by
 * the OS and web URIs will be opened in an external web browser app.
 *
 * This property defaults to YES on ABKInAppMessageHTML subclasses and NO on all other ABKInAppMessage subclasses.
 */
@property BOOL openUrlInWebView;

/*!
 * inAppMessageDismissType defines the dismissal behavior of the in-app message.
 * See the above documentation for ABKInAppMessageDismissType for additional details.
 */
@property ABKInAppMessageDismissType inAppMessageDismissType;

/*!
 * backgroundColor defines the background color of the in-app message. The default background color is black with 0.9 alpha for
 * ABKInAppMessageSlideup, and white with 1.0 alpha for ABKInAppMessageModal and ABKInAppMessageFull.
 */
@property (nonatomic, strong, nullable) UIColor *backgroundColor;

/*!
 * textColor defines the message text color of the in-app message. The default text color is black.
 */
@property (nonatomic, strong, nullable) UIColor *textColor;

/*!
 * icon the unicode string of the Font Awesome icon for this in-app message.
 *
 * You may add Font Awesome icons to in-app messages from the Braze dashboard.
 */
@property (nonatomic, copy, nullable) NSString *icon;

/*!
 * iconColor defines the font color of icon property.
 * The default font color is white.
 */
@property (nonatomic, strong, nullable) UIColor *iconColor;

/*!
 * iconBackgroundColor defines the background color of icon property.
 *  * The default background color's RGB values are R:0 G:115 B:213.
 */
@property (nonatomic, strong, nullable) UIColor *iconBackgroundColor;

/*!
 * This boolean determines if the in-app message will attempt to use dark theme colors, granted the device
 * is in dark mode and the fields are present in the response.
 *
 * @discussion The default of this value is YES but can be overriden in `beforeInAppMessageDisplayed:`
 *             to ensure that the dark theme is disabled for any given in-app message.
 */
@property (nonatomic, assign) BOOL enableDarkTheme;

/*!
 * Data model that contains all the dark theme color info for any visible views, including any buttons
 * that may be present.
 */
@property (nonatomic, strong, nullable) ABKInAppMessageDarkTheme *darkTheme;

/*!
 * An optional UIUserInterfaceStyle that can be used to force dark or light mode.
 *
 * @discussion The default value will not override OS settings but can
 *             be overriden in `beforeInAppMessageDisplayed:`
 *             to ensure that the dark or light theme is used for any given in-app message.
 *             This property is of type NSInteger to avoid any iOS version dependencies.
 */
@property (nonatomic) NSInteger overrideUserInterfaceStyle;

/*!
 * imageURI defines the URI of the image icon on in-app message.
 * When there is a iconImage defined, the iconImage will be used and the value of property icon will 
 * be ignored.
 */
@property (copy, nullable) NSURL *imageURI;

/*!
 * imageContentMode defines the content mode of the image on in-app message.
 * For immersive in-app messages, the imageContentMode defines both the image icon and the graphic
 * image's content mode.
 *
 * The imageContentMode default values are:
 *     Slideup: UIViewContentModeScaleAspectFit
 *       Modal: UIViewContentModeScaleAspectFit
 *        Full: UIViewContentModeScaleAspectFill
 */
@property UIViewContentMode imageContentMode;

/*!
 * orientation defines the preferred screen orientation for the in-app message.
 * In-app messages will only display if the preferred orientation matches the current status bar
 * orientation. However, there is an important exception for iPads. For in-app messages that
 * have a preferred orientation and are being displayed on an iPad, the in-app message will appear
 * in the style of the preferred orientation regardless of actual screen orientation.
 */
@property ABKInAppMessageOrientation orientation;

/*!
 * messageTextAlignment defines the preferred text alignment of the message label.
 * The default values are:
 *     Slideup: NSTextAlignmentNatural
 *       Modal: NSTextAlignmentCenter
 *        Full: NSTextAlignmentCenter
 */
@property NSTextAlignment messageTextAlignment;

/*
 * animateIn/animateOut define if the in-app message should be animated in/out on the screen when
 * displaying/dismissing. The default value is YES.
 */
@property BOOL animateIn;
@property BOOL animateOut;

/*!
 * isControl defines whether this in-app message is a control. Control in-app messages should not be displayed to users.
 */
@property BOOL isControl;

/*!
 * If you're handling in-app messages completely on your own, you should still report
 * impressions and clicks on the in-app message back to Braze with these methods so that your campaign reporting features
 * still work in the dashboard.
 *
 * Note: Each in-app message can log at most one impression and at most one click.
 */
- (void)logInAppMessageImpression;
- (void)logInAppMessageClicked;

/*!
 * This method will set the inAppMessageClickActionType property.
 *
 * When clickActionType is ABKInAppMessageRedirectToURI, the parameter uri cannot be nil. When clickActionType is
 * ABKInAppMessageDisplayNewsFeed or ABKInAppMessageNoneClickAction, the parameter uri will be ignored, and property uri
 * will be set to nil.
 */
- (void)setInAppMessageClickAction:(ABKInAppMessageClickActionType)clickActionType withURI:(nullable NSURL *)uri;

/*!
 * Serializes the in-app message to binary data for use by wrappers such as Braze's Unity SDK for iOS.
 */
- (nullable NSData *)serializeToData;

@end
NS_ASSUME_NONNULL_END
