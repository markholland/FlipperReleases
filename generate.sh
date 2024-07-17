#!/usr/bin/env bash

# Cleanup
rm -rf flipper
rm -f flipper.tar.gz

# Get latest version published by Meta
REPO="facebook/flipper"
LATEST_TAG=$(curl -L https://github.com/facebook/flipper/releases/latest  | grep "facebook/flipper/releases/tag" -m 1 | sed "s/.*releases\/tag\///;s/\".*//")
TARBALL_URL="https://github.com/facebook/flipper/archive/refs/tags/$LATEST_TAG.tar.gz"

SOURCE_TAR="flipper.tar.gz"
curl -L -o $SOURCE_TAR $TARBALL_URL

mkdir -p flipper
tar -xf $SOURCE_TAR -C flipper --strip-components=1

# Apply patches
pushd flipper
git init && git add . && git commit -m "Original source"
git remote add flipperUpstream https://github.com/facebook/flipper
git fetch flipperUpstream pull/3553/head:universalBuild

pushd desktop
if grep -Fxq "@electron/universal" package.json
then
    echo "electron/universal is present in the resolutions"
else
    echo "Patching electron/universal in the resolutions"
    resolutions='"resolutions": {'
    electron_resolution='"@electron/universal": "2.0.0",'
    sed -i '' "/$resolutions/ a\\
    $electron_resolution
    " package.json
fi

# To fix some errors shows in CI, suggesting that repository key should be present in package.json
build_info='"homepage":'
repository_info='"repository": "facebook/flipper",'

sed -i '' "/$build_info/ a\\
  $repository_info
" package.json

yarn install
yarn build --mac
