#!/bin/bash
# Emits a JSON array of installed apps ([{"name":..., "exec":..., "path":...}, ...])
# for the quickshell app-menu list, reading .desktop files directly instead of
# going through a launcher like fuzzel/wofi. "path" (the .desktop file itself)
# is only used by the Sys > Apps > App Launchers section, to open it in nvim.
# Filters by the search term passed as $1 (case-insensitive), if any.
#
# Everything runs through a single awk pass over all .desktop files instead of
# forking grep/cut/sed per file per field - that was ~450ms for 89 apps
# (visibly laggy while typing in the search box), this is well under 100ms.

shopt -s nullglob

search_lower="${1,,}"

dirs=(
    "$HOME/.local/share/applications"
    "/usr/local/share/applications"
    "/usr/share/applications"
)

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '%s' "$s"
}

files=()
for dir in "${dirs[@]}"; do
    for f in "$dir"/*.desktop; do
        files+=("$f")
    done
done

entries=()
while IFS=$'\t' read -r name exec_line path; do
    [[ -z "$name" || -z "$exec_line" ]] && continue
    # Strip desktop-entry field codes (%f %F %u %U %i %c %k ...) without forking sed
    clean_exec="${exec_line//%?/}"
    entries+=("{\"name\":\"$(json_escape "$name")\",\"exec\":\"$(json_escape "$clean_exec &")\",\"path\":\"$(json_escape "$path")\"}")
done < <(
    ((${#files[@]})) && awk -F= -v search="$search_lower" '
        function basename(p,   n) { n = p; sub(/.*\//, "", n); return n }
        function flush() {
            if (skipfile || name == "" || execl == "" || nodisplay || hidden) return
            if (search != "" && index(tolower(name), search) == 0) return
            print name "\t" execl "\t" fname
        }
        FNR == 1 {
            if (NR > 1) flush()
            name = ""; execl = ""; nodisplay = 0; hidden = 0; in_entry = 0
            fname = FILENAME
            b = basename(fname)
            if (b in seen) { skipfile = 1 } else { seen[b] = 1; skipfile = 0 }
        }
        skipfile { next }
        /^\[Desktop Entry\]/ { in_entry = 1; next }
        /^\[/ { in_entry = 0 }
        in_entry && $1 == "NoDisplay" && $2 == "true" { nodisplay = 1 }
        in_entry && $1 == "Hidden" && $2 == "true" { hidden = 1 }
        in_entry && $1 == "Name" { name = substr($0, index($0, "=") + 1) }
        in_entry && $1 == "Exec" { execl = substr($0, index($0, "=") + 1) }
        END { flush() }
    ' "${files[@]}"
)

printf '%s\n' "${entries[@]}" | sort -t'"' -k4 | paste -sd, - | sed 's/^/[/; s/$/]/'
