param(
  [Parameter(Mandatory = $true)]
  [string]$CloudName,

  [Parameter(Mandatory = $true)]
  [string]$UploadPreset
)

$ErrorActionPreference = 'Stop'

$uploadUrl = "https://api.cloudinary.com/v1_1/$CloudName/image/upload"

# tiny 1x1 transparent PNG
$base64Png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6nGioAAAAASUVORK5CYII="
$tempFile = Join-Path $env:TEMP "cloudinary_probe_$(Get-Date -Format yyyyMMdd_HHmmss).png"

[IO.File]::WriteAllBytes($tempFile, [Convert]::FromBase64String($base64Png))

try {
  $invokeHasForm = $false
  try {
    $invokeHasForm = (Get-Command Invoke-RestMethod).Parameters.ContainsKey('Form')
  } catch {}

  if ($invokeHasForm) {
    $response = Invoke-RestMethod -Uri $uploadUrl -Method Post -Form @{
      upload_preset = $UploadPreset
      file = Get-Item $tempFile
      folder = "debug/probe"
    }
  } else {
    # Fallback for Windows PowerShell (no -Form): use .NET HttpClient to post multipart
    try {
      Add-Type -AssemblyName System.Net.Http -ErrorAction Stop
    } catch {
      Write-Host "FATAL: tidak dapat memuat System.Net.Http dari .NET runtime." -ForegroundColor Red
      Write-Host "Solusi: jalankan script ini menggunakan PowerShell Core (pwsh) atau instal PowerShell 7+ pada Windows." -ForegroundColor Yellow
      Write-Host "Contoh: 'pwsh ./scripts/test_cloudinary_upload.ps1 -CloudName <name> -UploadPreset <preset>'" -ForegroundColor Yellow
      throw
    }
    $client = New-Object System.Net.Http.HttpClient
    $bytes = [IO.File]::ReadAllBytes($tempFile)
    $content = [System.Net.Http.MultipartFormDataContent]::new()
    $fileContent = [System.Net.Http.ByteArrayContent]::new([byte[]]$bytes)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("image/png")
    $content.Add($fileContent, "file", (Split-Path $tempFile -Leaf))
    $content.Add([System.Net.Http.StringContent]::new($UploadPreset), "upload_preset")
    $content.Add([System.Net.Http.StringContent]::new("debug/probe"), "folder")

    $responseMessage = $client.PostAsync($uploadUrl, $content).Result
    $respBody = $responseMessage.Content.ReadAsStringAsync().Result
    if (-not $responseMessage.IsSuccessStatusCode) {
      throw "Cloudinary upload failed with status $($responseMessage.StatusCode): $respBody"
    }
    $response = $respBody | ConvertFrom-Json
  }

  if ($null -eq $response.secure_url -or [string]::IsNullOrWhiteSpace($response.secure_url)) {
    throw "Cloudinary response tidak berisi secure_url."
  }

  Write-Host "Cloudinary OK ✅" -ForegroundColor Green
  Write-Host "secure_url: $($response.secure_url)"
}
catch {
  Write-Host "Cloudinary GAGAL ❌" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Yellow
  if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
    Write-Host $_.ErrorDetails.Message -ForegroundColor Yellow
  }
  exit 1
}
finally {
  if (Test-Path $tempFile) {
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
  }
}
