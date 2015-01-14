#import "TSAppEventSourceImpl.h"

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

Class TSSKPaymentQueue = nil;
Class TSSKProductsRequest = nil;

static void TSLoadStoreKitClasses()
{
	if(TSSKPaymentQueue == nil)
	{
		TSSKPaymentQueue = NSClassFromString(@"SKPaymentQueue");
		TSSKProductsRequest = NSClassFromString(@"SKProductsRequest");
	}	
}


@interface TSRequestWrapper : NSObject<NSCopying>
@property(nonatomic, STRONG_OR_RETAIN) SKProductsRequest *request;
+ (id)requestWrapperWithRequest:(SKProductsRequest *)req;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (NSUInteger)hash;
@end

@implementation TSRequestWrapper
@synthesize request;
+ (id)requestWrapperWithRequest:(SKProductsRequest *)req
{
	return AUTORELEASE([[self alloc] initWithRequest:req]);
}
- (id)initWithRequest:(SKProductsRequest *)req
{
	if((self = [super init]) != nil)
	{
		self.request = req;
	}
	return self;
}
- (id)copyWithZone:(NSZone *)zone
{
	return [[[self class] allocWithZone:zone] initWithRequest:self.request];
}
- (BOOL)isEqual:(id)other
{
	if(self == other)
	{
		return YES;
	}
	if(!other || ![other isKindOfClass:[self class]])
	{
		return NO;
	}
	return self.request == ((TSRequestWrapper *)other).request;
}
- (NSUInteger)hash
{
	return (NSUInteger)self.request;
}
- (void)dealloc
{
	self.request = nil;
	SUPER_DEALLOC;
}
@end





@interface TSAppEventSourceImpl()

@property(nonatomic, STRONG_OR_RETAIN) id<NSObject> foregroundedEventObserver;
@property(nonatomic, copy) TSOpenHandler onOpen;
@property(nonatomic, copy) TSTransactionHandler onTransaction;
@property(nonatomic, STRONG_OR_RETAIN) NSMutableDictionary *requestTransactions;
@property(nonatomic, STRONG_OR_RETAIN) NSMutableDictionary *transactionReceiptSnapshots;

- (id)init;
- (void)dealloc;

@end


@implementation TSAppEventSourceImpl

@synthesize foregroundedEventObserver, onOpen, onTransaction, requestTransactions, transactionReceiptSnapshots;

- (id)init
{
	if((self = [super init]) != nil)
	{
		TSLoadStoreKitClasses();

#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		self.foregroundedEventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if(onOpen != nil)
			{
				onOpen();
			}
		}];
#endif
		
		if(TSSKPaymentQueue != nil)
		{
			self.requestTransactions = [NSMutableDictionary dictionary];
			[(id)[TSSKPaymentQueue defaultQueue] addTransactionObserver:self];
		}
		self.transactionReceiptSnapshots = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction *transaction in transactions)
	{
		switch(transaction.transactionState)
		{
			case SKPaymentTransactionStatePurchased:
			{
				
				// Load receipt data and stash it for use after the transaction is finished.
				// Note:  We have to grab this data now because consumable purchases get removed from
				// the receipt after the transaction is finished.
				
				NSData *receipt = nil;
				
#if TEST_IOS || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
				// For ios 7 and up, try to get the Grand Unified Receipt
				// If we can't get that, fall back to the transactionReceipt
				if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
				{
					receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
				}
				if(!receipt)
				{
					receipt = transaction.transactionReceipt;
				}
#else
				// For mac, try to load the receipt out of the bundle.  If appStoreReceiptURL method is
				// available, use it.
				NSURL *receiptUrl;
				if([[NSBundle mainBundle] respondsToSelector:@selector(appStoreReceiptURL)])
				{
					receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
				}
				else
				{
					receiptUrl = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
				}
				receipt = [NSData dataWithContentsOfURL:receiptUrl];
#endif
				
				if(receipt && transaction.transactionIdentifier != nil)
				{
					@synchronized(self)
					{
						[self.transactionReceiptSnapshots setObject:receipt forKey:transaction.transactionIdentifier];
					}
				}
			}
			break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
	if(onTransaction != nil)
	{
		NSMutableDictionary *transForProduct = [NSMutableDictionary dictionary];
		for(SKPaymentTransaction *trans in transactions)
		{
			if(trans.transactionState == SKPaymentTransactionStatePurchased)
			{
				[transForProduct setValue:trans forKey:trans.payment.productIdentifier];
			}
		}

		if([transForProduct count] > 0)
		{
			SKProductsRequest *req = AUTORELEASE([[TSSKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:[transForProduct allKeys]]]);
			req.delegate = self;
			@synchronized(self)
			{
				[self.requestTransactions setObject:transForProduct forKey:[TSRequestWrapper requestWrapperWithRequest:req]];
			}
			[req start];
		}
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	NSMutableDictionary *transactions = nil;
	@synchronized(self)
	{
		TSRequestWrapper *key = [TSRequestWrapper requestWrapperWithRequest:request];
		transactions = RETAIN([self.requestTransactions objectForKey:key]);
		[self.requestTransactions removeObjectForKey:key];
	}
	if(transactions)
	{
		for(SKProduct *product in response.products)
		{
			SKPaymentTransaction *transaction = [transactions objectForKey:product.productIdentifier];
			if(transaction)
			{
				NSData *receipt = nil;
				@synchronized(self)
				{
					receipt = RETAIN([self.transactionReceiptSnapshots objectForKey:transaction.transactionIdentifier]);
					[self.transactionReceiptSnapshots removeObjectForKey:transaction.transactionIdentifier];
				}
				
				NSString *b64Receipt = @"";
				if(receipt)
				{
					if([receipt respondsToSelector:@selector(base64EncodedStringWithOptions:)])
					{
						b64Receipt = [receipt base64EncodedStringWithOptions:0];
					}
					else
					{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
						b64Receipt = [receipt base64Encoding];
#pragma clang diagnostic pop
					}
				}
				
				onTransaction(transaction.transactionIdentifier,
					product.productIdentifier,
					(int)transaction.payment.quantity,
					(int)([product.price doubleValue] * 100),
					[product.priceLocale objectForKey:NSLocaleCurrencyCode],
					b64Receipt
					);

                RELEASE(receipt);
            }
		}
		RELEASE(transactions);
	}
}

- (void)setOpenHandler:(TSOpenHandler)handler
{
	self.onOpen = handler;
}

- (void)setTransactionHandler:(TSTransactionHandler)handler
{
	self.onTransaction = handler;
}

- (void)dealloc
{
	if(TSSKPaymentQueue != nil)
	{
		[(id)[TSSKPaymentQueue defaultQueue] removeTransactionObserver:self];
	}

	if(foregroundedEventObserver != nil)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:foregroundedEventObserver];
	}

	RELEASE(foregroundedEventObserver);
	RELEASE(requestTransactions);
	RELEASE(transactionReceiptSnapshots);
	SUPER_DEALLOC;
}

@end




