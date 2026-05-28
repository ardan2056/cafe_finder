param(
    [int[]]$Ports = 8080..8090,
    [switch]$Force
)

Write-Host "Scanning listening TCP ports: $($Ports -join ', ')"
$connections = Get-NetTCPConnection -State Listen | Where-Object { $Ports -contains $_.LocalPort }
if (-not $connections) {
    Write-Host "No listeners found in the specified port range."
    exit 0
}

$grouped = $connections | Group-Object -Property OwningProcess
foreach ($g in $grouped) {
    $pid = $g.Name
    $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
    $name = if ($proc) { $proc.ProcessName } else { '<unknown>' }
    $ports = ($g.Group | Select-Object -ExpandProperty LocalPort) -join ', '
    Write-Host "PID: $pid  Process: $name  Ports: $ports"
}

if (-not $Force) {
    $confirm = Read-Host "Terminate these processes? Type YES to confirm"
    if ($confirm -ne 'YES') {
        Write-Host "Aborted. No processes were killed."
        exit 0
    }
}

foreach ($g in $grouped) {
    $pid = [int]$g.Name
    try {
        Stop-Process -Id $pid -Force -ErrorAction Stop
        Write-Host "Stopped PID $pid"
    } catch {
        Write-Warning "Failed to stop PID $pid: $_"
    }
}

Write-Host "Done."