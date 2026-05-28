param(
  [Parameter(Mandatory=$true)][string]$webKey,
  [Parameter(Mandatory=$true)][string]$androidKey,
  [Parameter(Mandatory=$true)][string]$iosKey
)

Write-Host "Replacing web key in web/index.html"
(Get-Content web/index.html) -replace 'YOUR_WEB_API_KEY', $webKey | Set-Content web/index.html

Write-Host "Replacing Android key in AndroidManifest.xml"
(Get-Content android/app/src/main/AndroidManifest.xml) -replace 'ISI_API_KEY_GOOGLE_MAPS', $androidKey | Set-Content android/app/src/main/AndroidManifest.xml

Write-Host "Replacing iOS key in AppDelegate.swift"
(Get-Content ios/Runner/AppDelegate.swift) -replace 'YOUR_IOS_API_KEY', $iosKey | Set-Content ios/Runner/AppDelegate.swift

Write-Host "Done. Remember not to commit your API keys to version control."
