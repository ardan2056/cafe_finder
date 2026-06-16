param(
  [Parameter(Mandatory = $true)]
  [string]$CloudName,

  [Parameter(Mandatory = $true)]
  [string]$UploadPreset
)

Set-Location -Path "$PSScriptRoot\.."

$env:CLOUDINARY_CLOUD_NAME = $CloudName
$env:CLOUDINARY_UPLOAD_PRESET = $UploadPreset

Write-Host "Running with CLOUDINARY_CLOUD_NAME=$CloudName" -ForegroundColor Cyan
Write-Host "Running with CLOUDINARY_UPLOAD_PRESET=$UploadPreset" -ForegroundColor Cyan

flutter run -d windows
