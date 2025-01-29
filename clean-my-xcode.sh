#!/usr/bin/env bash

# ------------------------------
# Configuration
# ------------------------------

XCODE_FOLDERS=(
  "$HOME/Library/Developer/Xcode/DerivedData"
  "$HOME/Library/Developer/Xcode/Archives"
  "$HOME/Library/Developer/Xcode/Products"
  "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  "$HOME/Library/Developer/Xcode/macOS DeviceSupport"
  "$HOME/Library/Developer/Xcode/watchOS DeviceSupport"
  "$HOME/Library/Developer/Xcode/UserData/Previews"
)

TEMP_FILE=$(mktemp)

# ------------------------------
# Function Definitions
# ------------------------------

spinner() {
  local pid=$1
  local delay=0.1
  local spin_chars='-\|/'

  while kill -0 "$pid" 2>/dev/null; do
    for char in $spin_chars; do
      printf "\r[%s] Gathering data..." "$char"
      sleep "$delay"
    done
  done
  printf "\r[✔] Done gathering data!          \n"
}

check_permissions() {
  local temp_test="$HOME/Library/.clean-my-xcode-permission-test"
  touch "$temp_test" &>/dev/null

  if [ $? -ne 0 ]; then
    echo "Insufficient permissions. Requesting elevated permissions via sudo..."
    sudo bash "$0" "$@"
    exit $?
  else
    rm -f "$temp_test"
  fi
}

gather_sizes_and_dates() {
  for folder in "${XCODE_FOLDERS[@]}"; do
    if [ -d "$folder" ]; then
      size_kb=$(du -sk "$folder" 2>/dev/null | cut -f1)
      size_h=$(du -sh "$folder" 2>/dev/null | cut -f1)
      last_used=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$folder" 2>/dev/null || echo "Unknown")
      echo "$last_used|$size_kb|$size_h|$folder" >> "$TEMP_FILE"
    fi
  done
}

read_gathered_data() {
  FOLDER_DATA=()
  while IFS= read -r line; do
    FOLDER_DATA+=("$line")
  done < "$TEMP_FILE"
}

sort_folders_by_date() {
  IFS=$'\n' FOLDER_DATA=($(sort -rk1 <<< "${FOLDER_DATA[*]}"))
  unset IFS
}

show_warning() {
  echo "⚠️  Deleting Xcode caches may require Xcode to regenerate them."
  echo "   This can cause delays during your next build."
  echo
}

list_main_directories() {
  echo "Available main directories (sorted by last used date):"
  echo "---------------------------------------------------------------"
  local index=1
  local directories=()
  for entry in "${FOLDER_DATA[@]}"; do
    last_used="${entry%%|*}"
    rest="${entry#*|}"
    size_kb="${rest%%|*}"
    rest="${rest#*|}"
    size_h="${rest%%|*}"
    path="${rest#*|}"
    printf "%-5s %-20s %-10s %-50s\n" "$index" "$last_used" "$size_h" "$path"
    directories+=("$path")
    ((index++))
  done
  echo "---------------------------------------------------------------"
  echo
  echo "Enter the number of the directory you want to navigate into."
  echo "Press Enter to skip."
  read -p "Your choice: " selection

  if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#directories[@]}" ]; then
    list_subfolders "${directories[$((selection - 1))]}"
  else
    echo "No valid selection. Skipping."
  fi
}

list_subfolders() {
  local parent_folder=$1
  echo "Contents of: $parent_folder (sorted by last used date)"
  echo "---------------------------------------------------------------"
  local subfolders=()
  local index=1
  for item in "$parent_folder"/*; do
    if [ -e "$item" ]; then
      last_used=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$item" 2>/dev/null || echo "Unknown")
      size_h=$(du -sh "$item" 2>/dev/null | cut -f1)
      subfolders+=("$last_used|$size_h|$item")
    fi
  done

  IFS=$'\n' subfolders=($(sort -rk1 <<< "${subfolders[*]}"))
  unset IFS

  for entry in "${subfolders[@]}"; do
    last_used="${entry%%|*}"
    rest="${entry#*|}"
    size_h="${rest%%|*}"
    path="${rest#*|}"
    printf "%-5s %-20s %-10s %-50s\n" "$index" "$last_used" "$size_h" "$path"
    ((index++))
  done
  echo "---------------------------------------------------------------"
  echo
  echo "Enter the numbers of the items you want to delete, separated by spaces (e.g., 1 3 5)."
  echo "Press Enter to skip."
  read -p "Your selection: " -a selections

  local to_delete=()
  for sel in "${selections[@]}"; do
    if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#subfolders[@]}" ]; then
      to_delete+=("${subfolders[$((sel - 1))]}")
    fi
  done

  if [ ${#to_delete[@]} -eq 0 ]; then
    echo "No valid selections made. Skipping deletion for $parent_folder."
    return
  fi

  echo "You have selected to delete the following:"
  for item in "${to_delete[@]}"; do
    path="${item#*|*|}"
    echo " - $path"
  done
  read -p "Are you sure? (y/n): " confirm
  if [[ "$confirm" =~ ^[yY]$ ]]; then
    for item in "${to_delete[@]}"; do
      path="${item#*|*|}"
      echo -n "Deleting: $path... "
      rm -rf "$path"
      if [ $? -eq 0 ]; then
        echo "✔ Done."
      else
        echo "❌ Failed."
      fi
    done
  else
    echo "Aborted deletion for $parent_folder."
  fi
}

# ------------------------------
# Main Script
# ------------------------------

if [ -z "$BASH_VERSION" ]; then
  echo "❌ Error: Please run this script with Bash."
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  check_permissions "$@"
fi

show_warning

echo "Gathering sizes and last used dates of Xcode cache directories. Please wait..."
gather_sizes_and_dates &
spinner "$!"

read_gathered_data
sort_folders_by_date
rm -f "$TEMP_FILE"

if [ ${#FOLDER_DATA[@]} -eq 0 ]; then
  echo "No Xcode cache directories found."
  exit 0
fi

echo "Found the following Xcode cache directories (sorted by last used date):"
echo "---------------------------------------------------------------"
printf "%-5s %-20s %-10s %-50s\n" "No." "Last Used" "Size" "Path"
echo "---------------------------------------------------------------"
index=1
for entry in "${FOLDER_DATA[@]}"; do
  last_used="${entry%%|*}"
  rest="${entry#*|}"
  size_kb="${rest%%|*}"
  rest="${rest#*|}"
  size_h="${rest%%|*}"
  path="${rest#*|}"
  printf "%-5s %-20s %-10s %-50s\n" "$index" "$last_used" "$size_h" "$path"
  ((index++))
done
echo "---------------------------------------------------------------"

echo
echo "Options:"
echo "1) Delete all directories"
echo "2) Select specific directories"
read -p "Your choice [1/2]: " choice

if [ "$choice" == "1" ]; then
  echo "Deleting all directories..."
  for entry in "${FOLDER_DATA[@]}"; do
    path="${entry#*|*|*|}"
    echo -n "Deleting: $path... "
    rm -rf "$path"
    if [ $? -eq 0 ]; then
      echo "✔ Done."
    else
      echo "❌ Failed."
    fi
  done
elif [ "$choice" == "2" ]; then
  list_main_directories
else
  echo "Invalid choice. Exiting."
fi

echo "---------------------------------------------------------------"
echo "Cleanup completed."
exit 0
