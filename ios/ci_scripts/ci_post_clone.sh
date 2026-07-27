#!/bin/sh

# Xcode Cloud : execute apres le clone du depot, avant xcodebuild.
#
# Sans ce script, l'archive echoue avec :
#   Could not resolve package dependencies: the package at
#   '.../ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage'
#   cannot be accessed (doesn't exist in file system)
#
# Le pbxproj reference ce package Swift local, mais ios/Flutter/ephemeral/ est
# gitignore : c'est Flutter qui le genere. Il faut donc installer Flutter et le
# laisser generer avant que xcodebuild ne tente de resoudre les dependances.

set -e

# Le repertoire d'execution par defaut de ce script est ci_scripts/.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Version epinglee sur celle utilisee en local. Laisser "stable" ferait deriver
# la version de Flutter du CI par rapport a celle qui a servi aux tests, et une
# archive TestFlight serait alors construite avec un SDK jamais valide ici.
FLUTTER_VERSION=3.44.8
git clone https://github.com/flutter/flutter.git \
  --depth 1 -b "$FLUTTER_VERSION" "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter precache --ios
flutter pub get

# Genere ios/Flutter/ephemeral/ (dont FlutterGeneratedPluginSwiftPackage) et
# aligne son deployment target sur IPHONEOS_DEPLOYMENT_TARGET. Sans cette etape
# il reste a 13.0, ce qui casse la resolution de Firebase (iOS 15 minimum).
flutter build ios --config-only --release --no-codesign

# Le projet utilise aussi CocoaPods (ios/Podfile.lock est versionne).
if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

cd ios
pod install

exit 0
