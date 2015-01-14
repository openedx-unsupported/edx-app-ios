//
//  OptimizelyKey.h
//  Optimizely
//
//  Created by Optimizely Engineering on 5/13/14.
//  Copyright (c) 2014 Optimizely Engineering. All rights reserved.
//

/** This class defines a key that can be used to retrieve Optimizely live variables.
 *
 *
 *  The recommended method of creating an OptimizelyVariableKey is through the appropriate
 *  macro:
 *
 *  OptimizelyVariableKeyForString for NSString variables
 *
 *  OptimizelyVariableKeyForColor for UIColor variables
 *
 *  OptimizelyVariableKeyForNumber for NSNumber variables
 *
 *  OptimizelyVariableKeyForPoint for CGPoint variables
 *
 *  OptimizelyVariableKeyForSize for CGSize variables
 *
 *  OptimizelyVariableKeyForRect for CGRect variables
 *
 *  OptimizelyVariableKeyForBool for BOOL variables
 *
 *
 *  For example:
 *
 *  OptimizelyVariableKeyForString(myStringVariable, @"My default string");
 *
 *  Defines an OptimizelyVariableKey called myStringVariable for an NSString variable with
 *  a default value of @"My default string".
 *
 *  You may then read your variable as:
 *
 *  NSString *myString = [Optimizely stringForKey:myStringVariable];
 *
 */
@interface OptimizelyVariableKey : NSObject
/** A unique name for this OptimizelyVariableKey */
@property (readonly) NSString *key;
/** The value that will be returned if no active experiment involves this variable. */
@property (readonly) id defaultValue;
/** The type of this key */
@property (readonly) NSString *type;

// Can be used to define an OptimizelyVariableKey inline
// In general, these should not be called directly -- we recommend using OptimizelyVariableKeyForString macro
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultNSString:(NSString *)defaultValue;
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultUIColor:(UIColor *)defaultValue;
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultNSNumber:(NSNumber *)defaultValue;
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultCGPoint:(CGPoint)defaultValue;
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultCGSize:(CGSize)defaultValue;
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultCGRect:(CGRect)defaultValue;
+ (OptimizelyVariableKey *)optimizelyKeyWithKey:(NSString *)key defaultBOOL:(BOOL)defaultValue;
- (BOOL)isEqualToOptimizelyVariableKey:(OptimizelyVariableKey *)key;
@end

#define _OptimizelyVariableKey(key, type, defVal) OptimizelyVariableKey * key; \
    static void __attribute__((constructor)) initialize_ ## key() { \
        @autoreleasepool { \
            key = [OptimizelyVariableKey optimizelyKeyWithKey:@#key default ## type:defVal]; \
            [Optimizely preregisterVariableKey:key]; \
        } \
    }

/** Defines an OptimizelyKey for variables of type NSString
 * @param key The name of this OptimizelyKey.
 * @param defString The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForString(key, defString) _OptimizelyVariableKey(key, NSString, defString)
/** Defines an OptimizelyKey for variables of type UIColor
 * @param key The name of this OptimizelyKey.
 * @param defColor The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForColor(key, defColor) _OptimizelyVariableKey(key, UIColor, defColor)
/** Defines an OptimizelyKey for variables of type NSNumber
 * @param key The name of this OptimizelyKey.
 * @param defNumber The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForNumber(key, defNumber) _OptimizelyVariableKey(key, NSNumber, defNumber)
/** Defines an OptimizelyKey for variables of type CGPoint
 * @param key The name of this OptimizelyKey.
 * @param defPoint The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForPoint(key, defPoint) _OptimizelyVariableKey(key, CGPoint, defPoint)
/** Defines an OptimizelyKey for variables of type CGSize
 * @param key The name of this OptimizelyKey.
 * @param defSize The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForSize(key, defSize) _OptimizelyVariableKey(key, CGSize, defSize)
/** Defines an OptimizelyKey for variables of type CGRect
 * @param key The name of this OptimizelyKey.
 * @param defRect The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForRect(key, defRect) _OptimizelyVariableKey(key, CGRect, defRect)
/** Defines an OptimizelyKey for variables of type BOOL
 * @param key The name of this OptimizelyKey.
 * @param defBool The value that will be returned if no active experiment involves this variable.
 */
#define OptimizelyVariableKeyForBool(key, defBool) _OptimizelyVariableKey(key, BOOL, defBool)
