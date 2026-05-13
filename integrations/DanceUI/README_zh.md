# DanceUI

DanceUI 是声明式 UI 框架
- 支持复用 SwiftUI 生态
- 兼容性好，最低支持 iOS 13

[English](README.md) | 简体中文

## 环境搭建

建议先创建统一的工作目录，将相关仓库放在同一个 workspace 下。

### 1. 创建 workspace 目录

```bash
mkdir DanceUIWorkSpace
cd DanceUIWorkSpace
```

### 2. 克隆依赖仓库

在 `DanceUIWorkSpace` 目录下执行：

```bash
git clone https://github.com/bytedance/DanceUI
git clone https://github.com/bytedance/DanceUIRuntime
git clone https://github.com/bytedance/DanceUIGraph
```

### 3. 初始化 DanceUI 仓库

进入 `DanceUI` 目录后执行初始化脚本：

```bash
cd DanceUI
bash init.sh
```

### 4. 安装 Example 工程依赖

进入 `Example` 目录后，依次执行：

```bash
cd Example
bundle install
bundle exec pod install
```

完成后即可使用 `Example/DanceUIApp.xcworkspace` 打开示例工程进行开发和调试。

## License

本项目基于 Apache License 2.0 开源，详见 [LICENSE](./LICENSE)。

