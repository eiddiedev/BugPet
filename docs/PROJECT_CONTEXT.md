# BugPet Project Context

## What This Project Is

`BugPet` is a native macOS desktop pet app built around coding presence, focus tracking, pet growth, and a lightweight playful companion experience.

BugPet 是一个原生 macOS 桌宠项目，核心方向是：

- coding 专注陪伴
- 宠物成长反馈
- 更轻量的效率激励
- 更有生命感的桌面交互

## Tech Stack

- `Swift`
- `AppKit`
- `SpriteKit`
- `Swift Package Manager`

## Current Product Shape

The app currently includes:

- transparent floating pet window
- always-on-top desktop pet
- drag to move
- frontmost app detection
- idle detection
- coding / focus XP growth
- right-click control panel
- Chinese / English switching
- whitelist management
- dark mode support
- TODO page
- contribution heatmap
- multi-pet selection groundwork
- basic speech bubble and animation system

当前产品已经具备：

- 透明悬浮宠物窗口
- 始终置顶
- 左键拖拽
- 前台应用识别
- 空闲检测
- coding / focus 经验成长
- 右键控制面板
- 中英切换
- 白名单管理
- 深色模式适配
- TODO 页面
- 专注贡献热力图
- 多宠物系统预留
- 基础状态气泡与动画

## Product Tone

BugPet should feel:

- restrained
- playful but not noisy
- friendly
- native
- clean
- a little emotional, but not overly cute

不希望它变成：

- 花哨堆砌
- 过重的 gamification
- 像 AI 模板站那样的泛化设计
- 复杂、拥挤、信息过量的界面

## Packaging Notes

- Local debug builds can keep some developer-only controls.
- Release / packaged builds should be cleaner and hide internal developer controls.
- The app is currently distributed outside the Mac App Store.
- There is currently no Apple Developer notarization / certification yet.

## Why A Separate Website Repo Makes Sense

Keeping the download website separate from the app codebase is recommended because:

- deployment is cleaner
- web iteration is faster
- it avoids mixing AppKit app code with marketing / download pages
- the app repo can stay focused on product development

Recommended structure:

- `BugPet` repository: native app
- `BugPet-Web` repository: official website / download page

## Website Goal

The website is not meant to be a complicated marketing site.

It should be:

- extremely restrained
- minimal
- logo-first
- one large download CTA
- quiet typography
- simple section flow

## Website Content Structure

Desired page order:

1. Hero
2. Features
3. Usage Guide
4. Download Notes
5. Repository / Open Source
6. Developer Panel

## Hero Expectations

The hero should contain:

- BugPet logo
- one large download button
- a very short supporting line

Avoid:

- crowded nav
- multiple competing buttons
- too many cards above the fold
- overly decorative gradients

## Download Notes

This section should clearly explain:

- the app is for macOS
- the project is open source
- the packaged app may trigger system security prompts
- the developer does not currently have Apple Developer certification / notarization
- users may need to manually allow the app in macOS security settings

## Open Source / Community Direction

The project should clearly invite contributions.

Contribution directions include:

- debugging
- adding new pets
- improving interactions
- polishing animation
- improving stats
- refining panel UX

## Planned Future Roadmap

Planned future directions include:

- direct log-based detection
- more comprehensive statistics
- custom pets
- achievement system
- fusion system
- richer interactions
- better animation polish

## Developer Info To Surface

- Name: `Eiddie`
- Feedback email: handled via copy button rather than plain visible text when possible
- GitHub: `https://github.com/eiddiedev/BugPet`

## Suggested Workflow For A New Website Thread

When starting a new thread or a new repo for the website, reuse this context and state:

- this is the official download website for BugPet
- the visual direction is extremely restrained and minimal
- the hero should prioritize logo + a single large download button
- the page sections should follow the structure defined above
- the site should explain the lack of Apple Developer certification clearly but calmly
