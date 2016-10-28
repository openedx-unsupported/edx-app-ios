# Pre-requisites

- [Cocoapods](https://guides.cocoapods.org/using/getting-started.html)

# Getting Started

1. Fork this repository and edit `OEXRemoteConfig.podspec`, `config/local.yml`, and `config/config.yml` to match your project
2. Run this command to validate your changes: 
```
$ pod spec lint OEXRemoteConfig.podspec --verbose --private
```
3. Update your Podfile (or the environment variable mentioned in your Podfile) to pull from your new custom cocoapod URL.

# FAQ

- [Official guide to making a cocoapod](https://guides.cocoapods.org/making/making-a-cocoapod.html)
