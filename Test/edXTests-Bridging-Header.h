//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "NSString+TestExamples.h"

#import "OEXFileUtility+TestAdditions.h"
#import "OEXMockCredentialStorage.h"
#import "OEXMockUserDefaults.h"
#import "NSString+OEXFormatting.h"
#import "OEXUserDetails+OEXTestDataFactory.h"

// This is #defined as a command line preprocessor argument
// so it can contain environment variables that get resolved
// this exposes it to swift, which doesn't have preprocessor defines
#define SNAPSHOT_TEST_DIR FB_REFERENCE_IMAGE_DIR
