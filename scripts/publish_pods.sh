
#!/bin/bash
set -o pipefail
set -e

ROOT_PATH=`dirname "${0}"`/..
source "$ROOT_PATH/scripts/config.sh"

cd "$ROOT_PATH"

bundle exec pod trunk push Airship.podspec
bundle exec pod trunk push AirshipExtensions.podspec

cd -
