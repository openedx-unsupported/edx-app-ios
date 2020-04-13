/*
 * Copyright 2019 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: wireless/android/config/proto/config.proto

// This CPP symbol can be defined to use imports that match up to the framework
// imports needed when using CocoaPods.
#if !defined(GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS)
 #define GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS 0
#endif

#if GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS
 #import <Protobuf/GPBProtocolBuffers.h>
#else
 #import "GPBProtocolBuffers.h"
#endif

#if GOOGLE_PROTOBUF_OBJC_VERSION < 30002
#error This file was generated by a newer version of protoc which is incompatible with your Protocol Buffer library sources.
#endif
#if 30002 < GOOGLE_PROTOBUF_OBJC_MIN_SUPPORTED_VERSION
#error This file was generated by an older version of protoc which is incompatible with your Protocol Buffer library sources.
#endif

// @@protoc_insertion_point(imports)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

CF_EXTERN_C_BEGIN

@class AndroidConfigFetchProto;
@class RCNAppConfigTable;
@class RCNAppNamespaceConfigTable;
@class RCNKeyValue;
@class RCNNamedValue;
@class RCNPackageData;
@class RCNPackageTable;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum RCNConfigDeviceType

typedef GPB_ENUM(RCNConfigDeviceType) {
  RCNConfigDeviceType_Unknown = 0,
  RCNConfigDeviceType_Android = 1,
  RCNConfigDeviceType_Ios = 2,
  RCNConfigDeviceType_ChromeBrowser = 3,
  RCNConfigDeviceType_ChromeOs = 4,
  RCNConfigDeviceType_Desktop = 5,
};

GPBEnumDescriptor *RCNConfigDeviceType_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL RCNConfigDeviceType_IsValidValue(int32_t value);

#pragma mark - Enum RCNAppNamespaceConfigTable_NamespaceStatus

typedef GPB_ENUM(RCNAppNamespaceConfigTable_NamespaceStatus) {
  RCNAppNamespaceConfigTable_NamespaceStatus_Update = 0,
  RCNAppNamespaceConfigTable_NamespaceStatus_NoTemplate = 1,
  RCNAppNamespaceConfigTable_NamespaceStatus_NoChange = 2,
  RCNAppNamespaceConfigTable_NamespaceStatus_EmptyConfig = 3,
  RCNAppNamespaceConfigTable_NamespaceStatus_NotAuthorized = 4,
};

GPBEnumDescriptor *RCNAppNamespaceConfigTable_NamespaceStatus_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL RCNAppNamespaceConfigTable_NamespaceStatus_IsValidValue(int32_t value);

#pragma mark - Enum RCNConfigFetchResponse_ResponseStatus

typedef GPB_ENUM(RCNConfigFetchResponse_ResponseStatus) {
  RCNConfigFetchResponse_ResponseStatus_Success = 0,
  RCNConfigFetchResponse_ResponseStatus_NoPackagesInRequest = 1,
};

GPBEnumDescriptor *RCNConfigFetchResponse_ResponseStatus_EnumDescriptor(void);

/**
 * Checks to see if the given value is defined by the enum or was not known at
 * the time this source was generated.
 **/
BOOL RCNConfigFetchResponse_ResponseStatus_IsValidValue(int32_t value);

#pragma mark - RCNConfigRoot

/**
 * Exposes the extension registry for this file.
 *
 * The base class provides:
 * @code
 *   + (GPBExtensionRegistry *)extensionRegistry;
 * @endcode
 * which is a @c GPBExtensionRegistry that includes all the extensions defined by
 * this file and all files that it depends on.
 **/
@interface RCNConfigRoot : GPBRootObject
@end

#pragma mark - RCNPackageData

typedef GPB_ENUM(RCNPackageData_FieldNumber) {
  RCNPackageData_FieldNumber_PackageName = 1,
  RCNPackageData_FieldNumber_VersionCode = 2,
  RCNPackageData_FieldNumber_Digest = 3,
  RCNPackageData_FieldNumber_CertHash = 4,
  RCNPackageData_FieldNumber_ProjectId = 5,
  RCNPackageData_FieldNumber_GmpProjectId = 6,
  RCNPackageData_FieldNumber_GamesProjectId = 7,
  RCNPackageData_FieldNumber_NamespaceDigestArray = 8,
  RCNPackageData_FieldNumber_CustomVariableArray = 9,
  RCNPackageData_FieldNumber_AppCertHash = 10,
  RCNPackageData_FieldNumber_AppVersionCode = 11,
  RCNPackageData_FieldNumber_AppInstanceId = 12,
  RCNPackageData_FieldNumber_AppVersion = 13,
  RCNPackageData_FieldNumber_AppInstanceIdToken = 14,
  RCNPackageData_FieldNumber_RequestedHiddenNamespaceArray = 15,
  RCNPackageData_FieldNumber_SdkVersion = 16,
  RCNPackageData_FieldNumber_AnalyticsUserPropertyArray = 17,
  RCNPackageData_FieldNumber_RequestedCacheExpirationSeconds = 18,
  RCNPackageData_FieldNumber_FetchedConfigAgeSeconds = 19,
  RCNPackageData_FieldNumber_ActiveConfigAgeSeconds = 20,
};

@interface RCNPackageData : GPBMessage


@property(nonatomic, readwrite) int32_t versionCode;

@property(nonatomic, readwrite) BOOL hasVersionCode;

@property(nonatomic, readwrite, copy, null_resettable) NSData *digest;
/** Test to see if @c digest has been set. */
@property(nonatomic, readwrite) BOOL hasDigest;


@property(nonatomic, readwrite, copy, null_resettable) NSData *certHash;
/** Test to see if @c certHash has been set. */
@property(nonatomic, readwrite) BOOL hasCertHash;


@property(nonatomic, readwrite, copy, null_resettable) NSString *projectId;
/** Test to see if @c projectId has been set. */
@property(nonatomic, readwrite) BOOL hasProjectId;


@property(nonatomic, readwrite, copy, null_resettable) NSString *packageName;
/** Test to see if @c packageName has been set. */
@property(nonatomic, readwrite) BOOL hasPackageName;


@property(nonatomic, readwrite, copy, null_resettable) NSString *gmpProjectId;
/** Test to see if @c gmpProjectId has been set. */
@property(nonatomic, readwrite) BOOL hasGmpProjectId;


@property(nonatomic, readwrite, copy, null_resettable) NSString *gamesProjectId;
/** Test to see if @c gamesProjectId has been set. */
@property(nonatomic, readwrite) BOOL hasGamesProjectId;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNNamedValue*> *namespaceDigestArray;
/** The number of items in @c namespaceDigestArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger namespaceDigestArray_Count;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNNamedValue*> *customVariableArray;
/** The number of items in @c customVariableArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger customVariableArray_Count;


@property(nonatomic, readwrite, copy, null_resettable) NSData *appCertHash;
/** Test to see if @c appCertHash has been set. */
@property(nonatomic, readwrite) BOOL hasAppCertHash;


@property(nonatomic, readwrite) int32_t appVersionCode;

@property(nonatomic, readwrite) BOOL hasAppVersionCode;

@property(nonatomic, readwrite, copy, null_resettable) NSString *appVersion;
/** Test to see if @c appVersion has been set. */
@property(nonatomic, readwrite) BOOL hasAppVersion;


@property(nonatomic, readwrite, copy, null_resettable) NSString *appInstanceId;
/** Test to see if @c appInstanceId has been set. */
@property(nonatomic, readwrite) BOOL hasAppInstanceId;


@property(nonatomic, readwrite, copy, null_resettable) NSString *appInstanceIdToken;
/** Test to see if @c appInstanceIdToken has been set. */
@property(nonatomic, readwrite) BOOL hasAppInstanceIdToken;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<NSString*> *requestedHiddenNamespaceArray;
/** The number of items in @c requestedHiddenNamespaceArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger requestedHiddenNamespaceArray_Count;


@property(nonatomic, readwrite) int32_t sdkVersion;

@property(nonatomic, readwrite) BOOL hasSdkVersion;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNNamedValue*> *analyticsUserPropertyArray;
/** The number of items in @c analyticsUserPropertyArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger analyticsUserPropertyArray_Count;


@property(nonatomic, readwrite) int32_t requestedCacheExpirationSeconds;

@property(nonatomic, readwrite) BOOL hasRequestedCacheExpirationSeconds;

@property(nonatomic, readwrite) int32_t fetchedConfigAgeSeconds;

@property(nonatomic, readwrite) BOOL hasFetchedConfigAgeSeconds;

@property(nonatomic, readwrite) int32_t activeConfigAgeSeconds;

@property(nonatomic, readwrite) BOOL hasActiveConfigAgeSeconds;
@end

#pragma mark - RCNKeyValue

typedef GPB_ENUM(RCNKeyValue_FieldNumber) {
  RCNKeyValue_FieldNumber_Key = 1,
  RCNKeyValue_FieldNumber_Value = 2,
};

@interface RCNKeyValue : GPBMessage


@property(nonatomic, readwrite, copy, null_resettable) NSString *key;
/** Test to see if @c key has been set. */
@property(nonatomic, readwrite) BOOL hasKey;


@property(nonatomic, readwrite, copy, null_resettable) NSData *value;
/** Test to see if @c value has been set. */
@property(nonatomic, readwrite) BOOL hasValue;

@end

#pragma mark - RCNNamedValue

typedef GPB_ENUM(RCNNamedValue_FieldNumber) {
  RCNNamedValue_FieldNumber_Name = 1,
  RCNNamedValue_FieldNumber_Value = 2,
};

@interface RCNNamedValue : GPBMessage


@property(nonatomic, readwrite, copy, null_resettable) NSString *name;
/** Test to see if @c name has been set. */
@property(nonatomic, readwrite) BOOL hasName;


@property(nonatomic, readwrite, copy, null_resettable) NSString *value;
/** Test to see if @c value has been set. */
@property(nonatomic, readwrite) BOOL hasValue;

@end

#pragma mark - RCNConfigFetchRequest

typedef GPB_ENUM(RCNConfigFetchRequest_FieldNumber) {
  RCNConfigFetchRequest_FieldNumber_AndroidId = 1,
  RCNConfigFetchRequest_FieldNumber_PackageDataArray = 2,
  RCNConfigFetchRequest_FieldNumber_DeviceDataVersionInfo = 3,
  RCNConfigFetchRequest_FieldNumber_SecurityToken = 4,
  RCNConfigFetchRequest_FieldNumber_Config = 5,
  RCNConfigFetchRequest_FieldNumber_ClientVersion = 6,
  RCNConfigFetchRequest_FieldNumber_GmsCoreVersion = 7,
  RCNConfigFetchRequest_FieldNumber_ApiLevel = 8,
  RCNConfigFetchRequest_FieldNumber_DeviceCountry = 9,
  RCNConfigFetchRequest_FieldNumber_DeviceLocale = 10,
  RCNConfigFetchRequest_FieldNumber_DeviceType = 11,
  RCNConfigFetchRequest_FieldNumber_DeviceSubtype = 12,
  RCNConfigFetchRequest_FieldNumber_OsVersion = 13,
  RCNConfigFetchRequest_FieldNumber_DeviceTimezoneId = 14,
};

@interface RCNConfigFetchRequest : GPBMessage


@property(nonatomic, readwrite, strong, null_resettable) AndroidConfigFetchProto *config;
/** Test to see if @c config has been set. */
@property(nonatomic, readwrite) BOOL hasConfig;


@property(nonatomic, readwrite) uint64_t androidId;

@property(nonatomic, readwrite) BOOL hasAndroidId;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNPackageData*> *packageDataArray;
/** The number of items in @c packageDataArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger packageDataArray_Count;


@property(nonatomic, readwrite, copy, null_resettable) NSString *deviceDataVersionInfo;
/** Test to see if @c deviceDataVersionInfo has been set. */
@property(nonatomic, readwrite) BOOL hasDeviceDataVersionInfo;


@property(nonatomic, readwrite) uint64_t securityToken;

@property(nonatomic, readwrite) BOOL hasSecurityToken;

@property(nonatomic, readwrite) int32_t clientVersion;

@property(nonatomic, readwrite) BOOL hasClientVersion;

@property(nonatomic, readwrite) int32_t gmsCoreVersion;

@property(nonatomic, readwrite) BOOL hasGmsCoreVersion;

@property(nonatomic, readwrite) int32_t apiLevel;

@property(nonatomic, readwrite) BOOL hasApiLevel;

@property(nonatomic, readwrite, copy, null_resettable) NSString *deviceCountry;
/** Test to see if @c deviceCountry has been set. */
@property(nonatomic, readwrite) BOOL hasDeviceCountry;


@property(nonatomic, readwrite, copy, null_resettable) NSString *deviceLocale;
/** Test to see if @c deviceLocale has been set. */
@property(nonatomic, readwrite) BOOL hasDeviceLocale;


@property(nonatomic, readwrite) int32_t deviceType;

@property(nonatomic, readwrite) BOOL hasDeviceType;

@property(nonatomic, readwrite) int32_t deviceSubtype;

@property(nonatomic, readwrite) BOOL hasDeviceSubtype;

@property(nonatomic, readwrite, copy, null_resettable) NSString *osVersion;
/** Test to see if @c osVersion has been set. */
@property(nonatomic, readwrite) BOOL hasOsVersion;


@property(nonatomic, readwrite, copy, null_resettable) NSString *deviceTimezoneId;
/** Test to see if @c deviceTimezoneId has been set. */
@property(nonatomic, readwrite) BOOL hasDeviceTimezoneId;

@end

#pragma mark - RCNPackageTable

typedef GPB_ENUM(RCNPackageTable_FieldNumber) {
  RCNPackageTable_FieldNumber_PackageName = 1,
  RCNPackageTable_FieldNumber_EntryArray = 2,
  RCNPackageTable_FieldNumber_ProjectId = 3,
};

@interface RCNPackageTable : GPBMessage


@property(nonatomic, readwrite, copy, null_resettable) NSString *packageName;
/** Test to see if @c packageName has been set. */
@property(nonatomic, readwrite) BOOL hasPackageName;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNKeyValue*> *entryArray;
/** The number of items in @c entryArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger entryArray_Count;


@property(nonatomic, readwrite, copy, null_resettable) NSString *projectId;
/** Test to see if @c projectId has been set. */
@property(nonatomic, readwrite) BOOL hasProjectId;

@end

#pragma mark - RCNAppNamespaceConfigTable

typedef GPB_ENUM(RCNAppNamespaceConfigTable_FieldNumber) {
  RCNAppNamespaceConfigTable_FieldNumber_Namespace_p = 1,
  RCNAppNamespaceConfigTable_FieldNumber_Digest = 2,
  RCNAppNamespaceConfigTable_FieldNumber_EntryArray = 3,
  RCNAppNamespaceConfigTable_FieldNumber_Status = 4,
};

@interface RCNAppNamespaceConfigTable : GPBMessage


@property(nonatomic, readwrite, copy, null_resettable) NSString *namespace_p;
/** Test to see if @c namespace_p has been set. */
@property(nonatomic, readwrite) BOOL hasNamespace_p;


@property(nonatomic, readwrite, copy, null_resettable) NSString *digest;
/** Test to see if @c digest has been set. */
@property(nonatomic, readwrite) BOOL hasDigest;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNKeyValue*> *entryArray;
/** The number of items in @c entryArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger entryArray_Count;


@property(nonatomic, readwrite) RCNAppNamespaceConfigTable_NamespaceStatus status;

@property(nonatomic, readwrite) BOOL hasStatus;
@end

#pragma mark - RCNAppConfigTable

typedef GPB_ENUM(RCNAppConfigTable_FieldNumber) {
  RCNAppConfigTable_FieldNumber_AppName = 1,
  RCNAppConfigTable_FieldNumber_NamespaceConfigArray = 2,
  RCNAppConfigTable_FieldNumber_ExperimentPayloadArray = 3,
  RCNAppConfigTable_FieldNumber_EnabledFeatureKeysArray = 5,
};

@interface RCNAppConfigTable : GPBMessage


@property(nonatomic, readwrite, copy, null_resettable) NSString *appName;
/** Test to see if @c appName has been set. */
@property(nonatomic, readwrite) BOOL hasAppName;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNAppNamespaceConfigTable*> *namespaceConfigArray;
/** The number of items in @c namespaceConfigArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger namespaceConfigArray_Count;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<NSData*> *experimentPayloadArray;
/** The number of items in @c experimentPayloadArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger experimentPayloadArray_Count;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<NSString*> *enabledFeatureKeysArray;
/** The number of items in @c enabledFeatureKeysArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger enabledFeatureKeysArray_Count;

@end

#pragma mark - RCNConfigFetchResponse

typedef GPB_ENUM(RCNConfigFetchResponse_FieldNumber) {
  RCNConfigFetchResponse_FieldNumber_PackageTableArray = 1,
  RCNConfigFetchResponse_FieldNumber_Status = 2,
  RCNConfigFetchResponse_FieldNumber_InternalMetadataArray = 3,
  RCNConfigFetchResponse_FieldNumber_AppConfigArray = 4,
};

@interface RCNConfigFetchResponse : GPBMessage


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNPackageTable*> *packageTableArray;
/** The number of items in @c packageTableArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger packageTableArray_Count;


@property(nonatomic, readwrite) RCNConfigFetchResponse_ResponseStatus status;

@property(nonatomic, readwrite) BOOL hasStatus;

@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNKeyValue*> *internalMetadataArray;
/** The number of items in @c internalMetadataArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger internalMetadataArray_Count;


@property(nonatomic, readwrite, strong, null_resettable) NSMutableArray<RCNAppConfigTable*> *appConfigArray;
/** The number of items in @c appConfigArray without causing the array to be created. */
@property(nonatomic, readonly) NSUInteger appConfigArray_Count;

@end

NS_ASSUME_NONNULL_END

CF_EXTERN_C_END

#pragma clang diagnostic pop

// @@protoc_insertion_point(global_scope)