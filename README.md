# codexU-Krill

[English](README.en.md)

codexU-Krill 是一个为个人使用场景定制的 macOS Codex 额度小组件。它优先显示 Krill 中转站余额，同时保留官方 Codex 额度、本机 token 用量、今日任务看板和系统 WidgetKit 小组件。

![codexU-Krill 桌面小组件截图](docs/screenshot.png)

## 主要能力

- **Krill 优先**：默认进入 `中转站` 模式，显示钱包余额、今日请求花费、周额度、套餐额度、到期时间和 API Key 使用摘要。
- **官方额度可切换**：顶部 `中转站 | 官方` 可以切回 Codex 官方 5 小时 / 7 天额度窗口。
- **额度进度条**：中转站周额度和套餐额度都以进度条展示，扫一眼就能知道还能用多少。
- **快捷登录**：Krill 登录态失效时，可从主窗口或系统小组件直接打开内置 Krill 登录窗口。
- **系统 WidgetKit 小组件**：可添加到 macOS 通知中心或桌面，小号显示余额与进度，中号显示余额、周额度、套餐额度、钱包和今日花费。
- **本机统计**：读取本机 Codex SQLite 状态，显示今日、近 7 天和累计 token 用量，以及今日任务看板。
- **桌面常驻**：主窗口默认贴在桌面层，支持 `Command + U` 在桌面层和前台层之间切换。
- **中英双语**：支持中文和英文界面，默认按系统时区判断，也可以手动切换。

## 安装

从 Release 下载 Apple Silicon 版本：

[下载最新 DMG](https://github.com/yym8224961/codexU-Krill/releases/latest)

安装步骤：

1. 打开 `codexU-0.1.5-mac-arm64.dmg`。
2. 将 `codexU.app` 拖到 `Applications`。
3. 从 `Applications` 打开 codexU。
4. 如果 macOS 拦截，进入 **系统设置 > 隐私与安全性**，点击 **仍要打开**。

首次运行后，主 App 会写入系统小组件需要的本机快照。然后可以在 macOS 的 **编辑小组件** 中添加 `codexU`。

## 使用

- `Command + U`：切换桌面层 / 前台层。
- 菜单栏仪表图标：执行同样的窗口切换。
- `中转站 | 官方`：切换 Krill 中转站余额和官方 Codex 额度。
- `中 | EN`：切换界面语言。
- 刷新按钮：立即刷新官方额度、本机统计、任务看板和 Krill 余额。
- 登录按钮：打开 codexU 内置 Krill 登录窗口；登录完成后关闭窗口即可刷新。
- 系统小组件：点击小组件打开主 App；登录态失效时点击 `登录` 打开 Krill 登录窗口。

## 数据来源与隐私

codexU-Krill 只在本机处理数据：

- Krill 中转站余额：来自 codexU 内置 `WKWebView` 中已登录 Krill 网页的可见文字。
- 系统 WidgetKit 小组件：读取主 App 写入的本机快照 `~/Library/Application Support/codexU/widget-snapshot.json`。
- 官方 Codex 额度：读取本机 `codex app-server` 的账户和 rate limit 数据。
- 本机 token 用量：读取 `~/.codex/state_5.sqlite`。
- 今日任务看板：读取本机 Codex 线程和 enabled automations 元数据。

不会做的事：

- 不读取 Chrome / Safari cookie。
- 不读取浏览器保存的密码。
- 不保存或上传 Krill 登录凭证。
- 不自动填写或提交登录表单。
- 不上传 Codex 线程、usage、账户信息或中转站余额。

## 运行要求

- macOS 14 或更新版本。
- Apple Silicon Mac 默认可直接使用 release DMG。
- 已安装并使用过 Codex，以生成本机 `~/.codex/state_5.sqlite`。
- Krill 模式需要在 codexU 内置登录窗口中完成登录。
- 官方模式需要本机 Codex 已登录，才能显示官方额度。
- 从源码构建需要 Xcode Command Line Tools。

## 从源码构建

```sh
make build
```

运行：

```sh
make run
```

检查本机数据源：

```sh
make probe
```

打包 DMG：

```sh
make release
```

产物示例：

```text
dist/codexU-0.1.5-mac-arm64.dmg
dist/codexU-0.1.5-mac-arm64.dmg.sha256
```

## 常见问题

### 为什么系统小组件显示“打开 codexU 刷新”？

WidgetKit 小组件不直接打开网页，也不直接读取 Codex 数据。先启动一次主 App，让它刷新并写入本机快照，小组件就会显示最新数据。

### 为什么要用内置 Krill 登录窗口？

Krill 没有提供当前账号余额的 API 权限，所以这个版本使用 codexU 自己的 `WKWebView` 登录态读取网页可见余额。这样不需要读取浏览器 cookie，也避免接触浏览器保存的密码。

### 这是官方 OpenAI 产品吗？

不是。codexU-Krill 是个人 fork 的本地 macOS 工具，用于查看 Krill 中转站余额和本机 Codex 使用状态。

### 支持 Intel Mac 吗？

默认 release 是 arm64 DMG。Intel Mac 可以从源码构建，或在支持对应 target 的机器上使用：

```sh
TARGET_TRIPLE="x86_64-apple-macos14.0" make release
```

## License

MIT. See [LICENSE](LICENSE).
