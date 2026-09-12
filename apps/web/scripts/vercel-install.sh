#!/usr/bin/env sh
# Vercel "Install Command" for emotely-web. The build image has no Dart, so
# this fetches the pinned SDK, verifies its checksum, and resolves packages.
# Local development uses the SDK on PATH; see README.md.
set -eu

DART_VERSION="3.13.3"
DART_SHA256="549c182cffbdc6864df7509c16fec646c73fe6cb8a18c2cb572db1292f300cd7"
DART_ZIP="dartsdk-linux-x64-release.zip"
DART_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/${DART_ZIP}"

sdk_dir="$PWD/.dart-sdk"
if [ ! -x "$sdk_dir/bin/dart" ] || ! "$sdk_dir/bin/dart" --version 2>&1 | grep -q "$DART_VERSION"; then
  echo "vercel-install: fetching Dart $DART_VERSION"
  rm -rf "$sdk_dir"
  curl -fsSL -o "/tmp/$DART_ZIP" "$DART_URL"
  echo "$DART_SHA256  /tmp/$DART_ZIP" | sha256sum -c -
  unzip -q "/tmp/$DART_ZIP" -d /tmp/dart-sdk-unpack
  mv /tmp/dart-sdk-unpack/dart-sdk "$sdk_dir"
  rm -rf "/tmp/$DART_ZIP" /tmp/dart-sdk-unpack
fi
export PATH="$sdk_dir/bin:$HOME/.pub-cache/bin:$PATH"

dart --version
dart pub get
# The CLI version tracks the jaspr dependency in pubspec.yaml.
dart pub global activate jaspr_cli 0.23.4
