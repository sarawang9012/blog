# setup-scheduled-task.ps1
# 创建 Windows 定时任务，每 30 分钟自动检测并提交

$taskName = "Obsidian博客自动提交"
$scriptPath = "C:\Users\iamno\work\git\quartz\auto-commit.ps1"

# 要执行的命令
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

# 触发器：每 30 分钟执行一次
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30)

# 设置：即使电脑未登录也运行
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# 注册任务
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "自动检测 Quartz content 文件夹变化并提交到 GitHub"

Write-Host "定时任务已创建！" -ForegroundColor Green
Write-Host "任务名称: $taskName" -ForegroundColor Yellow
Write-Host "执行频率: 每 30 分钟" -ForegroundColor Yellow
Write-Host ""
Write-Host "你可以在"任务计划程序"中查看或修改此任务。" -ForegroundColor Cyan
