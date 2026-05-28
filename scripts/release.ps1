param(
  [string]$Message = "chore: release v1.0.0"
)

git add .
git commit -m $Message
git tag -a v1.0.0 -m "v1.0.0"
git push origin HEAD
git push origin v1.0.0

if (Get-Command gh -ErrorAction SilentlyContinue) {
  gh release create v1.0.0 -F .github/RELEASE_BODY_v1.0.0.md
} else {
  Write-Host "gh CLI not found; create the release manually and paste .github/RELEASE_BODY_v1.0.0.md"
}
