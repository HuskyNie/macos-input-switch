# InputSwitch

## Setup

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
brew install xcodegen
xcodegen generate
```

## Run

```bash
open "$(find ~/Library/Developer/Xcode/DerivedData -path '*Build/Products/Debug/InputSwitch.app' -print -quit)"
```

## Build

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

## Test

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
```

## Permissions And Login Item

- 首次运行后应看到菜单栏图标 `⌨︎`。
- 如果前台应用切换或输入法检测异常，请先确认 macOS 没有拦截应用运行；当前诊断页会显示辅助功能权限状态。
- “开机启动” 通过系统登录项接入，切换后可在 `系统设置 -> 通用 -> 登录项` 中确认。

## Manual Verification

1. 运行 `xcodegen generate` 和完整测试后，打开 Debug 产物中的 `InputSwitch.app`。
2. 确认菜单栏图标出现，并能从菜单打开设置窗口。
3. 在不同前台应用之间切换，确认应用会切到记忆中的输入法，或切到锁定规则指定的输入法。
4. 将当前应用标记为“不管理”后再次切回该应用，确认不会再触发自动切换。
