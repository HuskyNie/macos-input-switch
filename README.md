# InputSwitch

## Setup

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
brew install xcodegen
xcodegen generate
```

## Build

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' build
```

## Test

```bash
xcodebuild -project InputSwitch.xcodeproj -scheme InputSwitch -destination 'platform=macOS' test
```
