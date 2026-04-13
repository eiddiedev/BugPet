# BugPet Native MVP

`BugPet` 已迁移为原生 macOS 最小桌宠版本，当前技术栈是：

- `Swift`
- `AppKit`
- `SpriteKit`

当前 MVP 包含：

- 透明悬浮窗
- 始终置顶
- 左键拖拽宠物
- 前台应用名称检测
- 系统空闲检测
- 简单状态机：`idle / focused / chaotic`
- 中英切换右键菜单
- 宠物待机动画
- 随状态变化的气泡文案

## 运行

在仓库目录执行：

```bash
swift run BugPet
```

如果只是先编译检查：

```bash
swift build
```

## 当前结构

```text
Package.swift
Sources/BugPetNative/
  Main.swift
  AppDelegate.swift
  PetCoordinator.swift
  PetWindowController.swift
  PetRootView.swift
  PetScene.swift
  PetSpriteView.swift
  SpeechBubbleView.swift
  ActivityMonitor.swift
  PetStateEngine.swift
  SpeechCatalog.swift
  PreferencesStore.swift
  Resources/
```

## 说明

- 当前是“原生最小闭环”，暂时只保留一只基础宠物。
- 旧的 `Tauri + React` 代码已从仓库移除。
- 由于这台机器当前只有 Command Line Tools，没有完整 Xcode，所以现在采用 `Swift Package Manager` 方式运行原生桌宠。

## 后续适合继续加的能力

- 不规则命中 / 更细的点击穿透
- 多宠物与资源配置
- 宠物成长系统
- 日志读取与会话解析
- 更完整的交互动画与待机动画
