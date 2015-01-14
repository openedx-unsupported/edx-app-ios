

/** This class defines a key that can be used to define an Optimizely code blocks experiment.
 *
 * The recommended method of creating an OptimizelyCodeBlocksKey is through the OptimizelyCodeBlocksKeyWithBlockNames
 * macro:
 *
 * OptimizelyCodeBlocksKeyWithBlockNames(myCodeBlocksKey, @"myFirstBlock", @"mySecondBlock")
 *
 * This will define an OptimizelyCodeBlocksKey called myCodeBlocksKey with a blockOne name of @"myFirstBlock" and blockTwo name of @"mySecondBlock".
 *
 * You can then implement the code blocks experiment with [Optimizely codeBlocksWithKey: blockOne: blockTwo: ... defaultBlock:]
 *
 *
 * The number of block names should match the number of non-default blocks in your code blocks experiment.
 *
 * If the number of block names is less than the number of blocks in your experiment, Optimizely will assign a default name
 * to the code block once it is executed.
 *
 * If the number of block names is fewer than the number of blocks in your experiment, Optimizely will ignore the additional names.
 *
 */
@interface OptimizelyCodeBlocksKey : NSObject
/** A unique name for this OptimizelyCodeBlocksKey */
@property (readonly) NSString *key;
/** Array of associated block names for this code blocks experiment */
@property (readonly) NSArray *blockNames;

// Can be used to define an OptimizelyCodeBlocksKey inline
// In general, this should not be called directly -- we recommend using OptimizelyCodeBlocksKeyWithBlockNames macro
+ (OptimizelyCodeBlocksKey *)optimizelyCodeBlocksKey:(NSString *)key
                                          blockNames:(NSArray *)blockNames;

@end

// Defines an OptimizelyCodeBlocksKey for a code blocks experiment.
#define OptimizelyCodeBlocksKeyWithBlockNames(key, ...) OptimizelyCodeBlocksKey * key; \
    static void __attribute__((constructor)) initialize_ ## key() { \
        @autoreleasepool { \
            key = [OptimizelyCodeBlocksKey optimizelyCodeBlocksKey:@#key blockNames:[NSArray arrayWithObjects:__VA_ARGS__, nil]]; \
            [Optimizely preregisterBlockKey:key]; \
        } \
    }
