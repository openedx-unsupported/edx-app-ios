#import <Foundation/Foundation.h>

#import "FIRPerformanceAttributable.h"

/* Different HTTP methods. */
typedef NS_ENUM(NSInteger, FIRHTTPMethod) {
  /** HTTP Method GET */
  FIRHTTPMethodGET NS_SWIFT_NAME(get),
  /** HTTP Method PUT */
  FIRHTTPMethodPUT NS_SWIFT_NAME(put),
  /** HTTP Method POST */
  FIRHTTPMethodPOST NS_SWIFT_NAME(post),
  /** HTTP Method DELETE */
  FIRHTTPMethodDELETE NS_SWIFT_NAME(delete),
  /** HTTP Method HEAD */
  FIRHTTPMethodHEAD NS_SWIFT_NAME(head),
  /** HTTP Method PATCH */
  FIRHTTPMethodPATCH NS_SWIFT_NAME(patch),
  /** HTTP Method OPTIONS */
  FIRHTTPMethodOPTIONS NS_SWIFT_NAME(options),
  /** HTTP Method TRACE */
  FIRHTTPMethodTRACE NS_SWIFT_NAME(trace),
  /** HTTP Method CONNECT */
  FIRHTTPMethodCONNECT NS_SWIFT_NAME(connect)
} NS_SWIFT_NAME(HTTPMethod);

/**
 * FIRHTTPMetric object can be used to make the SDK record information about a HTTP network request.
 */
NS_SWIFT_NAME(HTTPMetric)
@interface FIRHTTPMetric : NSObject <FIRPerformanceAttributable>

/**
 * Creates HTTPMetric object for a network request.
 * @param URL The URL for which the metrics are recorded.
 * @param httpMethod HTTP method used by the request.
 */
- (nullable instancetype)initWithURL:(nonnull NSURL *)URL HTTPMethod:(FIRHTTPMethod)httpMethod
    NS_SWIFT_NAME(init(url:httpMethod:));

/**
 * Use `initWithURL:HTTPMethod:` for Objective-C and `init(url:httpMethod:)` for Swift.
 */
- (nonnull instancetype)init NS_UNAVAILABLE;

/**
 * @brief HTTP Response code. Values are greater than 0.
 */
@property(nonatomic, assign) NSInteger responseCode;

/**
 * @brief Size of the request payload.
 */
@property(nonatomic, assign) long requestPayloadSize;

/**
 * @brief Size of the response payload.
 */
@property(nonatomic, assign) long responsePayloadSize;

/**
 * @brief HTTP Response content type.
 */
@property(nonatomic, nullable, copy) NSString *responseContentType;

/**
 * Marks the start time of the request.
 */
- (void)start;

/**
 * Marks the end time of the response and queues the network request metric on the device for
 * transmission. Check the logs if the metric is valid.
 */
- (void)stop;

@end
