if ./gradlew -q testLTRCurrentOS | xcpretty -c; then
  echo "Gradle task succeeded" >&2
else
  echo "Gradle task failed" >&2
fi