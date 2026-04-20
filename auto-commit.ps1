# auto-commit.ps1
# 自动检测 content 文件夹变化并提交到 GitHub

param(
    [string]$Message = "自动同步 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
)

# 设置路径
$quartzPath = "C:\Users\iamno\work\git\quartz"
$contentPath = "$quartzPath\content"

# 切换到 Quartz 目录
Set-Location $quartzPath

# 检查是否有更改
$status = git status --porcelain

if ($status) {
    # 有更改，执行提交
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 检测到更改，正在提交..." -ForegroundColor Green
    
    # 显示更改的文件
    Write-Host "更改的文件：" -ForegroundColor Yellow
    git status --short
    
    # 添加所有更改
    git add .
    
    # 提交
    git commit -m "$Message"
    
    # 推送
    git push
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 提交成功！" -ForegroundColor Green
    Write-Host ""
} else {
    # 无更改
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 无更改，跳过提交。" -ForegroundColor Gray
}
