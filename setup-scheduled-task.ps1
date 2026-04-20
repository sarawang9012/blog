# setup-scheduled-task.ps1
# Create Windows scheduled task to automatically detect and commit every 30 minutes

$taskName = "Obsidian auto commit"
$scriptPath = "C:\Users\iamno\work\git\quartz\auto-commit-eng.ps1"

# Action: the command to execute
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# Trigger: run every 30 minutes, starting now
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)

# Settings: allow to run on battery power without stopping
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Register the task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Auto-check Quartz content folder for changes and commit to GitHub"

Write-Host "Scheduled task created successfully!" -ForegroundColor Green
Write-Host "Task name: $taskName" -ForegroundColor Yellow
Write-Host "Execution interval: every 30 minutes" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can view or edit this task in Task Scheduler." -ForegroundColor Cyan
