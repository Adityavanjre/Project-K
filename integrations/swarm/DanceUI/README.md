# DanceUI

DanceUI is a declarative UI framework.

- Reuses the SwiftUI ecosystem
- Broad compatibility, with a minimum deployment target of iOS 13

English | [简体中文](README_zh.md)

## Environment Setup

It is recommended to create a shared workspace directory and place the related repositories under the same workspace.

### 1. Create a Workspace Directory

```bash
mkdir DanceUIWorkSpace
cd DanceUIWorkSpace
```

### 2. Clone the Required Repositories

Run the following commands inside `DanceUIWorkSpace`:

```bash
git clone https://github.com/bytedance/DanceUI
git clone https://github.com/bytedance/DanceUIRuntime
git clone https://github.com/bytedance/DanceUIGraph
```

### 3. Initialize the DanceUI Repository

Enter the `DanceUI` directory and run the initialization script:

```bash
cd DanceUI
bash init.sh
```

### 4. Install Dependencies for the Example Project

Enter the `Example` directory and run:

```bash
cd Example
bundle install
bundle exec pod install
```

After that, you can open `Example/DanceUIApp.xcworkspace` to develop and debug the example project.

## License

This project is open-sourced under the Apache License 2.0. See [LICENSE](./LICENSE) for details.
