# 本机 Blender 连接速查

先下载并解压本仓库的 [完整包](../../../packages/Codex-Blender-Bridge-full.zip)，将下例中的 `<解压目录>` 换成实际目录。Blender 插件安装在当前 Blender 版本的用户插件目录；端口默认是 `127.0.0.1:9878`，可选 Node 后端默认监听 `127.0.0.1:9887`。不要把本机令牌或第三方服务密钥提交到仓库。

## 启动与探测

在 PowerShell 中：

```powershell
$bridge = '<解压目录>'
python "$bridge\client.py" ping
& "$bridge\start_backend.ps1"
python "$bridge\backend_client.py" doctor --get
```

`doctor` 的 `addon.kind=ok` 才说明 GUI 插件通道健康。无 GUI 时可使用独立 Blender 后台流程，但不要把后台可用误认为当前 GUI 已连接。

## 查询目录后再操作

```powershell
python "$bridge\backend_client.py" plan --body '{"op":"catalog","args":{}}'
python "$bridge\backend_client.py" plan --body '{"op":"catalog","args":{"family":"audit"}}'
python "$bridge\backend_client.py" plan --body '{"op":"audit_help","args":{}}'
python "$bridge\client.py" modeling_modules
python "$bridge\client.py" modeling_catalog --params '{"module":"geo"}'
python "$bridge\client.py" modeling_op --params '{"module":"geo","op":"help","args":{}}'
```

插件的 `modeling_*` 模块入口与后端的 `plan` op 是两个层级，不把它们的数量混算。

## 场景与写操作

```powershell
python "$bridge\client.py" get_scene_info
python "$bridge\client.py" get_selection
python "$bridge\backend_client.py" plan --body '{"op":"audit_scene","args":{"summary_only":true}}'
```

对当前 GUI 场景用后端写路由时，先保存 `.blend`，领取写租约，操作结束后释放；同一任务保持相同的 `holder`。参数复杂时用 `--body-file` 传 JSON 文件，避免命令行转义问题。

```powershell
python "$bridge\backend_client.py" lease --body '{"holder":"codex-modeling","ttlMs":30000}'
python "$bridge\backend_client.py" act --body '{"holder":"codex-modeling","code":"import bpy; print(len(bpy.context.scene.objects))"}'
python "$bridge\backend_client.py" release --body '{"holder":"codex-modeling"}'
```

`frame.png` 是视口图接口。`worker`、`headless`、`job` 等独立流程的参数以当前 `plan catalog` 为准；`isolated:true` 的 worker 不会更新 GUI 场景。

## 核验口径

`ok` 只表示命令执行；验收需看 `verdict/state` 和未分析项目。`degraded` 不等于通过。保存与导出后读回产物，检查对象、尺寸、材质与法线。第三方服务入口需分别配置账号，未经实际调用不得声称生成成功。

