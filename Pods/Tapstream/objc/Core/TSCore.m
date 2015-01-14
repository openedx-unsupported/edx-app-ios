#import "TSCore.h"
#import "TSHelpers.h"
#import "TSLogging.h"
#import "TSUtils.h"

#define kTSVersion @"2.8.2"
#define kTSEventUrlTemplate @"https://api.tapstream.com/%@/event/%@/"
#define kTSHitUrlTemplate @"http://api.tapstream.com/%@/hit/%@.gif"
#define kTSConversionUrlTemplate @"https://reporting.tapstream.com/v1/timelines/lookup?secret=%@&event_session=%@"
#define kTSConversionPollInterval 1
#define kTSConversionPollCount 10

@interface TSEvent(hidden)
- (void)prepare:(NSDictionary *)globalEventParams;
- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName;
@end



@interface TSCore()

@property(nonatomic, STRONG_OR_RETAIN) id<TSDelegate> del;
@property(nonatomic, STRONG_OR_RETAIN) id<TSPlatform> platform;
@property(nonatomic, STRONG_OR_RETAIN) id<TSCoreListener> listener;
@property(nonatomic, STRONG_OR_RETAIN) id<TSAppEventSource> appEventSource;
@property(nonatomic, STRONG_OR_RETAIN) TSConfig *config;
@property(nonatomic, STRONG_OR_RETAIN) NSString *accountName;
@property(nonatomic, STRONG_OR_RETAIN) NSString *secret;
@property(nonatomic, STRONG_OR_RETAIN) NSString *encodedAppName;
@property(nonatomic, STRONG_OR_RETAIN) NSMutableString *postData;
@property(nonatomic, STRONG_OR_RETAIN) NSMutableSet *firingEvents;
@property(nonatomic, STRONG_OR_RETAIN) NSMutableSet *firedEvents;
@property(nonatomic, STRONG_OR_RETAIN) NSString *failingEventId;
@property(nonatomic, STRONG_OR_RETAIN) NSString *appName;
@property(nonatomic, STRONG_OR_RETAIN) NSString *platformName;

- (NSString *)clean:(NSString *)s;
- (void)increaseDelay;
- (void)makePostArgs;
@end


@implementation TSCore

@synthesize del, platform, listener, appEventSource, config, accountName, secret, encodedAppName, postData, firingEvents, firedEvents, failingEventId, appName, platformName;

- (id)initWithDelegate:(id<TSDelegate>)delegateVal
	platform:(id<TSPlatform>)platformVal
	listener:(id<TSCoreListener>)listenerVal
	appEventSource:(id<TSAppEventSource>)appEventSourceVal
	accountName:(NSString *)accountNameVal
	developerSecret:(NSString *)developerSecretVal
	config:(TSConfig *)configVal
{
	if((self = [super init]) != nil)
	{
		self.del = delegateVal;
		self.platform = platformVal;
		self.listener = listenerVal;
		self.config = configVal;
		self.appEventSource = appEventSourceVal;
		self.accountName = [self clean:accountNameVal];
		self.secret = developerSecretVal;
		self.encodedAppName = nil;
		self.postData = nil;
		self.failingEventId = nil;
		self.appName = nil;
		self.platformName = [kTSPlatform lowercaseString];

		[self makePostArgs];

        firingEvents = [[NSMutableSet alloc] initWithCapacity:32];
		self.firedEvents = [platform loadFiredEvents];
	}
	return self;
}

- (void)dealloc
{
	RELEASE(del);
	RELEASE(platform);
	RELEASE(listener);
	RELEASE(appEventSource);
	RELEASE(accountName);
	RELEASE(secret);
	RELEASE(postData);
	RELEASE(firingEvents);
	RELEASE(firedEvents);
	RELEASE(failingEventId);
	RELEASE(appName);
	RELEASE(platformName);
	SUPER_DEALLOC;
}

- (void)start
{
	self.appName = [platform getAppName];
	if(self.appName == nil)
	{
		self.appName = @"";
	}

	if(config.fireAutomaticInstallEvent)
	{
		if(config.installEventName != nil)
		{
			[self fireEvent:[TSEvent eventWithName:config.installEventName oneTimeOnly:YES]];
		}
		else
		{
			NSString *eventName = [NSString stringWithFormat:@"%@-%@-install", platformName, self.appName];
			[self fireEvent:[TSEvent eventWithName:eventName oneTimeOnly:YES]];
		}
	}

	__unsafe_unretained TSCore *me = self;

	if(config.fireAutomaticOpenEvent)
	{
		// Fire the initial open event
		if(config.openEventName != nil)
		{
			[self fireEvent:[TSEvent eventWithName:config.openEventName oneTimeOnly:NO]];
		}
		else
		{
			NSString *eventName = [NSString stringWithFormat:@"%@-%@-open", platformName, self.appName];
			[self fireEvent:[TSEvent eventWithName:eventName oneTimeOnly:NO]];
		}

		// Subscribe to be notified whenever the app enters the foreground
		[appEventSource setOpenHandler:^() {
			if(me.config.openEventName != nil)
			{
				[me fireEvent:[TSEvent eventWithName:me.config.openEventName oneTimeOnly:NO]];
			}
			else
			{
				NSString *eventName = [NSString stringWithFormat:@"%@-%@-open", me.platformName, me.appName];
				[me fireEvent:[TSEvent eventWithName:eventName oneTimeOnly:NO]];
			}
		}];
	}

	if(config.fireAutomaticIAPEvents)
	{
		[appEventSource setTransactionHandler:^(NSString *transactionId, NSString *productId, int quantity, int priceInCents, NSString *currencyCode, NSString *base64Receipt) {
			[me fireEvent:[TSEvent eventWithTransactionId:transactionId
				productId:productId
				quantity:quantity
				priceInCents:priceInCents
				currency:currencyCode
				base64Receipt:base64Receipt]];
		}];
	}
}

- (void)fireEvent:(TSEvent *)e
{
	@synchronized(self)
	{
		if(e.isTransaction)
		{
			[e setTransactionNameWithAppName:appName platform:platformName];
		}

		// Add global event params if they have not yet been added
		// Notify the event that we are going to fire it so it can record the time and bake its post data
		[e prepare:config.globalEventParams];

		if(e.isOneTimeOnly)
		{
			if([firedEvents containsObject:e.name])
			{
				[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream ignoring event named \"%@\" because it is a one-time-only event that has already been fired", e.name];
				[listener reportOperation:@"event-ignored-already-fired" arg:e.encodedName];
				[listener reportOperation:@"job-ended" arg:e.encodedName];
				return;
			}
			else if([firingEvents containsObject:e.name])
			{
				[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream ignoring event named \"%@\" because it is a one-time-only event that is already in progress", e.name];
				[listener reportOperation:@"event-ignored-already-in-progress" arg:e.encodedName];
				[listener reportOperation:@"job-ended" arg:e.encodedName];
				return;
			}

			[firingEvents addObject:e.name];
		}

		NSString *url = [NSString stringWithFormat:kTSEventUrlTemplate, accountName, e.encodedName];
		NSString *data = [postData stringByAppendingString:e.postData];

		int actualDelay = [del getDelay];
		dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * actualDelay);
		dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

			NSString *allData = data;
			if(config.collectTasteData)
			{
				NSString *processes = @"";
				NSSet *processSet = [platform getProcessSet];
				if(processSet)
				{
					processes = [TSUtils encodeString:[[processSet allObjects] componentsJoinedByString:@","]];
				}
				allData = [[data stringByAppendingString:@"&processes="] stringByAppendingString:processes];
			}

			TSResponse *response = [platform request:url data:allData method:@"POST"];
			bool failed = response.status < 200 || response.status >= 300;
			bool shouldRetry = response.status < 0 || (response.status >= 500 && response.status < 600);

			@synchronized(self)
			{
				if(e.isOneTimeOnly)
				{
					[firingEvents removeObject:e.name];
				}

				if(failed)
				{
					// Only increase delays if we actually intend to retry the event
					if(shouldRetry)
					{
						// Not every job that fails will increase the retry delay.  It will be the responsibility of
						// the first failed job to increase the delay after every failure.
						if(delay == 0)
						{
							// This is the first job to fail, it must be the one to manage delay timing
							self.failingEventId = e.uid;
							[self increaseDelay];
						}
						else if([failingEventId isEqualToString:e.uid])
						{
							[self increaseDelay];
						}
					}
				}
				else
				{
					if(e.isOneTimeOnly)
					{
						[firedEvents addObject:e.name];

						[platform saveFiredEvents:firedEvents];
						[listener reportOperation:@"fired-list-saved" arg:e.encodedName];
					}

					// Success of any event resets the delay
					delay = 0;
				}
			}

			if(failed)
			{
				if(response.status < 0)
				{
					[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, error=%@", response.message];
				}
				else if(response.status == 404)
				{
					[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, http code %d\nDoes your event name contain characters that are not url safe? This event will not be retried.", response.status];
				}
				else if(response.status == 403)
				{
				   [TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, http code %d\nAre your account name and application secret correct?  This event will not be retried.", response.status];
				}
				else
				{
					NSString *retryMsg = @"";
					if(!shouldRetry)
					{
						retryMsg = @"  This event will not be retried.";
					}
					[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire event, http code %d.%@", response.status, retryMsg];
				}

				[listener reportOperation:@"event-failed" arg:e.encodedName];
				if(shouldRetry)
				{
					[listener reportOperation:@"retry" arg:e.encodedName];
					[listener reportOperation:@"job-ended" arg:e.encodedName];
					if([del isRetryAllowed])
					{
						[self fireEvent:e];
					}
					return;
				}
			}
			else
			{
				[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream fired event named \"%@\"", e.name];
				[listener reportOperation:@"event-succeeded" arg:e.encodedName];
			}

			[listener reportOperation:@"job-ended" arg:e.encodedName];
		});
	}
}

- (void)fireHit:(TSHit *)hit completion:(void(^)(TSResponse *))completion
{
	NSString *url = [NSString stringWithFormat:kTSHitUrlTemplate, accountName, hit.encodedTrackerName];
	NSString *data = hit.postData;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		TSResponse *response = [platform request:url data:data method:@"POST"];
		if(response.status < 200 || response.status >= 300)
		{
			[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Failed to fire hit, http code: %d", response.status];
			[listener reportOperation:@"hit-failed"];
		}
		else
		{
			[TSLogging logAtLevel:kTSLoggingInfo format:@"Tapstream fired hit to tracker: %@", hit.trackerName];
			[listener reportOperation:@"hit-succeeded"];
		}

		if(completion != nil)
		{
			completion(response);
		}
	});
}

- (void)getConversionData:(void(^)(NSData *))completion
{
	if(completion == nil)
	{
		return;
	}

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    	[self getConversionData:[completion copy] tries:0];
    });
}

- (void)getConversionData:(void(^)(NSData *))completion tries:(int)tries {
	tries++;

	NSString *url = [NSString stringWithFormat:kTSConversionUrlTemplate, secret, [platform loadUuid]];
	TSResponse *response = [platform request:url data:nil method:@"GET"];

	if(response.status >= 200 && response.status < 300)
	{
		NSData *jsonData = RETAIN(response.data);
		NSString *jsonString = AUTORELEASE([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);

		// If it is not an empty json array, then make the callback
		NSError *error = nil;
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\[\\s*\\]\\s*$" options:0 error:&error];
		if(error == nil && [regex numberOfMatchesInString:jsonString options:NSMatchingAnchored range:NSMakeRange(0, [jsonString length])] == 0)
		{
			// Call the user's completion handler in the main thread
			dispatch_async(dispatch_get_main_queue(), ^{
				completion(jsonData);
				RELEASE(jsonData);
				RELEASE(completion);
			});
			return;
		} else {
			// Cleanup for the next round of polling
			RELEASE(jsonData);
		}
	}

	BOOL serverError = NO;
	if (response.status >= 400 && response.status <= 499){
		[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: 4XX while getting conversion data"];
		serverError = YES;
	}

	BOOL triesExhausted = NO;
	if (tries >= kTSConversionPollCount){
		[TSLogging logAtLevel:kTSLoggingError format:@"Tapstream Error: Tries exhausted while getting conversion data"];
		triesExhausted = YES;
	}

	if(serverError || triesExhausted)
	{
		// Don't try any more
		dispatch_async(dispatch_get_main_queue(), ^{
			completion(nil);
			RELEASE(completion);
		});
		return;
	}
	else
	{
		// Schedule a retry after kTSConversionPollInterval seconds
		dispatch_after(
			dispatch_time(DISPATCH_TIME_NOW, kTSConversionPollInterval * NSEC_PER_SEC),
			dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
				[self getConversionData:completion tries:tries];
		});
		return;
	}
}

- (int)getDelay
{
	return delay;
}

- (NSString *)clean:(NSString *)s
{
	s = [s lowercaseString];
	s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return [TSUtils encodeString:s];
}

- (void)increaseDelay
{
	if(delay == 0)
	{
		// First failure
		delay = 2;
	}
	else
	{
		// 2, 4, 8, 16, 32, 60, 60, 60...
		int newDelay = (int)pow( 2, log2( delay ) + 1 );
		delay = newDelay > 60 ? 60 : newDelay;
	}
	[listener reportOperation:@"increased-delay"];
}

- (void)appendPostPairWithPrefix:(NSString *)prefix key:(NSString *)key value:(NSString *)value
{
	NSString *encodedPair = [TSUtils encodeEventPairWithPrefix:prefix key:key value:value limitValueLength:YES];
	if(encodedPair == nil)
	{
		return;
	}

	if(postData == nil)
	{
		NSMutableString *newPostDataString = [[NSMutableString alloc] initWithCapacity:256];
        self.postData = newPostDataString;
        RELEASE(newPostDataString);
	}
	else
	{
        [postData appendString:@"&"];
	}
	[postData appendString:encodedPair];
}

- (void)makePostArgs
{
	[self appendPostPairWithPrefix:@"" key:@"secret" value:secret];
	[self appendPostPairWithPrefix:@"" key:@"sdkversion" value:kTSVersion];

	[self appendPostPairWithPrefix:@"" key:@"hardware" value:config.hardware];
	[self appendPostPairWithPrefix:@"" key:@"hardware-odin1" value:config.odin1];
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	[self appendPostPairWithPrefix:@"" key:@"hardware-open-udid" value:config.openUdid];
	[self appendPostPairWithPrefix:@"" key:@"hardware-ios-udid" value:config.udid];
	[self appendPostPairWithPrefix:@"" key:@"hardware-ios-idfa" value:config.idfa];
	[self appendPostPairWithPrefix:@"" key:@"hardware-ios-secure-udid" value:config.secureUdid];
#else
	[self appendPostPairWithPrefix:@"" key:@"hardware-mac-serial-number" value:config.serialNumber];
#endif

	if(config.collectWifiMac)
	{
		[self appendPostPairWithPrefix:@"" key:@"hardware-wifi-mac" value:[platform getWifiMac]];
	}

	[self appendPostPairWithPrefix:@"" key:@"uuid" value:[platform loadUuid]];
	[self appendPostPairWithPrefix:@"" key:@"platform" value:kTSPlatform];
	[self appendPostPairWithPrefix:@"" key:@"vendor" value:[platform getManufacturer]];
	[self appendPostPairWithPrefix:@"" key:@"model" value:[platform getModel]];
	[self appendPostPairWithPrefix:@"" key:@"os" value:[platform getOs]];
	[self appendPostPairWithPrefix:@"" key:@"resolution" value:[platform getResolution]];
	[self appendPostPairWithPrefix:@"" key:@"locale" value:[platform getLocale]];
	[self appendPostPairWithPrefix:@"" key:@"app-name" value:[platform getAppName]];
	[self appendPostPairWithPrefix:@"" key:@"app-version" value:[platform getAppVersion]];
	[self appendPostPairWithPrefix:@"" key:@"package-name" value:[platform getPackageName]];
	[self appendPostPairWithPrefix:@"" key:@"gmtoffset" value:[TSUtils stringifyInteger:(int)[[NSTimeZone systemTimeZone] secondsFromGMT]]];

	// Fields necessary for receipt validation
	// Use developer-provided values (if available) for stricter validation, otherwise get values from bundle
	[self appendPostPairWithPrefix:@"" key:@"receipt-guid" value:[platform getComputerGUID]];

	NSString *bundleId = config.hardcodedBundleId ? config.hardcodedBundleId : [platform getBundleIdentifier];
	[self appendPostPairWithPrefix:@"" key:@"receipt-bundle-id" value:bundleId];

	NSString *shortVersion = config.hardcodedBundleShortVersionString ? config.hardcodedBundleShortVersionString : [platform getBundleShortVersion];
	[self appendPostPairWithPrefix:@"" key:@"receipt-short-version" value:shortVersion];
}


@end
