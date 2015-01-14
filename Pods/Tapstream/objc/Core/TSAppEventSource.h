#pragma once
#import <Foundation/Foundation.h>

typedef void(^TSOpenHandler)();

// Args: transactionId, productId, quantity, priceCents, currencyCode, base64Receipt
typedef void(^TSTransactionHandler)(NSString *, NSString *, int, int, NSString *, NSString *);


@protocol TSAppEventSource<NSObject>
- (void)setOpenHandler:(TSOpenHandler)handler;
- (void)setTransactionHandler:(TSTransactionHandler)handler;
@end
