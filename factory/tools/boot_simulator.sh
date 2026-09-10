#!/usr/bin/env bash
# Boot one simulator and prove it actually booted.
#
#   factory/tools/boot_simulator.sh <udid>
#
# Two things this exists for:
#
# 1. `simctl bootstatus -b` is not a reliable success signal. It exits 0
#    regardless, and its terminal line reads "Status=4294967295, isTerminal=YES"
#    on a perfectly good boot as well as a failed one -- verified on both a
#    working local device and a CI runner where the device never came up. The
#    only trustworthy answer is whether simctl then reports the device Booted,
#    so that is what gets checked. Without this the step carried on and
#    xcodebuild failed with "Unable to find a device matching the provided
#    destination specifier", which reads like a bad UDID rather than a dead
#    simulator.
#
# 2. Booting several simulators on one runner is what makes that happen. Each
#    step shuts the others down first, so only one device is ever running.
set -euo pipefail

udid="${1:?usage: boot_simulator.sh <udid>}"

xcrun simctl shutdown all >/dev/null 2>&1 || true
xcrun simctl bootstatus "$udid" -b || true

if ! xcrun simctl list devices | grep -q "($udid) (Booted)"; then
  echo "::error::simulator $udid never reached Booted. simctl reports:"
  xcrun simctl list devices | grep -F "$udid" || echo "  (no such device)"
  exit 1
fi
echo "booted $(xcrun simctl list devices | grep -F "$udid" | sed -E 's/^ *(.*) \([0-9A-Fa-f-]{36}\).*/\1/')"
