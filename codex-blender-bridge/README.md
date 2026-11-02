# Codex Blender Bridge + 建模工作流

这一套由三层组成：

1. **Blender 插件**：在 Blender 的 N 面板提供连接、选区、暂停 AI 写操作和第三方素材服务设置；本机端口为 `127.0.0.1:9878`。
2. **可选 Node 后端与 Python 客户端**：把建模目录、操作、审计、视口画面、后台任务等能力提供给本机 Codex 工作流；后端监听 `127.0.0.1:9887`。
3. **[Blender 建模工作流 Skill](skill/blender-modeling-workflow/SKILL.md)**：规定从参考、规格、建模、检查到交付的步骤。Skill 本身不执行建模，需配合本机工具。

## 下载

- [完整包](packages/Codex-Blender-Bridge-full.zip)：插件、后端、客户端与许可文件。需要完整建模工具链时使用。
- [仅插件包](packages/Codex-Blender-Bridge-addon.zip)：只有 Blender 插件。适合只使用 Blender 面板和插件内建模模块的情况。
- [Skill 压缩包](packages/blender-modeling-workflow-skill.zip)：可安装的 Skill，已将原本针对单台电脑的绝对路径改为通用说明。

## 安装与调用

1. 安装 Blender 5.2 系列。把 `codex_blender_bridge` 文件夹安装到该版本的 Blender 用户插件目录，在 Blender 首选项中启用它。打开 3D 视图，按 `N`，选择 **Codex Blender Bridge**。
2. 完整包还需要 Node.js 24.9 或更新版本。保留完整包的目录结构，在解压目录运行 `powershell -File .\start_backend.ps1`。后端读取插件生成的本机令牌；不需要把令牌粘贴到聊天或命令行。
3. 将 `blender-modeling-workflow` 文件夹放进 Codex 的 Skills 目录，按 [本机连接说明](skill/blender-modeling-workflow/references/local-bridge.md) 配置解压路径。安装 Skill 不会自动安装插件或启动后端。
4. 先运行 `python client.py ping` 和 `python backend_client.py doctor --get` 检查连接；再查询 `plan catalog` 与相应 `*_help`，按当前版本的参数调用。写入当前 GUI 场景前保存 `.blend`，后端写操作使用租约。

## 来源、授权与验证边界

插件改编自 [sixtysevenlf/dsh-blender-plugin v3.0.3](https://github.com/sixtysevenlf/dsh-blender-plugin)，其 Blender 侧代码继承 [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp) 的 MIT 许可；建模运行库和后端继承上游 BSD-3-Clause。完整许可和署名保留在压缩包内，也可在 [授权说明](LICENSES.md) 查看。

此前在一台 Windows 机器的 Blender 5.2.3 LTS 中，已核验插件 GUI、连接、选区、暂停写入、`geo.box`、场景读取、视口截图、`doctor`、`plan catalog`、`lease → act → release` 和独立 worker 启停。此处上传的是该次交付的源码包；**未在另一台机器上完成全新安装验收**。第三方 Poly Haven、Sketchfab、Poly Pizza、Hyper3D 和混元入口需要各自账号或服务条件，未验证其付费或实际生成效果。

本仓库原创 Skill 和说明文档按[免费分享与使用说明](../SHARING.md)提供：允许个人自用和学习，商业使用、转卖和付费教学需另获许可。插件及运行库中的上游 MIT/BSD 代码仍按其原许可使用。

`execute_code` 能运行任意 Blender Python；只在可信本机使用客户端和令牌文件。默认监听回环地址，不要直接暴露端口到公网。

