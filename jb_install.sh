#!/bin/bash

# -----------------------------------------------------------------
# jb_install.sh - 一键安装脚本
# 用于在任何机器上自动部署 Git 仓库，并创建 'jb' 全局命令
# -----------------------------------------------------------------

# 实际的 GitHub 仓库地址
REPO_URL="https://github.com/laolaoshiren/nofxupdate"
INSTALL_DIR="/opt/jb_project"
CORE_SCRIPT="update_and_start.sh"
WRAPPER_PATH="/usr/local/bin/jb"

echo "========================================="
echo "### jb 自动化安装程序 ###"
echo "========================================="

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本需要 root 权限。请使用 'sudo' 执行。"
    exit 1
fi

# 1. 克隆 Git 仓库
if [ -d "$INSTALL_DIR" ]; then
    echo "警告：目标安装目录 $INSTALL_DIR 已存在。跳过克隆。"
    echo "请手动检查或删除该目录后重试。"
else
    echo "--> 1. 克隆 Git 仓库到 $INSTALL_DIR..."
    # 注意：这里克隆的是整个仓库，包含 update_and_start.sh 和 nofx 文件夹（如果它在仓库中）
    git clone "$REPO_URL" "$INSTALL_DIR"
    if [ $? -ne 0 ]; then
        echo "严重错误：Git 克隆失败。请检查仓库URL和网络连接。"
        exit 1
    fi
    echo "Git 仓库克隆成功。"
fi

# 2. 赋予核心脚本执行权限
echo "--> 2. 赋予核心脚本执行权限..."
chmod +x "$INSTALL_DIR/$CORE_SCRIPT"

# 3. 创建 jb 全局命令包装器 (Wrapper)
echo "--> 3. 创建 'jb' 全局命令 ($WRAPPER_PATH)..."
cat << EOF > "$WRAPPER_PATH"
#!/bin/bash
# 自动生成的 jb 启动包装器
# 切换到项目根目录并执行核心脚本
cd "$INSTALL_DIR"
./$CORE_SCRIPT
EOF

# 4. 赋予包装器执行权限
chmod +x "$WRAPPER_PATH"

echo "========================================="
echo "安装成功！"
echo "项目已安装至: $INSTALL_DIR"
echo "现在您可以在任何地方输入 'jb' 来运行您的脚本了！"
echo "========================================="
