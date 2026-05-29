param(
    [string]$ProjectId = "auto"
)

# Runs Firebase emulators and executes the integration test against them.
# Usage:
#   .\scripts\run_emulator_integration_test.ps1 -ProjectId auto

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Error "firebase CLI not found. Install with: npm i -g firebase-tools"
    exit 2
}

Write-Host "Running emulators and executing integration tests (project: $ProjectId)"

# Build the command to run inside the emulators process. Use backtick to escape $env when embedded in double-quoted string.
$inner = "powershell -NoProfile -Command \`$env:USE_FIREBASE_EMULATOR='1'; flutter test integration_test/demo_migration_test.dart"

# Call firebase emulators:exec which sets emulator env vars for the child process
& firebase emulators:exec --only auth,firestore --project $ProjectId $inner

$rc = $LASTEXITCODE
if ($rc -ne 0) {
    Write-Error "Emulator exec or tests failed with exit code $rc"
}
exit $rc
