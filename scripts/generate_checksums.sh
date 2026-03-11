#!/usr/bin/env bash
# =============================================================================
# generate_checksums.sh
#
# Generates SHA-256 checksums for all build artifacts in the release_builds/
# directory. This script creates a checksums.txt file containing the hashes
# which must be verified by the Flutter plugin build scripts (Gradle, CocoaPods,
# CMake) when downloading the pre-built libraries.
#
# Usage:
#   cd scripts
#   ./generate_checksums.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
RELEASE_DIR="$ROOT_DIR/release_builds"
OUTPUT_FILE="$RELEASE_DIR/checksums.txt"

# Ensure the release directory exists
if [[ ! -d "$RELEASE_DIR" ]]; then
  echo "Error: Directory $RELEASE_DIR does not exist."
  echo "Please build the platform libraries first."
  exit 1
fi

echo "Generating SHA-256 checksums for release artifacts..."
echo "Directory: $RELEASE_DIR"
echo "--------------------------------------------------------"

# Remove old checksum file if it exists
rm -f "$OUTPUT_FILE"

# Find an appropriate sha256 command (macOS vs Linux)
if command -v shasum >/dev/null 2>&1; then
  SHA_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  SHA_CMD="sha256sum"
else
  echo "Error: No suitable SHA-256 command found (shasum or sha256sum)."
  exit 1
fi

count=0
# Loop through all files in the release directory, excluding checksums.txt itself
for file in "$RELEASE_DIR"/*; do
  if [[ -f "$file" ]] && [[ "$(basename "$file")" != "checksums.txt" ]]; then
    filename=$(basename "$file")
    
    # Calculate hash and extract only the hash part
    hash_output=$($SHA_CMD "$file")
    hash=$(echo "$hash_output" | awk '{print $1}')
    
    # Get human-readable file size using ls/awk
    if [[ "$OSTYPE" == "darwin"* ]]; then
      size=$(ls -lh "$file" | awk '{print $5}')
    else
      size=$(ls -lh "$file" | awk '{print $5}')
    fi
    
    # Append to output file
    echo "$hash  $filename" >> "$OUTPUT_FILE"
    
    # Print to console
    printf "%-40s | %-10s | %s\n" "$filename" "$size" "$hash"
    ((count++))
  fi
done

echo "--------------------------------------------------------"
if [[ $count -eq 0 ]]; then
  echo "No files found in $RELEASE_DIR."
  rm -f "$OUTPUT_FILE"
else
  echo "Successfully generated checksums for $count files."
  echo "Checksums saved to: $OUTPUT_FILE"
  echo ""
  echo "Next Steps:"
  echo "1. Create a new GitHub Release."
  echo "2. Upload all files from $RELEASE_DIR to the release."
  echo "3. Update the checksums and VERSION variables in:"
  echo "   - android/build.gradle.kts"
  echo "   - ios/mpv_audio_pro_kit.podspec"
  echo "   - macos/mpv_audio_pro_kit.podspec"
  echo "   - windows/CMakeLists.txt"
  echo "   - linux/CMakeLists.txt"
fi
