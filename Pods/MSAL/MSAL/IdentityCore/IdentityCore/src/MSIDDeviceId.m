// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDDeviceId.h"
#import "MSIDVersion.h"
#import "MSIDConstants.h"
#import "MSIDOAuth2Constants.h"

#if !TARGET_OS_IPHONE
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#endif

@implementation MSIDDeviceId

#if !TARGET_OS_IPHONE
// Returns the serial number as a CFString.
// It is the caller's responsibility to release the returned CFString when done with it.
void CopySerialNumber(CFStringRef *serialNumber)
{
    if (serialNumber != NULL)
    {
        *serialNumber = NULL;
        
        io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                     IOServiceMatching("IOPlatformExpertDevice"));
        
        if (platformExpert)
        {
            CFTypeRef serialNumberAsCFString =
            IORegistryEntryCreateCFProperty(platformExpert,
                                            CFSTR(kIOPlatformSerialNumberKey),
                                            kCFAllocatorDefault, 0);
            if (serialNumberAsCFString)
            {
                *serialNumber = serialNumberAsCFString;
            }
            
            IOObjectRelease(platformExpert);
        }
    }
}
#endif

//Extracts the CPU information according to the constants defined in
//machine.h file. The method prints minimal information - only if 32 or
//64 bit CPU architecture is being used.
+ (NSString*)getCPUInfo
{
    size_t structSize;
    cpu_type_t cpuType;
    structSize = sizeof(cpuType);
    
    //Extract the CPU type. E.g. x86. See machine.h for details
    //See sysctl.h for details.
    int result = sysctlbyname("hw.cputype", &cpuType, &structSize, NULL, 0);
    if (result)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Cannot extract cpu type. Error: %d", result);
        return nil;
    }
    
    return (CPU_ARCH_ABI64 & cpuType) ? @"64" : @"32";
}

/*! Returns diagnostic trace data to be sent to the Auzure Active Directory servers. */
+ (NSDictionary *)deviceId
{
    static NSMutableDictionary *s_adalId = nil;
    static dispatch_once_t deviceIdOnce;
    
    dispatch_once(&deviceIdOnce, ^{
#if TARGET_OS_IPHONE
        //iOS:
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:
                                       @{
                                         MSID_PLATFORM_KEY: [MSIDVersion platformName],
                                         MSID_VERSION_KEY: [MSIDVersion sdkVersion],
                                         MSID_OS_VER_KEY: [self deviceOSVersion],
                                         MSID_DEVICE_MODEL_KEY: [UIDevice currentDevice].model,
                                         }];
#else
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:
                                       @{
                                         MSID_PLATFORM_KEY: [MSIDVersion platformName],
                                         MSID_VERSION_KEY: [MSIDVersion sdkVersion],
                                         MSID_OS_VER_KEY: [self deviceOSVersion],
                                         }];
#endif
        NSString *CPUVer = [self getCPUInfo];
        
        if (![NSString msidIsStringNilOrBlank:CPUVer])
        {
            [result setObject:CPUVer forKey:MSID_CPU_KEY];
        }
        
        s_adalId = result;
    });
    
    return s_adalId;
}

+ (NSString *)deviceOSVersion
{
#if TARGET_OS_IPHONE
    return [UIDevice currentDevice].systemVersion;
#else
    NSOperatingSystemVersion osVersion = [[NSProcessInfo processInfo] operatingSystemVersion];
    return [NSString stringWithFormat:@"%ld.%ld.%ld", (long)osVersion.majorVersion, (long)osVersion.minorVersion, (long)osVersion.patchVersion];
#endif
}

+ (NSString *)deviceOSId
{
    static NSString *s_OSString = @"UnkOS";
    static dispatch_once_t osStringOnce;
    
    dispatch_once(&osStringOnce, ^{
        
#if TARGET_OS_IPHONE
#if TARGET_OS_SIMULATOR
        s_OSString = [NSString stringWithFormat:@"iOS Sim %@", [self deviceOSVersion]];
#else
        s_OSString = [NSString stringWithFormat:@"iOS %@", [self deviceOSVersion]];
#endif
#elif TARGET_OS_WATCH
#error watchOS is not supported
#elif TARGET_OS_TV
#error tvOS is not supported
#else
        s_OSString = [NSString stringWithFormat:@"Mac %@", [self deviceOSVersion]];
#endif
    });
    
    return s_OSString;
}

+ (NSString *)deviceTelemetryId
{
#if TARGET_OS_IPHONE
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#else
    CFStringRef macSerialNumber = nil;
    CopySerialNumber(&macSerialNumber);
    NSString *deviceId = CFBridgingRelease(macSerialNumber);
    return deviceId;
#endif
}

+ (NSString *)applicationName
{
#if TARGET_OS_IPHONE
    return [[NSBundle mainBundle] bundleIdentifier];
#else
    return [[NSProcessInfo processInfo] processName];
#endif
}

/*! Returns application version for telemetry purposes. */
+ (NSString *)applicationVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

+ (void)setIdValue:(NSString *)value
            forKey:(NSString *)key
{
    [(NSMutableDictionary *)[self deviceId] setObject:value forKey:key];
}

@end
