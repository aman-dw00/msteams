#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
GRAFANA_URL="http://localhost:3000"
API_KEY=""
LOCAL_ROOT="GRAFANA-DASH"
AUTH_HEADER="Authorization: Bearer ${API_KEY}"

# === SETUP ===
mkdir -p "$LOCAL_ROOT"
declare -A folder_paths  # Maps folder UID to local filesystem path

# === FUNCTION TO CALL API ===
api_request() {
  local endpoint="$1"
  curl -s -H "$AUTH_HEADER" -H "Content-Type: application/json" "${GRAFANA_URL}${endpoint}"
}

# === RECURSIVE FUNCTION TO FETCH FOLDERS ===
fetch_folders_recursively() {
  local parent_uid="$1"
  local base_path="$2"
  local folders

  # Determine if root or child level
  if [[ "$parent_uid" == "root" ]]; then
    folders=$(api_request "/api/folders" | jq -c '.[] | select(.uid != "sharedwithme")')
  else
    folders=$(api_request "/api/folders?parentUid=${parent_uid}" | jq -c '.[]')
  fi

  while read -r folder; do
    [[ -z "$folder" ]] && continue

    uid=$(echo "$folder" | jq -r '.uid')
    title=$(echo "$folder" | jq -r '.title')

    # Sanitize folder name
    safe_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-zA-Z0-9_-/')
    full_path="${base_path}/${safe_title}"
    full_path=$(echo "$full_path" | sed 's|^/||')  # Remove leading slash if any

    folder_paths["$uid"]="$full_path"

    mkdir -p "$LOCAL_ROOT/$full_path"
    echo "Created folder: $full_path"

    # Recurse into subfolders
    fetch_folders_recursively "$uid" "$full_path"
  done <<< "$folders"
}

# === START FOLDER FETCH ===
echo "Building folder hierarchy..."
folder_paths["root"]=""
fetch_folders_recursively "root" ""

# === DOWNLOAD DASHBOARDS ===
echo "Downloading dashboards..."
dashboards=$(api_request "/api/search?type=dash-db" | jq -c '.[]')

while read -r dashboard; do
  [[ -z "$dashboard" ]] && continue

  uid=$(echo "$dashboard" | jq -r '.uid')
  title=$(echo "$dashboard" | jq -r '.title')
  folder_uid=$(echo "$dashboard" | jq -r '.folderUid // "root"')

  # Sanitize file name
  safe_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-zA-Z0-9_')
  filename="${safe_title}.json"

  # Fetch dashboard JSON
  dashboard_json=$(api_request "/api/dashboards/uid/$uid" | jq '.dashboard')

  # Determine path
  folder_path="${folder_paths[$folder_uid]:-.}"
  full_path="$LOCAL_ROOT/$folder_path/$filename"

  # Save dashboard JSON
  echo "$dashboard_json" > "$full_path"
  echo "Saved: $folder_path/$filename"
done <<< "$dashboards"

echo "✅ Done! All dashboards downloaded with nested folder structure in '$LOCAL_ROOT'"
