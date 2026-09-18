#!/bin/bash
# Emits a JSON array of scripts in ~/.config/textual-config/commands
# ([{"name":..., "exec":...}, ...]) for the quickshell commands-overview list.
# That folder is managed by the textual-config TUI, not by this repo.
# Filters by the search term passed as $1 (case-insensitive), if any.

TARGET_DIR="$HOME/.config/textual-config/commands"
search_lower="${1,,}"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

entries=()

while IFS= read -r f; do
    name="$(basename "$f")"
    [[ -n "$search_lower" && "${name,,}" != *"$search_lower"* ]] && continue
    entries+=("{\"name\":\"$(json_escape "$name")\",\"exec\":\"\\\"$(json_escape "$f")\\\" &\"}")
done < <(find "$TARGET_DIR" -maxdepth 1 -type f 2>/dev/null | sort)

printf '%s\n' "${entries[@]}" | paste -sd, - | sed 's/^/[/; s/$/]/'
