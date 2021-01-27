#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SEGAES256Crypto.h"
#import "SEGCrypto.h"
#import "SEGAliasPayload.h"
#import "SEGGroupPayload.h"
#import "SEGIdentifyPayload.h"
#import "SEGIntegration.h"
#import "SEGIntegrationFactory.h"
#import "SEGIntegrationsManager.h"
#import "SEGPayload.h"
#import "SEGScreenPayload.h"
#import "SEGTrackPayload.h"
#import "NSData+SEGGZIP.h"
#import "SEGAnalyticsUtils.h"
#import "SEGFileStorage.h"
#import "SEGHTTPClient.h"
#import "SEGSegmentIntegration.h"
#import "SEGSegmentIntegrationFactory.h"
#import "SEGStorage.h"
#import "SEGStoreKitTracker.h"
#import "SEGUserDefaultsStorage.h"
#import "SEGUtils.h"
#import "UIViewController+SEGScreen.h"
#import "SEGContext.h"
#import "SEGMiddleware.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsConfiguration.h"
#import "SEGSerializableValue.h"
#import "SEGReachability.h"

FOUNDATION_EXPORT double AnalyticsVersionNumber;
FOUNDATION_EXPORT const unsigned char AnalyticsVersionString[];

