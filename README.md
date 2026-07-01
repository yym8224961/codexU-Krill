# codexU

[English](README.en.md)

codexU 是一个 macOS 桌面小组件，用来查看中转站余额、OpenAI Codex / ChatGPT Codex 的额度窗口、token 用量和今日任务状态。它把常用信息放在桌面上，帮助你快速判断剩余额度、重置时间和当天工作进展。

![codexU 桌面小组件截图](docs/screenshot.png)

## 适合谁

- 经常使用 OpenAI Codex、Codex CLI 或 Codex 桌面应用的开发者。
- 使用 Krill 等中转站，并希望优先查看中转站钱包、套餐和今日花费的人。
- 需要快速查看 5 小时/7 天额度、token 用量和重置时间的 ChatGPT Pro / Team 用户。
- 想在桌面查看 Codex 使用状态、减少反复打开浏览器或终端的人。

## 功能

- 默认显示中转站余额，可通过顶部 `中转站 | 官方` 切换到官方 Codex 额度。
- 中转站模式读取 codexU 自己的 Krill 网页登录态，显示钱包余额、套餐额度、今日请求花费和 API Key 使用摘要。
- 中转站模式提供快捷登录入口，会打开内置 Krill 登录窗口，方便登录态失效后重新登录。
- 展示 Codex 5 小时和 7 天额度的剩余比例、已用比例和重置时间。
- 汇总今日、近 7 天和累计 token 用量，并显示 7 天使用趋势。
- 从本机 Codex 线程和启用中的 automations 生成今日任务看板。
- 按进行中、待处理、定时、完成四类组织任务。
- 默认贴在桌面层，支持 `Command + U` 一键唤到前台。
- 支持中文和英文界面，可根据系统时区自动选择，也可通过顶部 `中 | EN` 手动切换。
- 本地读取数据，不上传 usage、线程或账户数据到第三方服务。

## 快捷键和操作

- `Command + U`：在桌面层和前台层之间切换小组件。
- 菜单栏仪表图标：点击后执行和 `Command + U` 相同的切换操作。
- 顶部 `中 | EN`：切换中文或英文界面，手动选择会在下次启动时保留。
- 顶部 `中转站 | 官方`：切换中转站余额和官方 Codex 额度，默认使用中转站模式。
- 中转站模式的登录按钮：打开内置 Krill 登录窗口；登录完成后关闭窗口并刷新。
- 右上角刷新按钮：立即刷新额度、token 统计、趋势图和任务看板。
- 右上角关闭按钮：退出 codexU。
- 拖动小组件背景：移动小组件位置。

## 首次安装：隐私与安全

codexU 目前通过 GitHub Release 的 DMG 安装包分发，不经过 Mac App Store。第一次打开时，macOS 可能会拦截，需要手动允许：

1. 打开 `codexU.app` 一次。如果系统提示无法打开，先取消弹窗。
2. 打开 **系统设置 > 隐私与安全性**。
3. 在 **安全性** 区域找到 `codexU.app`，点击 **仍要打开**。
4. 使用 Touch ID 或密码确认，然后点击 **打开**。

也可以在 Finder 中右键点击 `codexU.app`，选择 **打开**，再确认系统安全提示。

codexU 需要读取本机 `~/.codex/` 下的 Codex 数据。如果 macOS 弹出文件或文件夹访问授权，请允许访问，否则小组件无法读取本机 usage、线程和自动化任务信息。

中转站模式使用 codexU 内置的 `WKWebView` 打开 Krill 网页并读取可见余额文字。codexU 不读取 Chrome cookie、浏览器保存的密码，也不会自动填写或提交登录表单。

## 安装

从 GitHub Release 下载最新的 `codexU-<version>-mac-arm64.dmg`：

1. 打开 DMG。
2. 将 `codexU.app` 拖到 `Applications` 文件夹。
3. 从 `Applications` 打开 codexU。
4. 按上面的 **首次安装：隐私与安全** 步骤完成手动放行。

## 运行要求

- macOS 14 或更新版本。
- 本机已安装 Codex。
- 中转站模式需要在 codexU 内置 Krill 登录窗口中完成登录。
- 官方模式需要已登录 Codex 账户，额度信息才会显示。
- Codex 至少使用过一次，以便生成 `~/.codex/state_5.sqlite`。
- 从源码构建时需要 Xcode Command Line Tools。

## 从源码构建

```sh
make build
```

运行：

```sh
make run
```

安装到 `/Applications`：

```sh
make install
```

检查本机数据源输出：

```sh
make probe
```

## 打包 DMG

```sh
make release
```

产物会写入 `dist/`，例如：

```text
dist/codexU-0.1.4-mac-arm64.dmg
dist/codexU-0.1.4-mac-arm64.dmg.sha256
```

Developer ID 签名和 Apple notarization 流程见 [DISTRIBUTION.md](DISTRIBUTION.md)。

## 数据来源

- 中转站余额：codexU 内置 `WKWebView` 中已登录的 Krill 网页可见文本。
- 账户与额度：`codex app-server` 的 `account/read`、`account/rateLimits/read`、`account/usage/read`。
- 本机 token 用量：`~/.codex/state_5.sqlite`。
- 今日任务看板：本机 SQLite 中未归档和今日归档的 Codex 线程。
- 定时任务：`~/.codex/automations/**/automation.toml` 中启用的 automation 元数据。

当前 Codex 额度 API 暴露的是滚动窗口百分比和重置时间，不暴露绝对配额数量。更完整的数据口径和回退策略见 [RESEARCH.md](RESEARCH.md)。

## 常见问题

### codexU 是官方 OpenAI 产品吗？

不是。codexU 是一个非官方的本地 macOS 工具，用于读取本机 Codex app-server 和本机 `~/.codex/` 数据。

### codexU 会上传我的 Codex 线程、usage 或中转站数据吗？

不会。codexU 只在本机读取 Codex 账户额度、本机 SQLite usage、automation 元数据和内置 Krill 网页中的可见余额文字，不把这些数据上传到第三方服务。

### codexU 会读取我的 Chrome 登录态吗？

不会。中转站模式不读取 Chrome cookie、浏览器本地存储或保存的密码。快捷登录入口打开的是 codexU 自己的内置 Krill 登录窗口。

### 为什么显示的是剩余百分比，而不是绝对额度？

当前 Codex 本地 API 暴露的是滚动窗口已用百分比和重置时间，不暴露绝对额度数量，所以 codexU 展示的是 5 小时和 7 天窗口的剩余百分比。

### 支持 Intel Mac 吗？

默认 release 是 Apple Silicon / arm64 DMG。Intel Mac 可以从源码构建，或在支持对应 target 的机器上使用 `TARGET_TRIPLE="x86_64-apple-macos14.0"` 打包。

## License

MIT. See [LICENSE](LICENSE).
