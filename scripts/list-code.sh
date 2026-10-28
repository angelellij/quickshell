#!/bin/bash
# Emits a JSON array of project folders ([{"name":..., "exec":...}, ...])
# for the quickshell code-overview list: ~/.config plus each repo under
# ~/Documents/GitHub. Each one opens a terminal with a tmux session in that
# folder, named after it: reopening the same folder reattaches to it.
# Filters by the search term passed as $1 (case-insensitive), if any.

TARGET_DIR="$HOME/Documents/GitHub"
search_lower="${1,,}"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

# Command that opens a folder (already JSON/shell-escaped) in a terminal,
# inside tmux session $2 (tmux doesn't allow "." or ":" in session names).
open_cmd() {
    local session="${2//[^A-Za-z0-9_-]/_}"
    printf 'alacritty --working-directory \\\"%s\\\" -e tmux new-session -A -s %s &' "$1" "$session"
}

entries=()
if [[ -z "$search_lower" || ".config" == *"$search_lower"* ]]; then
    entries+=("{\"name\":\".config\",\"exec\":\"$(open_cmd "$(json_escape "$HOME/.config")" ".config")\"}")
fi

while IFS= read -r d; do
    name="$(basename "$d")"
    [[ -n "$search_lower" && "${name,,}" != *"$search_lower"* ]] && continue
    entries+=("{\"name\":\"$(json_escape "$name")\",\"exec\":\"$(open_cmd "$(json_escape "$d")" "$name")\"}")
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

printf '%s\n' "${entries[@]}" | paste -sd, - | sed 's/^/[/; s/$/]/'
