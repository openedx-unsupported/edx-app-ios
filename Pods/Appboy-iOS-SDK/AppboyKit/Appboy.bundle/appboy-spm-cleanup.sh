#! /bin/sh

# AppboyKitLibrary
find "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}" -name libAppboyKitLibrary.a -follow -exec rm {} \;

# AppboyPushStory
find "${TARGET_BUILD_DIR}/${FULL_PRODUCT_NAME}" -name "AppboyPushStory.framework" -follow -exec rm -r {} \;

