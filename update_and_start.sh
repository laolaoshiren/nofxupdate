#!/bin/bash

# --- 配置 ---
# 您的脚本仓库地址
REPO_URL="https://github.com/laolaoshiren/nofxupdate"
# 安装脚本的目标目录
INSTALL_DIR="/opt/jb_project"
# 核心脚本名称
SCRIPT_NAME="update_and_start.sh"

echo "========================================="
echo "### jb 自动化系统安装脚本 ###"
echo "========================================="

# 1. 检查是否已经安装
if [ -d "$INSTALL_DIR" ]; then
    echo "警告：目录 $INSTALL_DIR 已存在。将尝试更新 jb 脚本..."
    cd "$INSTALL_DIR" || exit 1
    # 尝试更新脚本仓库本身
    git pull || echo "更新脚本失败，可能不是 Git 仓库或存在冲突。请手动检查。"
else
    # 2. 克隆脚本仓库
    echo "--> 正在克隆 jb 脚本仓库到 $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo "错误：克隆仓库失败。请检查 Git 是否安装以及网络连接。"
        exit 1
    fi
    cd "$INSTALL_DIR"
fi

# 3. 赋予执行权限
echo "--> 赋予 $SCRIPT_NAME 执行权限..."
chmod +x "$SCRIPT_NAME"

# 4. 创建全局 jb 命令
WRAPPER_PATH="/usr/local/bin/jb"
echo "--> 正在创建全局命令 $WRAPPER_PATH..."

# 创建一个简单的包装脚本，确保无论在哪里执行，都能正确找到主脚本并切换到正确的目录
echo '#!/bin/bash' > "$WRAPPER_PATH"
echo "cd $INSTALL_DIR && ./$SCRIPT_NAME \"\$@\"" >> "$WRAPPER_PATH"

chmod +x "$WRAPPER_PATH"

# 5. 提示用户完成安装
echo "-----------------------------------------"
echo "✅ jb 自动化系统脚本安装成功！"
echo ""
echo "### 下一步重要操作 ###"
echo "脚本期望在 $INSTALL_DIR/nofx 目录下找到您的服务代码。"
echo "请手动将您的 'nofx' 服务代码克隆到该路径："
echo ""
echo "1. 切换到项目目录："
echo "   cd $INSTALL_DIR"
echo ""
echo "2. 克隆您的服务代码 (请替换 [您的 NOFX 服务仓库地址])："
echo "   git clone [您的 NOFX 服务仓库地址] nofx"
echo ""
echo "部署完成后，即可在任何位置运行命令："
echo "   jb"
echo "-----------------------------------------"
