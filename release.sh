#!/bin/bash
rm -rf build
xcodebuild -configuration Beta
cd build/Beta
new_version=`cat System\ Scope.app/Contents/Info.plist |grep -A 1 CFBundleVersion |tail -n 1 |sed -e "s/.*<string>//" |sed -e "s/<\/string>//"`
echo -n "About to release System Scope v$new_version. Cool? [y/n] "
read confirm
if [ "$confirm" != "y" ]; then
  echo "alright nevermind then."
  exit 1
fi
zip -r SystemScope$new_version.zip System\ Scope.app
../../sign.sh SystemScope$new_version.zip ../../RemoteConsoleClient/dsa_priv.pem
scp SystemScope$new_version.zip SystemScope$new_version.zip.sig grapefruitsystems.com:/var/www/payme/shared/public/downloads/
