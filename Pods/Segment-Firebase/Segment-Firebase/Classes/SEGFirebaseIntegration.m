#import "SEGFirebaseIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>
#import <Firebase/Firebase.h>


@implementation SEGFirebaseIntegration

#pragma mark - Initialization

- (id)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        self.settings = settings;
        self.firebaseClass = [FIRAnalytics class];
        NSString *deepLinkURLScheme = [self.settings objectForKey:@"deepLinkURLScheme"];
        if (deepLinkURLScheme) {
            [FIROptions defaultOptions].deepLinkURLScheme = deepLinkURLScheme;
            SEGLog(@"[FIROptions defaultOptions].deepLinkURLScheme = %@;", deepLinkURLScheme);
        }

        if ([FIRApp defaultApp]) {
            SEGLog(@"[FIRApp Configure] already called, skipping");
            return self;
        }

        [FIRApp configure];
        SEGLog(@"[FIRApp Configure]");
    }
    return self;
}

- (id)initWithSettings:(NSDictionary *)settings andFirebase:(id)firebaseClass;
{
    if (self = [super init]) {
        self.settings = settings;
        self.firebaseClass = firebaseClass;
    }
    return self;
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    if (payload.userId) {
        [self.firebaseClass setUserID:payload.userId];
        SEGLog(@"[FIRAnalytics setUserId:%@]", payload.userId);
    }
    // Firebase requires user properties to be an NSString
    NSDictionary *mappedTraits = [SEGFirebaseIntegration mapToStrings:payload.traits];
    [mappedTraits enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *trait = [key stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSString *value = [obj stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.firebaseClass setUserPropertyString:value forName:trait];
        SEGLog(@"[FIRAnalytics setUserPropertyString:%@ forName:%@]", value, trait);
    }];
}

- (void)track:(SEGTrackPayload *)payload
{
    NSString *name = [self formatFirebaseEventNames:payload.event];
    NSDictionary *parameters = [self returnMappedFirebaseParameters:payload.properties];

    [self.firebaseClass logEventWithName:name parameters:parameters];
    SEGLog(@"[FIRAnalytics logEventWithName:%@ parameters:%@]", name, parameters);
}


#pragma mark - Utilities

// Event names can be up to 32 characters long, may only contain alphanumeric
// characters and underscores ("_"), and must start with an alphabetic character. The "firebase_"
// prefix is reserved and should not be used.

// Maps Segment Spec to Firebase Constants
// https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Constants#/c:FIRParameterNames.h@kFIRParameterCampaign

- (NSString *)formatFirebaseEventNames:(NSString *)event
{
    NSDictionary *mapper = [NSDictionary dictionaryWithObjectsAndKeys:
                                             kFIREventSelectContent, @"Product Clicked",
                                             kFIREventViewItem, @"Product Viewed",
                                             kFIREventAddToCart, @"Product Added",
                                             kFIREventRemoveFromCart, @"Product Removed",
                                             kFIREventBeginCheckout, @"Checkout Started",
                                             kFIREventPresentOffer, @"Promotion Viewed",
                                             kFIREventAddPaymentInfo, @"Payment Info Entered",
                                             kFIREventEcommercePurchase, @"Order Completed",
                                             kFIREventPurchaseRefund, @"Order Refunded",
                                             kFIREventViewItemList, @"Product List Viewed",
                                             kFIREventAddToWishlist, @"Product Added to Wishlist",
                                             kFIREventShare, @"Product Shared",
                                             kFIREventShare, @"Cart Shared",
                                             kFIREventSearch, @"Products Searched", nil];

    NSString *mappedEvent = [mapper objectForKey:event];
    NSArray *periodSeparatedEvent = [event componentsSeparatedByString:@"."];
    NSString *regexString = @"^[a-zA-Z0-9_]+$";
    NSError *error = NULL;
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:regexString
                                              options:0
                                                error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:event
                                                        options:0
                                                          range:NSMakeRange(0, [event length])];
    if (mappedEvent) {
        return mappedEvent;
    } else if (numberOfMatches == 0) {
        NSString *trimmedEvent = [event stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([periodSeparatedEvent count] > 1) {
            return [trimmedEvent stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        } else {
            return [trimmedEvent stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        }
    } else {
        return event;
    }
}

/// Params supply information that contextualize Events. You can associate up to 25 unique Params
/// with each Event type. Some Params are suggested below for certain common Events, but you are
/// not limited to these. You may supply extra Params for suggested Events or custom Params for
/// Custom events. Param names can be up to 24 characters long, may only contain alphanumeric
/// characters and underscores ("_"), and must start with an alphabetic character. Param values can
/// be up to 36 characters long. The "firebase_" prefix is reserved and should not be used.

- (NSDictionary *)returnMappedFirebaseParameters:(NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                                          kFIRParameterItemCategory, @"category",
                                          kFIRParameterItemID, @"product_id",
                                          kFIRParameterItemName, @"name",
                                          kFIRParameterPrice, @"price",
                                          kFIRParameterQuantity, @"quantity",
                                          kFIRParameterSearchTerm, @"query",
                                          kFIRParameterShipping, @"shipping",
                                          kFIRParameterTax, @"tax",
                                          kFIRParameterValue, @"total",
                                          kFIRParameterValue, @"revenue",
                                          kFIRParameterTransactionID, @"order_id",
                                          kFIRParameterCurrency, @"currency", nil];


    return [SEGFirebaseIntegration mapToFirebaseParameters:properties withMap:map];
}

+ (NSDictionary *)mapToFirebaseParameters:(NSDictionary *)properties withMap:(NSDictionary *)mapper
{
    NSMutableDictionary *mappedParams = [NSMutableDictionary dictionaryWithDictionary:properties];
    [mapper enumerateKeysAndObjectsUsingBlock:^(NSString *original, NSString *new, BOOL *stop) {
        id data = [properties objectForKey:original];
        if (data) {
            [mappedParams removeObjectForKey:original];
            [mappedParams setObject:data forKey:new];
        }
    }];

    return [formatEventProperties(mappedParams) copy];
}

NSDictionary *formatEventProperties(NSDictionary *dictionary)
{
    NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id data, BOOL *stop) {
        [output removeObjectForKey:key];
        NSArray *periodSeparatedKey = [key componentsSeparatedByString:@"."];
        NSString *trimmedKey = [key stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([periodSeparatedKey count] > 1) {
            key = [trimmedKey stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        } else {
            key = [trimmedKey stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        }
        if ([data isKindOfClass:[NSNumber class]]) {
            data = [NSNumber numberWithDouble:[data doubleValue]];
            [output setObject:data forKey:key];
        } else {
            [output setObject:data forKey:key];
        }
    }];

    return [output copy];
}

// Firebase requires all User traits to be Strings
+ (NSDictionary *)mapToStrings:(NSDictionary *)dictionary
{
    NSMutableDictionary *output = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];

    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id data, BOOL *stop) {
        if ([data isKindOfClass:[NSString class]]) {
            [output setObject:data forKey:key];
        } else {
            [output setObject:[NSString stringWithFormat:@"%@", data] forKey:key];
        }
    }];

    return [output copy];
}


@end
