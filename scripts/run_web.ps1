param(
    [string]$Device = 'chrome',
    [int]$Port = 0
)

# Run flutter on a free port. When Port=0, Flutter picks a free port.
if ($Port -eq 0) {
    Write-Host "Running: flutter run -d $Device --web-port=0"
    flutter run -d $Device --web-port=0
} else {
    Write-Host "Running: flutter run -d $Device --web-port=$Port"
    flutter run -d $Device --web-port=$Port
}
