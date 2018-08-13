//
//  BranchEvent.m
//  Branch-SDK
//
//  Created by Edward Smith on 7/24/17.
//  Copyright © 2017 Branch Metrics. All rights reserved.
//

#import "BranchEvent.h"
#import "BNCLog.h"

#pragma mark BranchStandardEvents

// Commerce events

BranchStandardEvent BranchStandardEventAddToCart          = @"ADD_TO_CART";
BranchStandardEvent BranchStandardEventAddToWishlist      = @"ADD_TO_WISHLIST";
BranchStandardEvent BranchStandardEventViewCart           = @"VIEW_CART";
BranchStandardEvent BranchStandardEventInitiatePurchase   = @"INITIATE_PURCHASE";
BranchStandardEvent BranchStandardEventAddPaymentInfo     = @"ADD_PAYMENT_INFO";
BranchStandardEvent BranchStandardEventPurchase           = @"PURCHASE";
BranchStandardEvent BranchStandardEventSpendCredits       = @"SPEND_CREDITS";

// Content Events

BranchStandardEvent BranchStandardEventSearch             = @"SEARCH";
BranchStandardEvent BranchStandardEventViewItem           = @"VIEW_ITEM";
BranchStandardEvent BranchStandardEventViewItems          = @"VIEW_ITEMS";
BranchStandardEvent BranchStandardEventRate               = @"RATE";
BranchStandardEvent BranchStandardEventShare              = @"SHARE";

// User Lifecycle Events

BranchStandardEvent BranchStandardEventCompleteRegistration   = @"COMPLETE_REGISTRATION";
BranchStandardEvent BranchStandardEventCompleteTutorial       = @"COMPLETE_TUTORIAL";
BranchStandardEvent BranchStandardEventAchieveLevel           = @"ACHIEVE_LEVEL";
BranchStandardEvent BranchStandardEventUnlockAchievement      = @"UNLOCK_ACHIEVEMENT";

#pragma mark - BranchEventRequest

@interface BranchEventRequest : BNCServerRequest <NSCoding>

- (instancetype) initWithServerURL:(NSURL*)serverURL
                   eventDictionary:(NSDictionary*)eventDictionary
                        completion:(void (^)(NSDictionary* response, NSError* error))completion;

@property (strong) NSDictionary *eventDictionary;
@property (strong) NSURL *serverURL;
@property (copy)   void (^completion)(NSDictionary* response, NSError* error);
@end

@implementation BranchEventRequest

- (instancetype) initWithServerURL:(NSURL*)serverURL
                   eventDictionary:(NSDictionary*)eventDictionary
                        completion:(void (^)(NSDictionary* response, NSError* error))completion {

	self = [super init];
	if (!self) return self;

	self.serverURL = serverURL;
	self.eventDictionary = eventDictionary;
	self.completion = completion;
	return self;
}

- (void)makeRequest:(BNCServerInterface *)serverInterface
			    key:(NSString *)key
           callback:(BNCServerCallback)callback {
    [serverInterface postRequest:self.eventDictionary
							 url:[self.serverURL absoluteString]
							 key:key
						callback:callback];
}

- (void)processResponse:(BNCServerResponse*)response
				  error:(NSError*)error {
	NSDictionary *dictionary =
		([response.data isKindOfClass:[NSDictionary class]])
		? (NSDictionary*) response.data
		: nil;
		
	if (self.completion)
		self.completion(dictionary, error);
}

#pragma mark BranchEventRequest NSCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
	if (!self) return self;

	self.serverURL = [decoder decodeObjectForKey:@"serverURL"];
	self.eventDictionary = [decoder decodeObjectForKey:@"eventDictionary"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:self.serverURL forKey:@"serverURL"];
    [coder encodeObject:self.eventDictionary forKey:@"eventDictionary"];
}

@end

#pragma mark - BranchEvent

@interface BranchEvent () {
    NSMutableDictionary *_customData;
    NSMutableArray      *_contentItems;
}
@property (nonatomic, strong) NSString*  eventName;
@end

@implementation BranchEvent : NSObject

- (instancetype) initWithName:(NSString *)name {
    self = [super init];
    if (!self) return self;
    _eventName = name;
    return self;
}

+ (instancetype) standardEvent:(BranchStandardEvent)standardEvent {
    return [[BranchEvent alloc] initWithName:standardEvent];
}

+ (instancetype) standardEvent:(BranchStandardEvent)standardEvent
               withContentItem:(BranchUniversalObject*)contentItem {
    BranchEvent *e = [BranchEvent standardEvent:standardEvent];
    if (contentItem) {
        e.contentItems = (NSMutableArray*) @[ contentItem ];
    }
    return e;
}

+ (instancetype) customEventWithName:(NSString*)name {
    return [[BranchEvent alloc] initWithName:name];
}

+ (instancetype) customEventWithName:(NSString*)name
                         contentItem:(BranchUniversalObject*)contentItem {
    BranchEvent *e = [[BranchEvent alloc] initWithName:name];
    if (contentItem) {
        e.contentItems = (NSMutableArray*) @[ contentItem ];
    }
    return e;
}

- (NSMutableDictionary*) customData {
    if (!_customData) _customData = [NSMutableDictionary new];
    return _customData;
}

- (void) setCustomData:(NSMutableDictionary<NSString *,NSString *> *)userInfo {
    _customData = [userInfo mutableCopy];
}

- (NSMutableArray*) contentItems {
    if (!_contentItems) _contentItems = [NSMutableArray new];
    return _contentItems;
}

- (void) setContentItems:(NSMutableArray<BranchUniversalObject *> *)contentItems {
    if ([contentItems isKindOfClass:[BranchUniversalObject class]]) {
        _contentItems = [NSMutableArray arrayWithObject:contentItems];
    } else
    if ([contentItems isKindOfClass:[NSArray class]]) {
        _contentItems = [contentItems mutableCopy];
    }
}

- (NSDictionary*) dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    #define BNCFieldDefinesDictionaryFromSelf
    #include "BNCFieldDefines.h"

    addString(transactionID,    transaction_id);
    addString(currency,         currency);
    addDecimal(revenue,         revenue);
    addDecimal(shipping,        shipping);
    addDecimal(tax,             tax);
    addString(coupon,           coupon);
    addString(affiliation,      affiliation);
    addString(eventDescription, description);
    addString(searchQuery,      search_query)
    addDictionary(customData,   custom_data);
    
    #include "BNCFieldDefines.h"

    return dictionary;
}

+ (NSArray<BranchStandardEvent>*) standardEvents {
    return @[
        BranchStandardEventAddToCart,
        BranchStandardEventAddToWishlist,
        BranchStandardEventViewCart,
        BranchStandardEventInitiatePurchase,
        BranchStandardEventAddPaymentInfo,
        BranchStandardEventPurchase,
        BranchStandardEventSpendCredits,
        BranchStandardEventSearch,
        BranchStandardEventViewItem,
        BranchStandardEventViewItems,
        BranchStandardEventRate,
        BranchStandardEventShare,
        BranchStandardEventCompleteRegistration,
        BranchStandardEventCompleteTutorial,
        BranchStandardEventAchieveLevel,
        BranchStandardEventUnlockAchievement,
    ];
}

- (void) logEvent {

    if (![_eventName isKindOfClass:[NSString class]] || _eventName.length == 0) {
        BNCLogError(@"Invalid event type '%@' or empty string.", NSStringFromClass(_eventName.class));
        return;
    }

    NSMutableDictionary *eventDictionary = [NSMutableDictionary new];
    eventDictionary[@"name"] = _eventName;

    NSDictionary *propertyDictionary = [self dictionary];
    if (propertyDictionary.count) {
        eventDictionary[@"event_data"] = propertyDictionary;
    }
    eventDictionary[@"custom_data"] = eventDictionary[@"event_data"][@"custom_data"];
    eventDictionary[@"event_data"][@"custom_data"] = nil;

    NSMutableArray *contentItemDictionaries = [NSMutableArray new];
    for (BranchUniversalObject *contentItem in self.contentItems) {
        NSDictionary *dictionary = [contentItem dictionary];
        if (dictionary.count) {
            [contentItemDictionaries addObject:dictionary];
        }
    }

    if (contentItemDictionaries.count) {
        eventDictionary[@"content_items"] = contentItemDictionaries;
    }

    BNCPreferenceHelper *preferenceHelper = [BNCPreferenceHelper preferenceHelper];
    NSString *serverURL =
        ([self.class.standardEvents containsObject:self.eventName])
        ? [NSString stringWithFormat:@"%@/%@", preferenceHelper.branchAPIURL, @"v2/event/standard"]
        : [NSString stringWithFormat:@"%@/%@", preferenceHelper.branchAPIURL, @"v2/event/custom"];

    BranchEventRequest *request =
		[[BranchEventRequest alloc]
			initWithServerURL:[NSURL URLWithString:serverURL]
			eventDictionary:eventDictionary
			completion:nil];

    [[Branch getInstance] sendServerRequestWithoutSession:request];
}

- (NSString*_Nonnull) description {
    return [NSString stringWithFormat:
        @"<%@ 0x%016llx %@ txID: %@ Amt: %@ %@ desc: %@ items: %ld customData: %@>",
        NSStringFromClass(self.class),
        (uint64_t) self,
        self.eventName,
        self.transactionID,
        self.currency,
        self.revenue,
        self.eventDescription,
        (long) self.contentItems.count,
        self.customData
    ];
}

@end
