fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### update_all_metadata

```sh
[bundle exec] fastlane update_all_metadata
```

Upload metadata to both App Store and Google Play

----


## iOS

### ios update_metadata

```sh
[bundle exec] fastlane ios update_metadata
```

Upload localized App Store metadata (name, subtitle, description, keywords, etc.)

----


## Android

### android update_metadata

```sh
[bundle exec] fastlane android update_metadata
```

Upload localized Google Play Store metadata (title, descriptions, changelogs, etc.)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
