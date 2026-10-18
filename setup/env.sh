# Source this file to put the installed Craft CLIs on PATH:  source setup/env.sh
_craft_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
export CRAFT_HOME="${CRAFT_HOME:-$_craft_root/.craft}"
case ":$PATH:" in *":$CRAFT_HOME/bin:"*) ;; *) export PATH="$CRAFT_HOME/bin:$PATH" ;; esac
unset _craft_root
