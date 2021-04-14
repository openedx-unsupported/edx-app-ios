#! /bin/sh

# AppboyKitLibrary
rm -f "$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/libAppboyKitLibrary.a"
rm -f "$BUILT_PRODUCTS_DIR/$PLUGINS_FOLDER_PATH/libAppboyKitLibrary.a"

# AppboyPushStory
rm -rf "$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH/AppboyPushStory.framework"
find "$BUILT_PRODUCTS_DIR/$PLUGINS_FOLDER_PATH/" -name AppboyPushStory -exec rm {} \;
