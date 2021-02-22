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

#import "SLLocalization.h"
#import "SmartlingLib.h"

FOUNDATION_EXPORT double Smartling_i18nVersionNumber;
FOUNDATION_EXPORT const unsigned char Smartling_i18nVersionString[];

