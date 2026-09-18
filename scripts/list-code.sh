#!/bin/bash
# Emits a JSON array of VS Code targets ([{"name":..., "exec":...}, ...])
# for the quickshell code-overview list: ~/.config plus each repo under
# ~/Documents/GitHub.
# Filters by the search term passed as $1 (case-insensitive), if any.

TARGET_DIR="$HOME/Documents/GitHub"
search_lower="${1,,}"

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

entries=()
if [[ -z "$search_lower" || ".config" == *"$search_lower"* ]]; then
    entries+=("{\"name\":\".config\",\"exec\":\"code \\\"$(json_escape "$HOME/.config")\\\" &\"}")
fi

while IFS= read -r d; do
    name="$(basename "$d")"
    [[ -n "$search_lower" && "${name,,}" != *"$search_lower"* ]] && continue
    entries+=("{\"name\":\"$(json_escape "$name")\",\"exec\":\"code \\\"$(json_escape "$d")\\\" &\"}")
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)

printf '%s\n' "${entries[@]}" | paste -sd, - | sed 's/^/[/; s/$/]/'
