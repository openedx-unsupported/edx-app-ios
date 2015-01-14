//
//  Copyright (c) 2014 Optimizely. All rights reserved.
//
//  Optimizely iOS SDK Uses Following Open Source Libraries
//       - AFDownloadRequestOperation
//       - AFNetworking
//       - CTObjectiveCRuntimeAdditions
//       - FMDB
//       - NSDateRFC1123
//       - SocketRocket
//
//  Contributors
//       - Kasra Kyanzadeh
//       - Yonatan Kogan
//       - Marco Sgrignuoli
//       - Richard Klafter
//       - Alex Medearis
//       - Chrix Finne
//       - Rama Ranganath
//       - Hemant Verma

#import "OptimizelyVariableKey.h"
#import "OptimizelyCodeBlocksKey.h"

typedef void (^OptimizelySuccessBlock)(BOOL success, NSError *error);

@interface UIView (Optimizely)
@property NSString *optimizelyId;
@end


/** This class defines the Optimizely SDK interface.
 *
 * The Optimizely SDK is organized around a singleton, accessible via
 * the `+sharedInstance` method. Through this singleton, you can configure
 * Optimizely.
 *
 * Methods associated with retrieving variables, code blocks and tracking goals are
 * available as class methods.
 */
@interface Optimizely : NSObject {
}

/** @name Initialization */

/** This method provides access to the Optimizely singleton.
 *
 * @return The Optimizely singleton
 */
+ (instancetype)sharedInstance;

/** Calling this activates the Optimizely framework. If not called, the app will behave
 * as though Optimizely wasn't included.
 *
 * This method attempts to fetch the latest Optimizely experiment data with a timeout of two seconds and returns immediately
 * after the data has been successfully loaded.  In the case of a timeout and when no experiment data is available, the user will
 * not be counted as a visitor to your experiment.
 *
 * @param apiToken The apiToken of your iOS project on Optimizely.
 * @param launchOptions A dictionary of launch options. This is typically the launch options
 * passed into `-application: didFinishLaunchingWithOptions:`.
 */
+ (void)startOptimizelyWithAPIToken:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions;

/** Calling this activates the Optimizely framework. If not called, the app will behave
 * as though Optimizely wasn't included.
 *
 * This method will return immediately.  However, accessing live variables, code blocks or Optimizely views
 * involved in an active experiment prior to receiving a successful callback will prevent the experiment
 * from running on this launch.
 *
 * @param apiToken The apiToken of your iOS project on Optimizely.
 * @param launchOptions A dictionary of launch options. This is typically the launch options
 * passed into `-application: didFinishLaunchingWithOptions:`.
 * @param experimentsLoadedCallback A block that will be executed when the Optimizely framework
 * has activated any experiments that pass targeting.
 * @discussion The experimentsLoadedCallback is guaranteed to be called exactly once.  If no data file has been cached
 * (e.g. if this is the first launch) then the experimentsLoadedCallback will not be called until
 * the latest experiments file has been downloaded from the server.
 * If the device is in edit mode, the callback will execute immediately.
 */
+ (void)startOptimizelyWithAPIToken:(NSString *)apiToken
                      launchOptions:(NSDictionary *)launchOptions
          experimentsLoadedCallback:(OptimizelySuccessBlock)experimentsLoadedCallback;

/** This method allows you to add custom tags for targeting.
 *
 * @param tagKey Key for custom tag
 * @param tagValue Value for custom tag
 * @warning This method should be called before +startOptimizelyWithAPIToken
 */

+ (void)setValue:(NSString *)tagValue forCustomTag:(NSString *)tagKey;


/** This method is intended to notify Optimizely that the app has been opened via URL and the
 * user wishes to enter edit mode.  Typically, this should be placed in `application:handleOpenURL:`
 * @param url The url passed to `application:handleOpenURL:`
 * @return Returns true if the provided URL is an Optimizely URL, false otherwise.
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/** This method makes the device available to the Optimizely web editor.
 *
 * It is a programmatic shortcut for developers to place the device in edit mode, rather than
 * opening the app through the custom URL accessible in the Optimizely web editor.
 *
 * @warning We recommend that this call be wrapped in an `#ifdef DEBUG` flag.  It should be removed from test and production builds.
 * @warning Should be called before `+startWithProjectId:launchOptions:`.
 */
+ (void)enableEditor;

/** This method deactivates the swizzling functionality of the SDK required for use of the visual editor.
 *
 * @warning Should be called before `+startWithProjectId:launchOptions:`.
 */
+ (void)disableSwizzle;

/** @name Events and Goal Tracking */

/** This method immediately starts a network request that sends tracked events
 *  to Optimizely and fetches the newest experiment data file.
 *
 * This is the same as calling dispatchEvents followed by fetchNewDataFile.
 *
 * Events are automatically flushed at regular intervals by the SDK. This method exists
 * so that the Optimizely SDK can piggy-back on an already activated radio. This can save
 * battery by reducing the number of times the radio is turned on/off.
 *
 * See dispatchInterval to change the frequency of auto dispatch (events and new data file).
 */
+ (void)dispatch;

/** Manually send events to Optimizely.
 */
+ (void)dispatchEvents;

/** Manually fetch new data file from Optimizely.
 */
+ (void)fetchNewDataFile;

/** This method informs Optimizely that a custom goal with key `description` occured.
 *
 * @param description A unique string identifying the custom goal
 * @see +dispatch
 */
+ (void)trackEvent:(NSString *)description;

/** This method registers a callback method for when a given variable is changed.
 *
 * @param key The Optimizely key associated with the variable you want to watch
 * @param callback The callback method that will be invoked whenever the variable is changed. It takes in two parameters, the first being the key of the changed variable and the second is the variable's new value
 */
+ (void)registerCallbackForVariableWithKey:(OptimizelyVariableKey *)key callback:(void (^)(NSString *, id))callback;

#pragma mark - Variable getters
/** @name Live Variables */

/** Returns the NSString idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (NSString *)stringForKey:(OptimizelyVariableKey *)key;

/** Returns the UIColor idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (UIColor *)colorForKey:(OptimizelyVariableKey *)key;

/** Returns the NSNumber idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (NSNumber *)numberForKey:(OptimizelyVariableKey *)key;

/** Returns the CGPoint idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (CGPoint)pointForKey:(OptimizelyVariableKey *)key;

/** Returns the CGSize idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (CGSize)sizeForKey:(OptimizelyVariableKey *)key;

/** Returns the CGRect idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (CGRect)rectForKey:(OptimizelyVariableKey *)key;

/** Returns the BOOL idenitified by the provided key.
 *
 * @param key A key uniquely identifying a live variable
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
+ (BOOL)boolForKey:(OptimizelyVariableKey *)key;

#pragma mark - Code Blocks
/** @name Code Blocks */

/** This method allows you to define a code block based experiment with one alternative.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
             defaultBlock:(void (^)(void))defaultBlock;

/** This method allows you to define a code block based experiment with two alternatives.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param blockTwo Block corresponding to the second block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
                 blockTwo:(void (^)(void))blockTwo
             defaultBlock:(void (^)(void))defaultBlock;

/** This method allows you to define a code block based experiment with three alternatives.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param blockTwo Block corresponding to the second block name in the provided OptimizelyCodeBlocksKey
 * @param blockThree Block corresponding to the third block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
                 blockTwo:(void (^)(void))blockTwo
               blockThree:(void (^)(void))blockThree
             defaultBlock:(void (^)(void))defaultBlock;

/** This method allows you to define a code block based experiment with four alternatives.
 *
 * @param codeBlocksKey The OptimizelyCodeBlocksKey associated with this code blocks experiment
 * @param blockOne Block corresponding to the first block name in the provided OptimizelyCodeBlocksKey
 * @param blockTwo Block corresponding to the second block name in the provided OptimizelyCodeBlocksKey
 * @param blockThree Block corresponding to the third block name in the provided OptimizelyCodeBlocksKey
 * @param blockFour Block corresponding to the fourth block name in the provided OptimizelyCodeBlocksKey
 * @param defaultBlock This block will be executed if no active experiment involves this code block key.
 */
+ (void)codeBlocksWithKey:(OptimizelyCodeBlocksKey *)codeBlocksKey
                 blockOne:(void (^)(void))blockOne
                 blockTwo:(void (^)(void))blockTwo
               blockThree:(void (^)(void))blockThree
                blockFour:(void (^)(void))blockFour
             defaultBlock:(void (^)(void))defaultBlock;

/* Should not be called directly.  These methods register a key with the editor in edit mode. */
+ (void)preregisterVariableKey:(OptimizelyVariableKey *)key;
+ (void)preregisterBlockKey:(OptimizelyCodeBlocksKey *)key;

#pragma mark - Properties
/** @name Properties */

/** Provides an array of all the experiments currently active for the user to the variation
 *  they're bucketed into for that experiment. The metadata includes experiment Id, variation Id,
 *  experiment description and variation description.
 */
@property (nonatomic, strong, readonly) NSArray *activeExperiments;


/** The The current Optimizely project id. */
@property (readonly, strong) NSString *projectId;

/** The current SDK version. */
@property (readonly, strong) NSString *sdkVersion;

/** A unique identifier for the current user.
 * If a custom identifier is provided, it must be set prior to calling `+startWithProjectId:launchOptions:`.
 * Defaults to the device UUIDString if no identifier is provided.
 */
@property (nonatomic, strong) NSString *userId;

/** When set to true, provides verbose logging details that may be useful for debugging.
 */
@property (nonatomic) BOOL verboseLogging;

/**The frequency (in seconds) at which events are sent to Optimizley and the experiment
 * data file is fetched from server. Defaults to 2 minutes.
 *
 * Setting this to zero or negative value will disable automatic sending
 * of events and you will need to send events manually using `-dispatch`.
 */
@property (nonatomic) NSTimeInterval dispatchInterval;

/** NSTimeInterval which controls timeout for first download of
 * config file.
 */
@property (nonatomic) NSTimeInterval networkTimeout;

/**
 * Indicates whether experiments should be reloaded on foregrounding.  Defaults to false.
 *
 * @discussion By default, Optimizely ensures that a user will never have an inconsistent
 * experience as a result of an experiment activation.  In practice, this means that once a view becomes
 * visible, a variable is read, or a code block is executed, its value/appearance will not change for the
 * duration of the app run (applicationDidFinishLaunching:withOptions: is called).
 *
 * When shouldReloadExperimentsOnForegrounding is set to true, experiments may be activated when
 * an application is foregrounded, regardless of whether it is a fresh launch.  Developers should be aware that Optimizely
 * values may change throughout the duration of the app run and that this may have unintended consequences on statistical validity.
 * We recommend targeting your experiments such that all users will have a consistent value for shouldReloadExperimentsOnForegrounding.
 */
@property (assign) BOOL shouldReloadExperimentsOnForegrounding;

#pragma mark - Integrations

/** @name Integrations*/
/**
 *  This activates the Optimizely SDK's Mixpanel integration. This behaves identically to web,
 *  which you can read about [here](https://help.optimizely.com/hc/en-us/articles/200040025-Integrating-Optimizely-with-Mixpanel),
 *  except that it cannot (yet) be activated through the website.
 *  @warning This currently *must* be called after `startOptimizelyWithAPIToken: launchOptions:` returns!
 */
+ (void)activateMixpanelIntegration;

#pragma mark - Variable getters
/** @name Deprecated Methods */

/* These methods will be removed in a future release */

/**  @deprecated.  Use `+trackEvent`.
 *
 * This method informs the server that a custom goal with key `description` occured.
 *
 * @param description The string uniquely identifying the custom goal you want to track
 * @see -dispatch
 */
- (void)trackEvent:(NSString *)description __attribute((deprecated("Use [Optimizely trackEvent:]")));

/**  @deprecated.  Use `+stringForKey:`.
 *
 * This method registers an NSString so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (NSString *)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue __attribute((deprecated("Use [Optimizely stringForKey:]")));

/**  @deprecated.  Use `+colorForKey:`.
 *
 * This method registers an UIColor so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (UIColor *)colorForKey:(NSString *)key defaultValue:(UIColor *)defaultValue  __attribute((deprecated("Use [Optimizely colorForKey:]")));

/**  @deprecated.  Use `+numberForKey:`.
 *
 * This method registers an NSNumber so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (NSNumber *)numberForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue  __attribute((deprecated("Use [Optimizely numberForKey:]")));

/**  @deprecated.  Use `+pointForKey:`.
 *
 * This method registers an CGPoint so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (CGPoint)pointForKey:(NSString *)key defaultValue:(CGPoint)defaultValue  __attribute((deprecated("Use [Optimizely pointForKey:]")));

/**  @deprecated.  Use `+sizeForKey:`.
 *
 * This method registers an CGSize so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (CGSize)sizeForKey:(NSString *)key defaultValue:(CGSize)defaultValue  __attribute((deprecated("Use [Optimizely sizeForKey:]")));

/**  @deprecated.  Use `+rectForKey:`.
 *
 * This method registers an CGRect so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (CGRect)rectForKey:(NSString *)key defaultValue:(CGRect)defaultValue __attribute((deprecated("Use [Optimizely rectForKey:]")));

/**  @deprecated.  Use `+boolForKey:`.
 *
 * This method registers a BOOL so that it can be changed via the Optimizely web editor
 *
 * @param key A key uniquely defining the variable
 * @param defaultValue The value this variable should take on in the absence of an
 * experimental change
 * @return The value of this variable in the active experiment (default if no active experiment)
 */
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue __attribute((deprecated("Use [Optimizely boolForKey:]")));

/**  @deprecated.  Use `+codeBlocksWithKey: blockOne:...`.
 *
 * This method allows you to define a code block based experiment
 *
 * @param codeTestKey A unique key that describes this test
 * @param blocks A dictionary that maps descriptive NSString keys to (void (^)(void)) blocks for each
 * variation of this test.
 * @param defaultBlock This block will be executed if no active experiment involves this code test.
 */
- (void)codeTest:(NSString *)codeTestKey
      withBlocks:(NSDictionary *)blocks
    defaultBlock:(void (^)(void))defaultBlock __attribute((deprecated("Use [Optimizely codeTestWithKey: blockOne:...]")));

@end
