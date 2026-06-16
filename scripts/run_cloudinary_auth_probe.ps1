param(
  [Parameter(Mandatory=$false)]
  [string]$CloudName = 'dojmnvq5o',
  [Parameter(Mandatory=$false)]
  [string]$UploadPreset = 'Unsigned_cafe'
)

$envFile = "$env:USERPROFILE\.cloudinary\environments.json"
$j = Get-Content $envFile -Raw | ConvertFrom-Json
$creds = $j.$CloudName
if (-not $creds) {
  Write-Host "No credentials found for $CloudName in $envFile" -ForegroundColor Red
  exit 1
}
$key = $creds.apiKey
$secret = $creds.apiSecret
$uploadUrl = "https://api.cloudinary.com/v1_1/$CloudName/image/upload"
$base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6nGioAAAAASUVORK5CYII='
$tmp = Join-Path $env:TEMP 'cloudinary_probe_auth.png'
[IO.File]::WriteAllBytes($tmp, [Convert]::FromBase64String($base64))

Add-Type -AssemblyName System.Net.Http
$handler = New-Object System.Net.Http.HttpClientHandler
$client = New-Object System.Net.Http.HttpClient($handler)
$authBytes = [Text.Encoding]::UTF8.GetBytes($key + ':' + $secret)
$auth = [Convert]::ToBase64String($authBytes)
$client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Basic', $auth)

$bytes = [IO.File]::ReadAllBytes($tmp)
$content = [System.Net.Http.MultipartFormDataContent]::new()
$fileContent = [System.Net.Http.ByteArrayContent]::new([byte[]]$bytes)
$fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse('image/png')
$content.Add($fileContent, 'file', (Split-Path $tmp -Leaf))
$content.Add([System.Net.Http.StringContent]::new($UploadPreset), 'upload_preset')

$responseMessage = $client.PostAsync($uploadUrl, $content).Result
$resp = $responseMessage.Content.ReadAsStringAsync().Result
if(-not $responseMessage.IsSuccessStatusCode){
  Write-Host 'AUTH UPLOAD FAILED' -ForegroundColor Red
  Write-Host $resp
  exit 1
} else {
  Write-Host 'AUTH UPLOAD OK' -ForegroundColor Green
  Write-Host $resp
}

Remove-Item $tmp -Force
