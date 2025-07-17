# EnvManager

EnvManager 是一个用于命令行中快速切换和管理临时环境变量组的工具。

## 特点

- **预设管理**: 将常用的环境变量组合成预设，方便一键切换。
- **临时生效**: 环境变量仅在当前 Shell 会话中生效，退出后自动恢复。
- **易于配置**: 使用简单的 JSON 文件进行配置，并支持在不同项目间切换配置文件。
- **无缝集成**: 通过一个简单的 Shell 函数，提供类似 `emanager use my-preset` 的原生体验，无需手动执行 `eval`。

## 安装

### 快速安装 (推荐)

我们提供了一个安装脚本来自动化整个过程。

1.  **克隆项目**:
    ```bash
    git clone <repository_url>
    cd EnvManager
    ```

2.  **运行安装脚本**:
    该脚本会自动编译项目、安装可执行文件并配置您的 Shell。
    ```bash
    chmod +x install.sh
    ./install.sh
    ```

3.  **重载 Shell**:
    安装完成后，根据脚本的提示，重启您的终端或运行 `source ~/.zshrc` (或 `~/.bashrc`) 即可开始使用。

### 手动安装

如果您想手动控制安装过程，请遵循以下步骤：

1.  **编译项目**:
    克隆本项目后，在项��根目录运行以下命令进行编译。
    ```bash
    cargo build --release
    ```
    编译后的可执行文件将位于 `./target/release/emanager`。

2.  **移动到 PATH**:
    为了在任何地方都能方便地使用 `emanager` 命令，请将其移动到一个包含在您系统 `PATH` 环境变量中的目录。一个常见的选择是 `/usr/local/bin`。
    ```bash
    sudo mv ./target/release/emanager /usr/local/bin/
    ```

3.  **配置 Shell**:
    这是最关键的一步。为了让 `emanager use` 和 `emanager clear` 能够影响您当前的 Shell 环境，需要将以下函数添加到您的 Shell 配置文件中。

    - 如果您使用 **Zsh** (macOS 默认)，请添加到 `~/.zshrc` 文件：
    - 如果您使用 **Bash**，请添加到 `~/.bashrc` 或 `~/.bash_profile` 文件：

    ```bash
    # emanager shell integration
    emanager() {
      case "$1" in
        use|clear)
          eval "$(command emanager "$@")"
          ;;
        *)
          command emanager "$@"
          ;;
      esac
    }
    ```

4.  **重载配置**:
    打开一个新的终端窗口，或者在当前窗口中运行以下命令使配置生效：
    ```bash
    # for Zsh
    source ~/.zshrc

    # for Bash
    source ~/.bashrc
    ```

## 使用方法

### 1. 创建第一个预设

```bash
# 添加一个名为 "project1" 的预设，并设置两个环境变量
emanager add project1 API_KEY=abc-123-xyz ENDPOINT=https://api.project1.dev
```
这会自动在 `~/.config/emanager/presets.json` 创建文件并保存您的预设。

### 2. 切换和清除环境

```bash
# 激活 project1 的环境变量
emanager use project1

# 验证一下
echo $API_KEY 
# > abc-123-xyz

# 清除由 emanager 设置的所有变量
emanager clear

# 再次验证
echo $API_KEY
# > (输出为空)
```

### 3. 管理预设

```bash
# 列出所有可用的预设
emanager list

# 显示 "project1" 预设的详细内容
emanager show project1

# 向 "project1" 预设中添加或更新一个变量
emanager add project1 DEBUG=true

# 删除 "project1" 预设
emanager remove project1
```

### 4. 管理配置文件

如果您希望为不同项目使用不同的预设文件，可以管理配置文件的路径。

```bash
# 查看当前使用的预设文件路径
emanager config get-path

# 将预设文件指向一个新的路径 (支持相对路径和绝对路径)
emanager config set-path ~/Documents/my-other-project/env.json
```
