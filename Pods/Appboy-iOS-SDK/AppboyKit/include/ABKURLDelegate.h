#import <Foundation/Foundation.h>
#import "Appboy.h"

/*
 * Braze Public API: ABKURLDelegate
 */
NS_ASSUME_NONNULL_BEGIN

@protocol ABKURLDelegate <NSObject>

/*!
 * @param url The deep link or web URL being offered to the delegate method.
 * @param channel An enum representing the URL's associated messaging channel.
 * @param extras The extras dictionary associated with the campaign or messaging object that the URL originated from.
                 Extras may be specified as key-value pairs on the Braze dashboard.
 * @return Boolean value which controls whether or not Braze will handle opening the URL. Returning YES will
 *         prevent Braze from opening the URL. Returning NO will cause Braze to handle opening the URL.
 *
 * This delegate method is fired whenever the user attempts to open a URL sent by Braze. You can use this delegate
 * to customize Braze's URL handling.
 */
- (BOOL)handleAppboyURL:(NSURL * _Nullable)url
            fromChannel:(ABKChannel)channel
             withExtras:(NSDictionary * _Nullable)extras;

@end
NS_ASSUME_NONNULL_END
