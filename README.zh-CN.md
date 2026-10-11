# SpeedPeek

轻量 macOS 菜单栏网速工具：上行在上（↑），下行在下（↓）。保留本地 MenuMeter v0.2 的双行显示和采样逻辑，使用 Swift 与系统框架，无第三方包依赖。

## 速率与覆盖范围

每 2 秒采样处于活动状态的硬件以太网/Wi-Fi 网卡，按实际时间间隔计算并合计；约每 30 秒及唤醒后刷新网卡列表。K/s、M/s、G/s 是十进制字节/秒，1 K = 1,000 字节，不是比特/秒或 KiB/s。统计包含 macOS 网卡计数器记录的协议开销。

排除回环、桥接、AWDL、VPN 隧道等虚拟接口，VPN 在物理连接上产生的流量仍统计。它不是应用级流量统计或互联网测速器，多物理接口流量会相加。首次采样、新接口、计数器复位和睡眠间隔重新建立基线，首次显示横线。

## 编译与测试

需 macOS、提供 `xcrun swiftc` 的 Apple Command Line Tools，以及用于图标封装的 Python 3。实际使用 Apple Swift 6.4 / macOS SDK 27.0。

```sh
zsh build.sh
```

生成 `SpeedPeek.app`，执行采样/格式测试、渲染纯应用预览图、校验 plist 与临时签名。构建不下载依赖。默认本机架构，`ARCH=x86_64 zsh build.sh` 可交叉编译 Intel 版本，`ARCH=arm64 zsh build.sh` 编译 Apple silicon 版本；后一次构建覆盖本地 App。构建步骤可重复，但不同工具链不保证逐字节相同。

部署目标为 **macOS 13.0**，因为使用 SMAppService。编译、单元测试与渲染在 **Apple silicon（arm64）、macOS 27.0.1** 通过；用户桌面实测确认可启动、上传在上且下载在下，并可正常退出。Intel 交叉编译通过，但 Intel 运行、macOS 13 运行以及此应用标识下的登录注册尚未验证。最低部署目标不代表在全部系统版本上实测通过。

## 安装、自启动与卸载

打开构建的 App 即可试用。若需自启动，将其安装到 `/Applications/SpeedPeek.app` 后主动勾选 **Launch at Login**。通过系统 SMAppService 注册，必要时在系统设置 → 通用 → 登录项批准。候选目录中的 App 禁止注册；默认不自动启用。

无需管理员、辅助功能、录屏、完全磁盘访问、抓包或网络扩展权限。应用没有沙盒，只读取本地网卡计数器，无遥测、更新检查、主动网络请求或持久流量日志；登录偏好保存在自己的 UserDefaults 域。

卸载时先取消自启动、退出，再移除 App；残留登录条目可在系统设置中移除或停用。退出后可选清理偏好：

```sh
defaults delete org.speedpeek.app
```

本地候选仅有 ad-hoc 临时签名，没有 Developer ID 签名和公证；网络下载的二进制可能被 Gatekeeper 拦截。仓库仅分发源码，不提供 App 下载 Release。

## 从 MenuMeter 切换

应用标识为 `org.speedpeek.app`，与旧应用独立。偏好域和登录注册相互独立，不自动迁移。用户决定切换后，在旧 App 取消自启动并退出，再安装新 App、重新选择自启动，否则可能同时出现两个工具。本次构建及测试不修改旧 App 或其登录项。

源码采用 [MIT](LICENSE)，版权署名为 SpeedPeek contributors，来源与依赖说明见 [PROVENANCE.md](PROVENANCE.md)。当前版本为 v0.2 build 3。完整源码结构见 [英文 README](README.md)。

反馈请使用 [GitHub Issues](https://github.com/KnickTaoTao/SpeedPeek/issues)，不要附带凭据或私人日志。
