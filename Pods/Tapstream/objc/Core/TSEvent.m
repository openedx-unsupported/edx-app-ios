#import "TSEvent.h"
#import <sys/time.h>
#import <stdio.h>
#import <stdlib.h>
#import "TSLogging.h"
#import "TSUtils.h"

@interface TSEvent()
@end


@implementation TSEvent

@synthesize uid, name, encodedName, productId, customFields, postData, isOneTimeOnly, isTransaction;

+ (id)eventWithName:(NSString *)eventName oneTimeOnly:(BOOL)oneTimeOnlyArg
{
	return AUTORELEASE([[self alloc] initWithName:eventName oneTimeOnly:oneTimeOnlyArg]);
}

+ (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
{
	return AUTORELEASE([[self alloc] initWithTransactionId:transactionId productId:productId quantity:quantity]);
}

+ (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
{
	return AUTORELEASE([[self alloc] initWithTransactionId:transactionId productId:productId quantity:quantity priceInCents:priceInCents currency:currencyCode]);
}

+ (id)eventWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productId
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
	base64Receipt:(NSString *)base64Receipt
{
	return AUTORELEASE([[self alloc] initWithTransactionId:transactionId productId:productId quantity:quantity priceInCents:priceInCents currency:currencyCode base64Receipt:base64Receipt]);
}

- (id)initWithName:(NSString *)eventName
	oneTimeOnly:(BOOL)oneTimeOnlyArg
{
	if((self = [super init]) != nil)
	{
		firstFiredTime = 0;
		uid = RETAIN([self makeUid]);
		[self setName:eventName];
		postData = RETAIN([NSMutableString stringWithCapacity:64]);
		isOneTimeOnly = oneTimeOnlyArg;
		isTransaction = NO;
		customFields = RETAIN([NSMutableDictionary dictionaryWithCapacity:16]);
	}
	return self;
}

- (id)initWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productIdVal
	quantity:(int)quantity
{
	if((self = [super init]) != nil)
	{
		firstFiredTime = 0;
		uid = RETAIN([self makeUid]);
		productId = RETAIN(productIdVal);
		postData = RETAIN([NSMutableString stringWithCapacity:64]);
		isOneTimeOnly = NO;
		isTransaction = YES;
		customFields = RETAIN([NSMutableDictionary dictionaryWithCapacity:16]);

		[self addValue:transactionId forKey:@"purchase-transaction-id" withPrefix:@"" limitValueLength:YES];
		[self addValue:productId forKey:@"purchase-product-id" withPrefix:@"" limitValueLength:YES];
		[self addValue:[NSNumber numberWithInt:quantity] forKey:@"purchase-quantity" withPrefix:@"" limitValueLength:YES];
	}
	return self;
}

- (id)initWithTransactionId:(NSString *)transactionId
				  productId:(NSString *)productIdVal
				   quantity:(int)quantity
			   priceInCents:(int)priceInCents
				   currency:(NSString *)currencyCode
{
	if((self = [super init]) != nil)
	{
		firstFiredTime = 0;
		uid = RETAIN([self makeUid]);
		productId = RETAIN(productIdVal);
		postData = RETAIN([NSMutableString stringWithCapacity:64]);
		isOneTimeOnly = NO;
		isTransaction = YES;
		customFields = RETAIN([NSMutableDictionary dictionaryWithCapacity:16]);
		
		[self addValue:transactionId forKey:@"purchase-transaction-id" withPrefix:@"" limitValueLength:YES];
		[self addValue:productId forKey:@"purchase-product-id" withPrefix:@"" limitValueLength:YES];
		[self addValue:[NSNumber numberWithInt:quantity] forKey:@"purchase-quantity" withPrefix:@"" limitValueLength:YES];
		[self addValue:[NSNumber numberWithInt:priceInCents] forKey:@"purchase-price" withPrefix:@"" limitValueLength:YES];
		[self addValue:currencyCode forKey:@"purchase-currency" withPrefix:@"" limitValueLength:YES];
	}
	return self;
}

- (id)initWithTransactionId:(NSString *)transactionId
	productId:(NSString *)productIdVal
	quantity:(int)quantity
	priceInCents:(int)priceInCents
	currency:(NSString *)currencyCode
	base64Receipt:(NSString *)base64Receipt
{
	if((self = [super init]) != nil)
	{
		firstFiredTime = 0;
		uid = RETAIN([self makeUid]);
		productId = RETAIN(productIdVal);
		postData = RETAIN([NSMutableString stringWithCapacity:64]);
		isOneTimeOnly = NO;
		isTransaction = YES;
		customFields = RETAIN([NSMutableDictionary dictionaryWithCapacity:16]);

		[self addValue:transactionId forKey:@"purchase-transaction-id" withPrefix:@"" limitValueLength:YES];
		[self addValue:productId forKey:@"purchase-product-id" withPrefix:@"" limitValueLength:YES];
		[self addValue:[NSNumber numberWithInt:quantity] forKey:@"purchase-quantity" withPrefix:@"" limitValueLength:YES];
		[self addValue:[NSNumber numberWithInt:priceInCents] forKey:@"purchase-price" withPrefix:@"" limitValueLength:YES];
		[self addValue:currencyCode forKey:@"purchase-currency" withPrefix:@"" limitValueLength:YES];
		[self addValue:base64Receipt forKey:@"receipt-body" withPrefix:@"" limitValueLength:NO];
	}
	return self;
}

- (NSString *)makeUid
{
	NSTimeInterval t = [[NSDate date] timeIntervalSince1970];
	return [NSString stringWithFormat:@"%.0f:%f", t*1000, arc4random() / (float)0x10000000];
}

- (void)setName:(NSString *)eventName
{
	RELEASE(name);
	name = RETAIN([[[eventName lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] stringByReplacingOccurrencesOfString:@"." withString:@"_"]);

	RELEASE(encodedName);
	encodedName = RETAIN([TSUtils encodeString:name]);
}

- (void)setTransactionNameWithAppName:(NSString *)appName platform:(NSString *)platformName
{
	NSString *eventName = [NSString stringWithFormat:@"%@-%@-purchase-%@", platformName, [appName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], productId];
	[self setName:eventName];
}

- (void)addValue:(NSObject *)obj forKey:(NSString *)key
{
	if(key != nil && obj != nil) {
		[self.customFields setObject:obj forKey:key];
	}
}

- (void)prepare:(NSDictionary *)globalEventParams
{
	// Only record the time of the first fire attempt
	if(firstFiredTime == 0)
	{
		firstFiredTime = [[NSDate date] timeIntervalSince1970];

		for(NSString *key in globalEventParams)
		{
			if([self.customFields objectForKey:key] == nil)
			{
				[self addValue:[globalEventParams valueForKey:key] forKey:key];
			}
		}

		[postData appendString:[NSString stringWithFormat:@"&created-ms=%.0f", firstFiredTime*1000]];
		
		for(NSString *key in self.customFields)
		{
			[self addValue:[self.customFields objectForKey:key] forKey:key withPrefix:@"custom-" limitValueLength:YES];
		}
	}
}

- (void)addValue:(id)value forKey:(NSString *)key withPrefix:(NSString *)prefix limitValueLength:(BOOL)limitValueLength
{
	NSString *encodedPair = [TSUtils encodeEventPairWithPrefix:prefix key:key value:value limitValueLength:limitValueLength];
	if(encodedPair != nil)
	{
		[postData appendString:@"&"];
		[postData appendString:encodedPair];
	}
}

- (void)dealloc
{
	RELEASE(uid);
	RELEASE(name);
	RELEASE(encodedName);
	RELEASE(productId);
	RELEASE(customFields);
	RELEASE(postData);
	SUPER_DEALLOC;
}


- (void)addIntegerValue:(int)value forKey:(NSString *)key
{
	[self addValue:[NSNumber numberWithInt:value] forKey:key];
}

- (void)addUnsignedIntegerValue:(uint)value forKey:(NSString *)key
{
	[self addValue:[NSNumber numberWithUnsignedInt:value] forKey:key];
}

- (void)addDoubleValue:(double)value forKey:(NSString *)key
{
	[self addValue:[NSNumber numberWithDouble:value] forKey:key];
}

- (void)addFloatValue:(float)value forKey:(NSString *)key
{
	[self addValue:[NSNumber numberWithFloat:value] forKey:key];
}

- (void)addBooleanValue:(BOOL)value forKey:(NSString *)key
{
	[self addValue:[NSNumber numberWithBool:value] forKey:key];
}


@end
