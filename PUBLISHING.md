# 以后怎样干净地上传插件或 Skill

仓库按“一套工具一个文件夹”组织。每个文件夹至少有 `README.md`（用途、安装、验证边界）和适用的许可/来源说明；程序、Skill、下载包可以分别放在 `src/`、`skill/`、`packages/`。不要把工作目录、测试缓存、账号配置、令牌、原始私人素材直接复制进来。

## 一条命令

先用 Git 克隆目标仓库并完成该电脑的 GitHub 登录。在**本仓库根目录**打开 PowerShell，复制下面命令，把两个路径改成自己的：

```powershell
.\scripts\publish-plugin.ps1 -Source 'C:\path\to\clean-source' -Name 'my-tool' -RepoPath '.' -Publish
```

不加 `-Publish` 时，脚本只检查并列出将上传的文件，不改动仓库，方便预览：

```powershell
.\scripts\publish-plugin.ps1 -Source 'C:\path\to\clean-source' -Name 'my-tool' -RepoPath '.'
```

脚本会检查工作区是否干净、拒绝常见密钥文件与令牌形态、跳过缓存和依赖目录。带 `-Publish` 时，它将指定来源同步到仓库内的同名文件夹，显示 `git diff --cached --stat`，然后提交并推送。源目录不会被删除。若 GitHub 登录或网络不可用，推送会失败，提交保留在本地，恢复连接后运行 `git push` 即可。

## 发布前自己检查

1. `README` 说明谁能用、怎么安装、实际验证到哪一步；别把“打包成功”写成“所有设备可用”。
2. 第三方代码保留原许可与署名，自己写的内容标清适用范围。当前仓库的 [分享说明](SHARING.md) 不改变上游 MIT/BSD 许可。
3. 压缩包应能解压，路径不含机器用户名或本机配置，依赖版本写清楚；大文件可另放 GitHub Release。
4. 推送后打开 GitHub 仓库，核对目录、下载链接、README 渲染和关键文件大小。只有读回远端结果，才算上传完成。

GitHub 页面里的代码块和单条命令有复制按钮；可以直接复制上面的命令，再替换路径。此脚本需要本机可用的 `git` 和已配置的推送凭据。

