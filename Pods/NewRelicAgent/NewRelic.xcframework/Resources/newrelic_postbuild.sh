#!/bin/sh


#
# Shell script to upload an iOS build's debug symbols to New Relic.
#
# usage:
# This script needs to be invoked during an Xcode build
#
# 1. In Xcode, select your project in the navigator, then click on the application target.
# 2. Select the Build Phases tab in the settings editor.
# 3. Click the + icon above Target Dependencies and choose New Run Script Build Phase.
# 4. Add the following two lines of code to the new phase,
#     removing the '#' at the start of each line and pasting in the
#     application token from your New Relic dashboard for the app in question.
#
#SCRIPT=`/usr/bin/find "${SRCROOT}" -name newrelic_postbuild.sh | head -n 1`
#/bin/sh "${SCRIPT}" "PUT_NEW_RELIC_APP_TOKEN_HERE"
#
# Optional:
# DSYM_UPLOAD_URL - define this environment variable to override the New Relic server hostname
# let ENABLE_SIMULATOR_DSYM_UPLOAD=1 # Uncomment to allow dSYM upload when building to simulator


echo "New Relic: Starting dSYM upload script"

not_in_xcode_env() {
    echo "New Relic: $0 must be run from an XCode build"
    exit -2
}

bitcode_enabled() {
    echo "New Relic: Build is Bitcode enabled. No dSYM has been uploaded. Bitcode enabled apps require dSYM files to be downloaded from iTunes Connect.
For more information please review https://docs.newrelic.com/docs/mobile-monitoring/new-relic-mobile-ios/install-configure/retrieve-upload-dsyms"
    exit 0
}

upload_dsym_to_new_relic() {
    echo "executing upload_dsym_to_new_relic"

    let RETRY_LIMIT=3
    let RETRY_COUNT=0

    while [ "$RETRY_COUNT" -lt "$RETRY_LIMIT" ]
    do
        let RETRY_COUNT=$RETRY_COUNT+1
        SERVER_RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null -F dsym=@"${DSYM_ARCHIVE_PATH}" -H "x-app-license-key: ${API_KEY}" "${DSYM_UPLOAD_URL}/symbol")
        if [ "${SERVER_RESPONSE}" -eq "201"  ]; then
            echo "new relic: successfully uploaded dsym files"
            DSYM_UPLOAD_STATUS="success"
            return 0
        else
            echo "new relic: error \"${SERVER_RESPONSE}\" while uploading \"${DSYM_ARCHIVE_PATH}\" to \"${DSYM_ARCHIVE_PATH}\""
        fi
    done
    return -1
}

upload_map_file_to_new_relic() {
    echo "executing upload_map_file_to_new_relic"

    let RETRY_LIMIT=3
    let RETRY_COUNT=0

    while [ "$RETRY_COUNT" -lt "$RETRY_LIMIT" ]
    do
        let RETRY_COUNT=$RETRY_COUNT+1
        echo "New Relic: map file upload attempt #${RETRY_COUNT} (of ${RETRY_LIMIT})"

        MAP_SCRIPT=`/usr/bin/find "${SRCROOT}" -name generateMap.py | head -n 1`

        if [ -z ${MAP_SCRIPT} ]; then
            echo "unable to find generateMap.py"
            return -1
        fi

        echo "Using URL: ${DSYM_UPLOAD_URL}"
        SERVER_RESPONSE=$(python "${MAP_SCRIPT}" "${DSYM_ARCHIVE_PATH}" ${API_KEY})

        if [ "${SERVER_RESPONSE}" == "201" ]; then
            echo "New Relic: Successfully uploaded map files"
            return 0
        fi
    done
    return -1
}

parse_region_aware() {
    echo "New Relic: parsing region from API key: ${API_KEY}"
    REGION=`echo ${API_KEY} | grep -oE "^.*?x" | head -1`
    if [ ! -z ${REGION} ]; then
        echo "New Relic: region ${REGION/%x}"
        DSYM_UPLOAD_URL="https://mobile-symbol-upload.${REGION/%x}.nr-data.net"
    fi

}

upload_symbols_to_new_relic() {
    if [ ! -f "${DSYM_ARCHIVE_PATH}" ]; then
        echo "New Relic: Failed to archive \"${DSYM_SRC}\" to \"${DSYM_ARCHIVE_PATH}\""
        exit -3
    fi


    echo "uploading map to new relic"
    upload_map_file_to_new_relic

    if [ $? -ne 0 ]; then
        upload_dsym_to_new_relic
        if [ $? -ne 0 ]; then
            /bin/rm -f "${DSYM_ARCHIVE_PATH}"
            exit -1
        fi
    fi
    # Loop until upload success or retry limit is exceeded

    /bin/rm -f "${DSYM_ARCHIVE_PATH}"
}



# Determine if this script should be ran
if [ ! $1 ]; then
    echo "New Relic: usage: $0 <NEW_RELIC_APP_TOKEN>"
    exit -1
fi

API_KEY=$1

if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" -a ! "$ENABLE_SIMULATOR_DSYM_UPLOAD" ]; then
    echo "New Relic: Skipping automatic upload of simulator build symbols"
    exit 0
fi

if [ ! "$DWARF_DSYM_FOLDER_PATH" -o ! "$DWARF_DSYM_FILE_NAME" -o ! "$INFOPLIST_FILE" ]; then
    not_in_xcode_env
fi

if [ "$ENABLE_BITCODE" == "YES" ]; then
    bitcode_enabled
fi

if [ ! "${DSYM_UPLOAD_URL}" ]; then
    DSYM_UPLOAD_URL="https://mobile-symbol-upload.newrelic.com"
fi

parse_region_aware

SAVEIFS=$IFS

IFS=$'\n'

# Gather dSYMs and upload
for dSYM in `find ${DWARF_DSYM_FOLDER_PATH} | grep .dSYM$`;
do
    echo "New Relic: Processing $dSYM"

    # Add pid/timestamp to tmp file name
    DSYM_TIMESTAMP=`date +%s`

    DSYM_ARCHIVE_PATH="${TEMP_FILES_DIR}/${dSYM##*/}-${DSYM_TIMESTAMP}.zip"

    echo "New Relic: Archiving ${dSYM} to ${DSYM_ARCHIVE_PATH}"
    echo "New Relic: /usr/bin/zip --recurse-paths --quiet "${DSYM_ARCHIVE_PATH}" "${dSYM}""
    /usr/bin/zip --recurse-paths --quiet "${DSYM_ARCHIVE_PATH}" "${dSYM}"

    # Convert to function and call in background
    echo "New Relic: Uploading dSYMs to New Relic"
    echo "New Relic: This script will fail silently if dsym fails to upload."
    echo "New Relic: For troubleshooting, see upload_dsym_results file in project root folder"
    upload_symbols_to_new_relic > upload_dsym_results 2>&1 &

done

# Revert IFS
IFS=$SAVEIFS

exit 0
