//
//  OEXHTTPStatusCodes.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger, OEXHTTPStatusCode) {
    // Informational
    OEXHTTPStatusCode100Continue = 100,
    OEXHTTPStatusCode101SwitchingProtocols = 101,
    OEXHTTPStatusCode102Processing = 102,

    // Success
    OEXHTTPStatusCode200OK = 200,
    OEXHTTPStatusCode201Created = 201,
    OEXHTTPStatusCode202Accepted = 202,
    OEXHTTPStatusCode203NonAuthoritativeInformation = 203,
    OEXHTTPStatusCode204NoContent = 204,
    OEXHTTPStatusCode205ResetContent = 205,
    OEXHTTPStatusCode206PartialContent = 206,
    OEXHTTPStatusCode207MultiStatus = 207,
    OEXHTTPStatusCode208AlreadyReported = 208,
    OEXHTTPStatusCode209IMUsed = 209,

    // Redirection
    OEXHTTPStatusCode300MultipleChoices = 300,
    OEXHTTPStatusCode301MovedPermanently = 301,
    OEXHTTPStatusCode302Found = 302,
    OEXHTTPStatusCode303SeeOther = 303,
    OEXHTTPStatusCode304NotModified = 304,
    OEXHTTPStatusCode305UseProxy = 305,
    OEXHTTPStatusCode306SwitchProxy = 306,
    OEXHTTPStatusCode307TemporaryRedirect = 307,
    OEXHTTPStatusCode308PermanentRedirect = 308,

    // Client error
    OEXHTTPStatusCode400BadRequest = 400,
    OEXHTTPStatusCode401Unauthorised = 401,
    OEXHTTPStatusCode402PaymentRequired = 402,
    OEXHTTPStatusCode403Forbidden = 403,
    OEXHTTPStatusCode404NotFound = 404,
    OEXHTTPStatusCode405MethodNotAllowed = 405,
    OEXHTTPStatusCode406NotAcceptable = 406,
    OEXHTTPStatusCode407ProxyAuthenticationRequired = 407,
    OEXHTTPStatusCode408RequestTimeout = 408,
    OEXHTTPStatusCode409Conflict = 409,
    OEXHTTPStatusCode410Gone = 410,
    OEXHTTPStatusCode411LengthRequired = 411,
    OEXHTTPStatusCode412PreconditionFailed = 412,
    OEXHTTPStatusCode413RequestEntityTooLarge = 413,
    OEXHTTPStatusCode414RequestURITooLong = 414,
    OEXHTTPStatusCode415UnsupportedMediaType = 415,
    OEXHTTPStatusCode416RequestedRangeNotSatisfiable = 416,
    OEXHTTPStatusCode417ExpectationFailed = 417,
    OEXHTTPStatusCode418IamATeapot = 418,
    OEXHTTPStatusCode419AuthenticationTimeout = 419,
    OEXHTTPStatusCode420MethodFailureSpringFramework = 420,
    OEXHTTPStatusCode420EnhanceYourCalmTwitter = 4200,
    OEXHTTPStatusCode422UnprocessableEntity = 422,
    OEXHTTPStatusCode423Locked = 423,
    OEXHTTPStatusCode424FailedDependency = 424,
    OEXHTTPStatusCode424MethodFailureWebDaw = 4240,
    OEXHTTPStatusCode425UnorderedCollection = 425,
    OEXHTTPStatusCode426UpgradeRequired = 426,
    OEXHTTPStatusCode428PreconditionRequired = 428,
    OEXHTTPStatusCode429TooManyRequests = 429,
    OEXHTTPStatusCode431RequestHeaderFieldsTooLarge = 431,
    OEXHTTPStatusCode444NoResponseNginx = 444,
    OEXHTTPStatusCode449RetryWithMicrosoft = 449,
    OEXHTTPStatusCode450BlockedByWindowsParentalControls = 450,
    OEXHTTPStatusCode451RedirectMicrosoft = 451,
    OEXHTTPStatusCode451UnavailableForLegalReasons = 4510,
    OEXHTTPStatusCode494RequestHeaderTooLargeNginx = 494,
    OEXHTTPStatusCode495CertErrorNginx = 495,
    OEXHTTPStatusCode496NoCertNginx = 496,
    OEXHTTPStatusCode497HTTPToHTTPSNginx = 497,
    OEXHTTPStatusCode499ClientClosedRequestNginx = 499,

    // Server error
    OEXHTTPStatusCode500InternalServerError = 500,
    OEXHTTPStatusCode501NotImplemented = 501,
    OEXHTTPStatusCode502BadGateway = 502,
    OEXHTTPStatusCode503ServiceUnavailable = 503,
    OEXHTTPStatusCode504GatewayTimeout = 504,
    OEXHTTPStatusCode505HTTPVersionNotSupported = 505,
    OEXHTTPStatusCode506VariantAlsoNegotiates = 506,
    OEXHTTPStatusCode507InsufficientStorage = 507,
    OEXHTTPStatusCode508LoopDetected = 508,
    OEXHTTPStatusCode509BandwidthLimitExceeded = 509,
    OEXHTTPStatusCode510NotExtended = 510,
    OEXHTTPStatusCode511NetworkAuthenticationRequired = 511,
    OEXHTTPStatusCode522ConnectionTimedOut = 522,
    OEXHTTPStatusCode598NetworkReadTimeoutErrorUnknown = 598,
    OEXHTTPStatusCode599NetworkConnectTimeoutErrorUnknown = 599
};