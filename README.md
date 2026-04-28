# InputSwitch

InputSwitch 是一个 macOS 菜单栏应用，用来按前台 App 自动切换键盘输入法。它常驻在菜单栏，菜单保持轻量，规则、默认输入法、开机启动和诊断日志放在设置窗口里管理。

## 功能

- 监听前台 App 变化，并按规则自动切换输入法。
- 自动记忆每个 App 用户最后手动切换到的输入法。
- 支持将 App 标记为“不管理”，或锁定到指定输入法。
- 支持设置全局默认输入法，未命中规则或记忆时使用。
- 支持菜单栏临时暂停 30 分钟。
- 支持开机启动。
- 支持 Debug 日志，记录规则命中、记忆命中、实际切换、程序回流事件和失败原因。

## 规则优先级

当前实现按 App 维度决策，匹配键优先使用 Bundle ID，其次使用 Bundle Path，最后使用可执行文件名。

优先级从高到低：

1. 不管理：保持当前输入法，不写入记忆。
2. 锁定输入法：切到规则指定的输入法，不写入记忆。
3. 自动记忆：切到该 App 上次手动使用的输入法。
4. 默认输入法：没有记忆时切到全局默认输入法。
5. 当前输入法已匹配：不重复切换。

## 菜单栏

菜单栏图标会根据当前输入法显示简短字形，例如 `A`、`拼`、`双`、`五` 或输入法名称首字。

菜单项：

- 当前应用
- 当前输入法
- 忽略当前应用
- 清除此应用记忆
- 暂停 30 分钟 / 恢复自动切换
- 打开设置
- 退出 InputSwitch

## 设置窗口

设置窗口包含 5 个页面：

- 当前状态：查看当前前台 App、默认输入法和规则数量。
- 规则列表：为当前 App 新建“不管理”或“锁定输入法”规则，也可以编辑、删除已有规则。
- 输入法列表：查看系统当前可选键盘输入源，并快速设为默认输入法。
- 通用设置：配置默认输入法和开机启动。
- 日志与诊断：开启 Debug 日志，查看最近运行事件。

## 本地数据

运行时数据保存在当前用户的 Application Support 目录：

```text
~/Library/Application Support/InputSwitch/settings.json
~/Library/Application Support/InputSwitch/memory.json
```

- `settings.json` 保存默认输入法、App 规则、开机启动状态和 Debug 日志开关。
- `memory.json` 保存 App 到输入法 ID 的自动记忆。

如果无法创建 Application Support 目录，应用会回退到系统临时目录，并在诊断日志中记录原因。

## 环境要求

- macOS 13.0 或更高版本
- 完整 Xcode 环境
- XcodeGen 2.42.0 或更高版本
- Swift 6.0

首次构建前建议确认 `xcode-select` 指向完整 Xcode，而不是 Command Line Tools：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcode-select -p
```

安装 XcodeGen：

```bash
brew install xcodegen
```

## 构建

生成 Xcode 工程：

```bash
xcodegen generate
```

编译：

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

测试：

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
```

## 运行

打开 Debug 产物：

```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -path '*Build/Products/Debug/InputSwitch.app' -print -quit)"
```

启动后应能在菜单栏看到 InputSwitch 图标。因为 `project.yml` 中配置了 `LSUIElement: true`，应用不会显示 Dock 图标。

## 权限

应用会检测辅助功能权限，并在诊断日志中显示当前授权状态。

如果前台 App 识别、输入法监听或自动切换异常，先检查：

1. `系统设置 -> 隐私与安全性 -> 辅助功能` 中是否允许 InputSwitch。
2. 是否运行的是最新构建出的 `InputSwitch.app`。
3. 系统键盘输入源中是否启用了目标输入法。
4. 诊断页是否有“目标输入法已不可用”或“切换输入法失败”等日志。

## 开机启动

“开机启动”通过 macOS 登录项接入。切换后可在：

```text
系统设置 -> 通用 -> 登录项
```

确认 InputSwitch 是否已加入或等待系统批准。

## 手动验证

1. 执行 `xcodegen generate`。
2. 执行完整测试：`xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test`。
3. 打开 Debug 产物，确认菜单栏图标出现。
4. 从菜单打开设置窗口，确认 5 个设置页面可正常切换。
5. 在“输入法列表”设置默认输入法。
6. 切到目标 App，手动切换一次输入法，再切走并切回，确认自动记忆生效。
7. 在“规则列表”为当前 App 设置“锁定输入法”，切走并切回，确认优先使用锁定规则。
8. 将当前 App 标记为“不管理”，再次切回该 App，确认不会自动切换，也不会写入新记忆。
9. 开启 Debug 日志，重复一次 App 切换，确认诊断页能看到规则命中和切换记录。
10. 使用菜单“暂停 30 分钟”，切换 App 时确认自动切换暂时停止；恢复后再次确认自动切换生效。

## 常见问题

### `xcodebuild` 提示找不到平台或 SDK

通常是当前机器只选择了 Command Line Tools。切到完整 Xcode 后重新生成工程：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodegen generate
```

### 菜单栏没有图标

确认已经打开 Debug 产物中的 `InputSwitch.app`，并检查系统是否拦截了未签名或本地构建的应用。也可以在“活动监视器”中确认 `InputSwitch` 进程是否存在。

### 没有自动切换输入法

优先检查是否处于暂停状态、当前 App 是否被标记为“不管理”、目标输入法是否仍在系统输入源列表中，以及 Debug 日志中是否有切换失败记录。

### 规则看起来没有生效

规则按匹配键保存。正常情况下优先使用 `bundle:<bundle id>`，如果 App 没有 Bundle ID，才会退到 `path:<bundle path>` 或 `exec:<executable name>`。可以在规则列表中查看每条规则的完整键。

## License

MIT License. See [LICENSE](./LICENSE).
