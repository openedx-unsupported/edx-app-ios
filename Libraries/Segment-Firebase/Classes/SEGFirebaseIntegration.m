#import "SEGFirebaseIntegration.h"
#import <Firebase/Firebase.h>

#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGAnalyticsUtils.h>
#else
@import Segment;
#endif


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


- (void)screen:(SEGScreenPayload *)payload
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.firebaseClass logEventWithName:kFIREventScreenView parameters:@{
            kFIRParameterScreenName: payload.name
        }];
        SEGLog(@"[FIRAnalytics setScreenName:%@]", payload.name);
    });
}


#pragma mark - Utilities

// Formats the following types of strings to match the Firebase requirements:
//
// Event Names: https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#+logeventwithname:parameters:
// Should contain 1 to 40 alphanumeric characters or underscores.
//
// Parameter Names: https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#/c:objc(cs)FIRAnalytics(cm)logEventWithName:parameters:
// Should contain 1 to 40 alphanumeric characters or underscores.
//
// Screen Names: https://firebase.google.com/docs/reference/ios/firebaseanalytics/api/reference/Classes/FIRAnalytics#setscreennamescreenclass
// Should contain 1 to 40 alphanumeric characters or underscores.

+ (NSString *)formatFirebaseNameString:(NSString *)name
{
    NSError *error = nil;

    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^a-zA-Z0-9_])" options:0 error:&error];
    NSString *formatted = [regex stringByReplacingMatchesInString:trimmed options:0 range:NSMakeRange(0, [trimmed length]) withTemplate:@"_"];

    NSLog(@"Output: %@", formatted); 
    return [formatted substringToIndex:MIN(40, [formatted length])];
}


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
                                             kFIREventPurchase, @"Order Completed",
                                             kFIREventPurchaseRefund, @"Order Refunded",
                                             kFIREventViewItemList, @"Product List Viewed",
                                             kFIREventAddToWishlist, @"Product Added to Wishlist",
                                             kFIREventShare, @"Product Shared",
                                             kFIREventShare, @"Cart Shared",
                                             kFIREventSearch, @"Products Searched", nil];

    NSString *mappedEvent = [mapper objectForKey:event];
    if (mappedEvent) {
        return mappedEvent;
    } else {
        return [SEGFirebaseIntegration formatFirebaseNameString:event];
    }
}

/// Params supply information that contextualize Events. You can associate up to 25 unique Params
/// with each Event type. Some Params are suggested below for certain common Events, but you are
/// not limited to these. You may supply extra Params for suggested Events or custom Params for
/// Custom events. Param names can be up to 40 characters long, may only contain alphanumeric
/// characters and underscores ("_"), and must start with an alphabetic character. Param values can
/// be up to 100 characters long. The "firebase_" prefix is reserved and should not be used.

- (NSDictionary *)returnMappedFirebaseParameters:(NSDictionary *)properties
{
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                                          kFIRParameterItems, @"products",
                                          kFIRParameterItemCategory, @"category",
                                          kFIRParameterItemID, @"product_id",
                                          kFIRParameterItemName, @"name",
                                          kFIRParameterItemBrand, @"brand",
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
            if ([data isKindOfClass:[NSDictionary class]]) {
                data = [self mapToFirebaseParameters:data withMap:mapper];
            } else if ([data isKindOfClass: [NSArray class]]) {
                NSMutableArray *newArray = [NSMutableArray array];
                for (id entry in newArray) {
                    if ([entry isKindOfClass:[NSDictionary class]]) {
                        id newEntry = [self mapToFirebaseParameters:entry withMap:mapper];
                        [newArray addObject:newEntry];
                    } else {
                        [newArray addObject:entry];
                    }
                }
                data = newArray;
            }
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
        key = [SEGFirebaseIntegration formatFirebaseNameString:key];

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
