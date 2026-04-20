---
title: Obsidian + Quartz 搭建个人博客全记录
publish: true
---

# Obsidian + Quartz 搭建个人博客全记录

> 从零开始，将 Obsidian 笔记发布为 GitHub Pages 博客

## 一、环境准备

### 1. 安装 Node.js
- 使用 Volta 管理 Node 版本
- 要求：Node >= 22，npm >= 10.9.2

```bash
# 安装并切换 Node 22
volta install node@22
volta pin node@22

# 验证版本
node --version  # v22.x.x
npm --version   # >=10.9.2
```

### 2. 安装 Git

- 下载安装 Git for Windows
- 配置 SSH（可选，推荐）

## 二、初始化 Quartz 项目

### 1. 从模板创建仓库

- 访问 [https://github.com/jackyzha0/quartz/generate](https://github.com/jackyzha0/quartz/generate)
- 创建新仓库（如 `blog`，选择 Public）

### 2. 克隆到本地

bash

git clone https://github.com/你的用户名/仓库名.git
cd 仓库名
npm i
npx quartz create

### 3. 配置发布开关

编辑 `quartz.config.ts`，在 `filters` 中添加：

```typescript

filters: [
  Plugin.ExplicitPublish(),  // 只发布标记了 publish: true 的笔记
  // ...
]
```

## 三、连接 Obsidian

### 最终方案：将 Quartz content 文件夹作为 Obsidian Vault

1. 在 Obsidian 中打开文件夹：`C:\Users\你的用户名\work\git\quartz\content`
2. 将其作为新的 Vault 使用
3. 在需要发布的笔记顶部添加：

```markdown
---
title: 文章标题
publish: true
---
正文内容...
```
### 目录结构

```text

quartz/
├── content/          ← Obsidian Vault（也是博客内容）
│   ├── index.md      ← 博客首页
│   └── 其他笔记.md
├── quartz.config.ts  ← 配置文件
└── .github/          ← GitHub Actions 配置
```
## 四、本地预览

```bash
# 在 Quartz 根目录执行
npx quartz build --serve
```
访问 `http://localhost:8080` 预览效果。

## 五、部署到 GitHub Pages

### 1. 创建 GitHub Actions 工作流

创建 `.github/workflows/deploy.yml`：

```yaml

name: Deploy Quartz to GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: "pages"
  cancel-in-progress: false
jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Install Dependencies
        run: npm ci
      - name: Build Quartz
        run: npx quartz build
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: public
  deploy:
    needs: build
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4

```
### 2. 配置 Git 远程仓库

```bash
# 添加远程仓库（SSH 方式，推荐）
git remote add origin git@github.com:用户名/仓库名.git
# 或 HTTPS 方式
git remote add origin https://github.com/用户名/仓库名.git
```
### 3. 推送代码

```bash
git add .
git commit -m "初始化 Quartz 博客"
git push -u origin main
```
### 4. 开启 GitHub Pages

- 仓库 → Settings → Pages
- Source 选择 **GitHub Actions**
- 等待自动部署完成

### 5. 访问博客

```text
https://你的用户名.github.io/仓库名/
```
## 六、后续更新流程

### 日常写博客

1. 在 Obsidian 中写笔记，加上 `publish: true`
2. 保存后自动同步到 `content` 文件夹

### 发布更新

```bash
cd C:\Users\你的用户名\work\git\quartz
git add .
git commit -m "更新博客内容"
git push
```
GitHub Actions 会自动构建并部署，几分钟后生效。

## 七、常见问题及解决

### 1. Node 版本不匹配

```bash
# 使用 Volta 切换
volta install node@22
volta pin node@22
```
### 2. OG 图片生成失败

编辑 `quartz.config.ts`，注释掉：

```typescript
// Plugin.CustomOgImages(),
```
### 3. Git 连接失败

```bash
# 设置代理（根据你的代理端口）
git config --global http.proxy http://127.0.0.1:10809
git config --global https.proxy http://127.0.0.1:10809
# 或改用 SSH
git remote set-url origin git@github.com:用户名/仓库名.git
```
### 4. 分支名不匹配

```bash
# 查看当前分支
git branch
# 重命名为 main
git branch -M main
```
### 5. 笔记不显示

检查：

- 笔记顶部是否有 `publish: true`
- `quartz.config.ts` 中是否配置了 `Plugin.ExplicitPublish()`
- 文件是否在 `content` 目录下

## 八、目录结构总结

```text
C:\Users\你的用户名\work\git\quartz/
├── content/                    ← Obsidian Vault（博客内容）
│   ├── index.md               ← 首页
│   ├── 笔记1.md
│   └── 笔记2.md
├── quartz.config.ts           ← Quartz 配置
├── quartz.config.ts           ← Quartz 配置
├── .github/workflows/         ← GitHub Actions
│   └── deploy.yml
├── public/                    ← 构建输出（不提交）
└── static/                    ← 静态文件（可选）
```

## 九、有用的命令速查

| 命令                                 | 说明         |
| ---------------------------------- | ---------- |
| `npx quartz build --serve`         | 本地预览       |
| `npx quartz build --clean`         | 清理并构建      |
| `git add . && git commit -m "msg"` | 提交更改       |
| `git push`                         | 推送到 GitHub |

## 十、资源链接

- [Quartz 官方文档](https://quartz.jzhao.xyz/)
- [Obsidian 官网](https://obsidian.md/)
- [GitHub Pages 文档](https://pages.github.com/)

---

_记录日期：2026年4月20日_  
_搭建用时：约 2 小时_
