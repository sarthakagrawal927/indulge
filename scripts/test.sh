#!/bin/zsh

set -euo pipefail

project_root="${0:A:h:h}"
test_destination="${INDULGE_TEST_DESTINATION:-}"

cd "$project_root"
xcodegen generate

if [[ -z "$test_destination" ]]; then
  simulator_id="$(
    xcrun simctl list devices available -j | python3 -c '
import json
import sys

devices = json.load(sys.stdin).get("devices", {})
candidates = []
for runtime, entries in devices.items():
    for device in entries:
        if (
            device.get("isAvailable")
            and device.get("deviceTypeIdentifier")
            == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
        ):
            candidates.append((runtime, device["udid"]))
if candidates:
    print(sorted(candidates)[0][1])
'
  )"
  test_destination="platform=iOS Simulator,id=${simulator_id}"
fi

xcodebuild \
  -project Indulge.xcodeproj \
  -scheme Indulge \
  -sdk iphonesimulator \
  -destination "$test_destination" \
  test
