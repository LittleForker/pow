#!/bin/sh
#
#     8b,dPPYba,    ,adPPYba,   8b      db      d8
#     88P'    "8a  a8"     "8a  `8b    d88b    d8'
#     88       d8  8b       d8   `8b  d8'`8b  d8'
#     88b,   ,a8"  "8a,   ,a8"    `8bd8'  `8bd8'
#     88`YbbdP"'    `"YbbdP"'       YP      YP
#     88
#     88    Zero-configuration Rack server
#           for Mac OS X -- http://pow.cx/
#
#
#     You're reading the uinstallation script for Pow.
#     See the full annotated source: http://pow.cx/docs/
#
#     Uninstall Pow by running this command:
#     curl get.pow.cx/uninstall.sh | sh


# Set up the environment.

      set -e
      POW_ROOT="$HOME/Library/Application Support/Pow"
      POW_CURRENT_PATH="$POW_ROOT/Current"
      POW_VERSIONS_PATH="$POW_ROOT/Versions"
      POWD_PLIST_PATH="$HOME/Library/LaunchAgents/cx.pow.powd.plist"
      FIREWALL_PLIST_PATH="/Library/LaunchDaemons/cx.pow.firewall.plist"


# Fail fast if Pow isn't present.

      if [[ ! -d "$POW_CURRENT_PATH" ]] && [[ ! -a "$POWD_PLIST_PATH" ]] && [[ ! -a "$FIREWALL_PLIST_PATH" ]]; then
        echo "error: can't find Pow" >&2
        exit 1
      fi


# Find the tty so we can prompt for confirmation even if we're being piped from curl.

      TTY="/dev/$( ps -p$$ | tail -1 | awk '{print$2}' )"


# Make sure we really want to uninstall.

      read -p "Sorry to see you go. Uninstall Pow [y/n]? " ANSWER < $TTY
      [[ $ANSWER == "y" ]] || exit 1
      echo "*** Uninstalling Pow..."


# Remove the Versions directory and the Current symlink.

      rm -fr "$POW_VERSIONS_PATH"
      rm -f "$POW_CURRENT_PATH"


# Unload cx.pow.powd from launchctl and remove the plist.

      launchctl unload "$POWD_PLIST_PATH" 2>/dev/null || true
      rm -f "$POWD_PLIST_PATH"


# Read the firewall plist, if possible, to figure out what ports are in use.

      if [[ -a "$FIREWALL_PLIST_PATH" ]]; then
        ports=($(ruby -e'puts $<.read.scan(/fwd .*?,([\d]+).*?dst-port ([\d]+)/)' "$FIREWALL_PLIST_PATH"))

        HTTP_PORT=${ports[0]}
        DST_PORT=${ports[1]}
      fi


# Assume reasonable defaults otherwise.

      [[ -z "$HTTP_PORT" ]] && HTTP_PORT=20559
      [[ -z "$DST_PORT" ]] && DST_PORT=80


# Try to find the ipfw rule and delete it.

      RULE=$(sudo ipfw show | (grep ",$HTTP_PORT .* dst-port $DST_PORT in" || true) | cut -f 1 -d " ")
      [[ -n "$RULE" ]] && sudo ipfw del "$RULE"


# Unload the firewall plist and remove it.

      sudo launchctl unload "$FIREWALL_PLIST_PATH" 2>/dev/null || true
      sudo rm -f "$FIREWALL_PLIST_PATH"

      echo "*** Uninstalled"
