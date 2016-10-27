# Pre-requisites

- [Cocoapods](https://guides.cocoapods.org/using/getting-started.html)

# Release

When you're ready to release a new version of this pod, increment the version in RemoteConfig.podspec and add a tag with the version name. 

Here are a few useful commands for tagging these releases:
```
# Create a new tag
$ git tag -a 0.0.1 -m "Creating the first custom version"

# Review tags
$ git describe --tags 

# Save a new tag
$ git push origin --tags # update github with the list of local tags
```

# Testing 

# Run this command to validate changes to RemoteConfig.podspec
```
$ pod spec lint RemoteConfig.podspec --verbose --private
```
