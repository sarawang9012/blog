# auto-commit-eng.ps1
param(
    [string]$Message = "Auto sync $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

$quartzPath = "C:\Users\iamno\work\git\quartz"

Set-Location $quartzPath

$status = git status --porcelain

if ($status) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Changes detected, committing..." -ForegroundColor Green
    Write-Host "Changed files:" -ForegroundColor Yellow
    git status --short
    git add .
    git commit -m "$Message"
    git push
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Commit successful!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] No changes, skipped." -ForegroundColor Gray
}
