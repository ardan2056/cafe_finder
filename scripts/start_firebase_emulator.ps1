param(
    [string]$ProjectId = "auto"
)

# Starts Firebase Auth + Firestore emulators for local testing.
# Usage: .\scripts\start_firebase_emulator.ps1 -ProjectId your-firebase-project-id

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Error "firebase CLI not found. Install with: npm i -g firebase-tools"
    exit 2
}

Write-Host "Starting Firebase Auth + Firestore emulators for project: $ProjectId"
Write-Host "This window will run the emulators. Open a second terminal to run the app with emulator env var."

# Set environment variable for child processes in this session
$env:USE_FIREBASE_EMULATOR = '1'

# Start emulators (will run in foreground)
firebase emulators:start --only auth,firestore --project $ProjectId
