#!/bin/bash

# --- 核心脚本自我定位功能 ---
# SCRIPT_DIR: 获取该脚本文件所在的绝对目录路径（例如：/opt/jb_project）。
# 这样无论 'jb' 命令从哪里执行，脚本都能找到其项目根目录。
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET_DIR="$SCRIPT_DIR/nofx"

echo "========================================="
echo "### 自动更新与启动脚本 (jb Command) ###"
echo "========================================="

# 1. 检查并进入 ./nofx 目录
if [ ! -d "$TARGET_DIR" ]; then
    echo "错误：目标目录 $TARGET_DIR 不存在。"
    echo "请确保您已在 $SCRIPT_DIR 目录下将 'nofx' 仓库克隆或放置好。"
    exit 1
fi

echo "--> 1. 切换到项目目录: $TARGET_DIR"
# 切换目录，如果失败则退出
cd "$TARGET_DIR" || { echo "错误：无法进入目录 $TARGET_DIR，请检查权限。"; exit 1; }

# 额外检查：确保当前目录是一个 Git 仓库
if ! git status &> /dev/null; then
    echo "严重错误：$TARGET_DIR 目录不是一个 Git 仓库。请先执行 git init 或 git clone。"
    exit 1
fi

# 2. 执行 git fetch
echo "--> 2. 执行 git fetch 获取最新远程状态..."
git fetch

# 3. 执行 git status 并判断是否有更新
# -uno 选项用于抑制未跟踪文件信息，使输出更简洁
STATUS_OUTPUT=$(git status -uno 2>&1)
UPDATED_REQUIRED=false

# 检查输出中是否包含“Your branch is behind”来判断是否有更新
if echo "$STATUS_OUTPUT" | grep -q "Your branch is behind"; then
    UPDATED_REQUIRED=true
fi


if [ "$UPDATED_REQUIRED" = true ]; then
    # ========================================
    # 情况 A: 发现更新，执行拉取和启动/构建
    # ========================================
    echo "--> 3. 发现更新，执行 git pull..."
    git pull

    if [ $? -ne 0 ]; then
        echo "严重错误：git pull 失败，请手动检查（如合并冲突）。停止后续操作。"
        exit 1
    fi

    echo "--> 4. 更新完成，执行 ./start.sh start --build"
    # 注意：./start.sh 此时在 $TARGET_DIR 目录下
    ./start.sh start --build

    echo "--> 5. 启动完成，运行 ./start.sh logs 查看日志..."
    ./start.sh logs

else
    # ========================================
    # 情况 B: 没有更新，询问是否查看日志
    # ========================================
    echo "--> 3. 本地分支与远程仓库同步，没有发现更新。"
    
    # 询问是否查看日志
    while true; do
        read -r -p "是否查看当前服务的日志 (./start.sh logs)? [Y/n]: " response
        response=${response,,} # 转换为小写

        if [[ "$response" =~ ^(yes|y|)$ ]]; then
            echo "--> 正在运行 ./start.sh logs..."
            ./start.sh logs
            break
        elif [[ "$response" =~ ^(no|n)$ ]]; then
            echo "--> 跳过查看日志。脚本结束。"
            break
        else
            echo "无效输入，请输入 Y 或 n。"
        fi
    done

fi

echo "========================================="
echo "脚本执行完毕。"
