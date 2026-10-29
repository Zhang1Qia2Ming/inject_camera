#!/bin/sh
# Read /dev/ttyACM0 and overwrite the log every time this script starts.
DEV="${1:-/dev/ttyACM0}"
LOG="${2:-/tmp/ps_acm.log}"

if [ ! -c "$DEV" ]; then
	echo "no such device: $DEV" >&2
	exit 1
fi

stty -F "$DEV" 115200 cs8 -cstopb -parenb -ixon raw -echo clocal -crtscts
echo "logging $DEV -> $LOG"
exec cat "$DEV" > "$LOG"
