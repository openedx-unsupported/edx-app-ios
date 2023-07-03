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

#import "MSAL.h"
#import "MSALAADAuthority.h"
#import "MSALAccount+MultiTenantAccount.h"
#import "MSALAccount.h"
#import "MSALAccountEnumerationParameters.h"
#import "MSALAccountId.h"
#import "MSALADFSAuthority.h"
#import "MSALAuthenticationSchemeBearer.h"
#import "MSALAuthenticationSchemePop.h"
#import "MSALAuthenticationSchemeProtocol.h"
#import "MSALAuthority.h"
#import "MSALB2CAuthority.h"
#import "MSALClaimsRequest.h"
#import "MSALDefinitions.h"
#import "MSALDeviceInformation.h"
#import "MSALError.h"
#import "MSALHttpMethod.h"
#import "MSALIndividualClaimRequest.h"
#import "MSALIndividualClaimRequestAdditionalInfo.h"
#import "MSALInteractiveTokenParameters.h"
#import "MSALJsonDeserializable.h"
#import "MSALJsonSerializable.h"
#import "MSALLogger.h"
#import "MSALParameters.h"
#import "MSALPublicClientApplication+SingleAccount.h"
#import "MSALPublicClientApplication.h"
#import "MSALPublicClientStatusNotifications.h"
#import "MSALRedirectUri.h"
#import "MSALResult.h"
#import "MSALSignoutParameters.h"
#import "MSALSilentTokenParameters.h"
#import "MSALTelemetry.h"
#import "MSALTenantProfile.h"
#import "MSALTokenParameters.h"
#import "MSALWebviewParameters.h"
#import "MSALWPJMetaData.h"
#import "MSALLegacySharedAccountsProvider.h"
#import "MSALHTTPConfig.h"
#import "MSALLoggerConfig.h"
#import "MSALTelemetryConfig.h"
#import "MSALGlobalConfig.h"
#import "MSALPublicClientApplicationConfig.h"
#import "MSALCacheConfig.h"
#import "MSALExternalAccountProviding.h"
#import "MSALSerializedADALCacheProvider.h"
#import "MSALWipeCacheForAllAccountsConfig.h"
#import "MSALSliceConfig.h"

FOUNDATION_EXPORT double MSALVersionNumber;
FOUNDATION_EXPORT const unsigned char MSALVersionString[];

