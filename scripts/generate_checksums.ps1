# =============================================================================
# generate_checksums.ps1
#
# Generates SHA-256 checksums for all build artifacts in the release_builds/
# directory on Windows using PowerShell. This script creates a checksums.txt 
# file containing the hashes which must be verified by the Flutter plugin 
# build scripts (Gradle, CocoaPods, CMake) when downloading the pre-built 
# libraries.
#
# Usage:
#   cd scripts
#   .\generate_checksums.ps1
# =============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$ReleaseDir = Join-Path $RootDir "release_builds"
$OutputFile = Join-Path $ReleaseDir "checksums.txt"

# Ensure the release directory exists
if (-not (Test-Path $ReleaseDir)) {
    Write-Host "Error: Directory $ReleaseDir does not exist." -ForegroundColor Red
    Write-Host "Please build the platform libraries first."
    exit 1
}

Write-Host "Generating SHA-256 checksums for release artifacts..."
Write-Host "Directory: $ReleaseDir"
Write-Host "--------------------------------------------------------"

# Remove old checksum file if it exists
if (Test-Path $OutputFile) {
    Remove-Item $OutputFile
}

$Count = 0
# Get all files except checksums.txt
$Files = Get-ChildItem -Path $ReleaseDir -File | Where-Object { $_.Name -ne "checksums.txt" }

foreach ($File in $Files) {
    # Calculate hash
    $HashResult = Get-FileHash -Path $File.FullName -Algorithm SHA256
    $Hash = $HashResult.Hash.ToLower()
    $FileName = $File.Name
    
    # Format size (human readable)
    $SizeInBytes = $File.Length
    $SizeString = ""
    if ($SizeInBytes -gt 1GB) {
        $SizeString = "$([Math]::Round($SizeInBytes / 1GB, 1))G"
    } elseif ($SizeInBytes -gt 1MB) {
        $SizeString = "$([Math]::Round($SizeInBytes / 1MB, 1))M"
    } elseif ($SizeInBytes -gt 1KB) {
        $SizeString = "$([Math]::Round($SizeInBytes / 1KB, 1))K"
    } else {
        $SizeString = "$($SizeInBytes)B"
    }

    # Append to output file (using Unix style spaces for consistency with shasum/sha256sum)
    "$Hash  $FileName" | Out-File -FilePath $OutputFile -Append -Encoding ascii -NoNewline
    "`n" | Out-File -FilePath $OutputFile -Append -Encoding ascii -NoNewline

    # Print to console
    $FilePart = $FileName.PadRight(40).Substring(0, 40)
    $SizePart = $SizeString.PadRight(10).Substring(0, 10)
    Write-Host "$FilePart | $SizePart | $Hash"
    $Count++
}

Write-Host "--------------------------------------------------------"
if ($Count -eq 0) {
    Write-Host "No files found in $ReleaseDir." -ForegroundColor Yellow
} else {
    Write-Host "Successfully generated checksums for $Count files." -ForegroundColor Green
    Write-Host "Checksums saved to: $OutputFile"
    Write-Host ""
    Write-Host "Next Steps:"
    Write-Host "1. Create a new GitHub Release."
    Write-Host "2. Upload all files from $ReleaseDir to the release."
    Write-Host "3. Update the checksums and VERSION variables in:"
    Write-Host "   - android/build.gradle.kts"
    Write-Host "   - ios/mpv_audio_kit.podspec"
    Write-Host "   - macos/mpv_audio_kit.podspec"
    Write-Host "   - windows/CMakeLists.txt"
    Write-Host "   - linux/CMakeLists.txt"
}
