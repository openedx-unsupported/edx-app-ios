#!/bin/bash

# This script strips unused architectures from any frameworks embedded in an
# app bundle. It should be called from an Xcode project as a post-build step.

if [ -z "${TARGET_BUILD_DIR}" ]; then
  echo "This script should be invoked from an Xcode project."
  exit 1
fi

app_dir="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

framework_dirs=($(find "${app_dir}" -type d -name '*.framework'))
for framework_dir in "${framework_dirs[@]}"; do
  framework_name=$(defaults read "${framework_dir}/Info.plist" CFBundleExecutable)
  framework_path="${framework_dir}/${framework_name}"

  echo "Removing unused architectures from framework: ${framework_name}"

  slice_paths=()
  for arch in ${ARCHS}; do
    slice_path="${framework_path}_${arch}"
    lipo "${framework_path}" -extract "${arch}" -output "${slice_path}"
    slice_paths+=("${slice_path}")
  done

  lipo "${slice_paths[@]}" -create -output "${framework_path}_thinned"
  rm -f "${slice_paths[@]}"

  rm -f "${framework_path}"
  mv "${framework_path}_thinned" "${framework_path}"
done
