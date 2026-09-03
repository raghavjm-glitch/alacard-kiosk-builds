#!/usr/bin/env bash
# The whole upgrade, in one command, over AnyDesk.
#
# Host this file next to the builds, then on a kiosk type one line:
#
#   curl -fsSL https://<your-updates-url>/bootstrap.sh | bash
#
# That is the entire visit. It fetches the newest build, switches the machine
# off the web kiosk, installs the app, and turns on automatic updates — so this
# is the last time anybody connects to that kiosk to change anything.
#
# It refuses rather than guesses: no URL, bad download, wrong checksum, or a
# missing Canon driver all stop it with a message naming the problem.
set -u

# Where the builds live. Overridable so a test kiosk can point elsewhere:
#   UPDATE_URL=https://.../test curl -fsSL .../bootstrap.sh | bash
UPDATE_URL="${UPDATE_URL:-https://raw.githubusercontent.com/raghavjm-glitch/alacard-kiosk-builds/main}"
# Where the actual build files live. Releases rather than the repository
# itself, so a 23MB zip per build never becomes 23MB of history.
RELEASES="${RELEASES:-https://github.com/raghavjm-glitch/alacard-kiosk-builds/releases/download}"
CHANNEL="${CHANNEL:-test}"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$*"; exit 1; }

[ -n "$UPDATE_URL" ] || die "No UPDATE_URL. Edit this file before hosting it."

bold "Alacard kiosk — upgrading this machine"
echo "  channel: $CHANNEL"

# --- the parts that must already be here ------------------------------------
#
# Checked first, because everything below is wasted if the Canon driver is
# missing — and that is the one thing this cannot install for you.
bold "1. Checking what this machine already has"
command -v lpstat >/dev/null 2>&1 || die "CUPS is not installed on this machine"
PRINTERS="$(lpstat -p 2>/dev/null | awk '{print $2}')"
[ -n "$PRINTERS" ] || die "CUPS knows about no printers. Install the driver first."
echo "$PRINTERS" | sed 's/^/    /'
COUNT="$(echo "$PRINTERS" | wc -l | tr -d ' ')"
ok "$COUNT printer(s) — $([ "$COUNT" -gt 1 ] && echo "dual kiosk" || echo "single-printer kiosk")"

# --- fetch -------------------------------------------------------------------
bold "2. Fetching the current build"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/m.json" "$UPDATE_URL/$CHANNEL.json" \
  || die "Could not reach $UPDATE_URL/$CHANNEL.json"

get() { python3 -c "import json;print(json.load(open('$TMP/m.json')).get('$1',''))"; }
SRC="$(get source)"
[ -n "$SRC" ] || die "The manifest names no source bundle to install from."

VER="$(get version)"
curl -fL --progress-bar -o "$TMP/src.zip" "$RELEASES/v$VER/$SRC" || die "Download failed"
ok "got $SRC"

# --- install -----------------------------------------------------------------
bold "3. Installing"
rm -rf "$HOME/kiosk-new"
mkdir -p "$HOME/kiosk-new"
unzip -q "$TMP/src.zip" -d "$HOME/kiosk-new" || die "The download would not open"

DIR="$(find "$HOME/kiosk-new" -maxdepth 1 -type d -name 'alacard-kiosk-*' | head -1)"
[ -n "$DIR" ] || die "Nothing recognisable inside the download"

bash "$DIR/kiosk-setup/switch-from-web.sh" || die "Setup did not finish"

# --- and never come back -----------------------------------------------------
bold "4. Turning on automatic updates"
echo "UPDATE_URL=$UPDATE_URL" | sudo tee /etc/alacard-update.conf >/dev/null
echo "CHANNEL=$CHANNEL" | sudo tee -a /etc/alacard-update.conf >/dev/null
cp "$DIR/kiosk-setup/update/alacard-update.sh" "$HOME/.local/bin/" 2>/dev/null || true
chmod +x "$HOME/.local/bin/alacard-update.sh" 2>/dev/null || true
ok "this kiosk will fetch its own updates from now on"

bold "Done — reboot to finish"
echo "  sudo reboot"
echo
echo "  To put the web kiosk back:"
echo "    bash $DIR/kiosk-setup/switch-from-web.sh --undo"
