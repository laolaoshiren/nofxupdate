#!/bin/bash

# =========================================================
# jb 自动化安装程序 (Integrated Setup & Updater)
# 目标：部署核心脚本，设置全局 'jb' 命令，并安装依赖。
# =========================================================

# --- 配置 ---
REPO_URL="https://raw.githubusercontent.com/laolaoshiren/nofxupdate/main"
INSTALL_DIR="/opt/jb_project"
SCRIPT_NAME="update_and_start.sh"
JB_COMMAND_PATH="/usr/local/bin/jb"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "========================================="
echo -e "### jb 自动化安装程序 (v2.0) ###"
echo -e "========================================="

# 依赖检查和安装函数 (适用于 Debian/Ubuntu)
install_dependency() {
    local package_name=$1
    echo -e "${YELLOW}--> 正在检查依赖: ${package_name}...${NC}"
    if ! command -v "$package_name" &> /dev/null; then
        echo -e "${YELLOW}--- ${package_name} 未安装。正在尝试安装... ---${NC}"
        if ! sudo apt update -y; then
            echo -e "${RED}错误：apt update 失败。请检查网络。${NC}"
            exit 1
        fi
        if ! sudo apt install -y "$package_name"; then
            echo -e "${RED}错误：安装 ${package_name} 失败。请尝试手动安装。${NC}"
            exit 1
        fi
        echo -e "${GREEN}--- ${package_name} 安装成功。 ---${NC}"
    else
        echo -e "${GREEN}--> ${package_name} 已安装。${NC}"
    fi
}

# 1. 安装核心依赖
install_dependency "git"
install_dependency "docker.io"
install_dependency "btop"

# 2. 确保安装目录存在
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}--> 正在创建安装目录 ${INSTALL_DIR}...${NC}"
    sudo mkdir -p "$INSTALL_DIR"
else
    echo -e "${YELLOW}--> 目录 ${INSTALL_DIR} 已存在。将进行覆盖更新。${NC}"
fi

# 3. 从 GitHub 下载并更新核心脚本 (update_and_start.sh)
echo -e "${YELLOW}--> 正在从 GitHub 下载最新脚本并覆盖更新...${NC}"
DOWNLOAD_URL="${REPO_URL}/${SCRIPT_NAME}"
TARGET_FILE="${INSTALL_DIR}/${SCRIPT_NAME}"

if sudo curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_FILE"; then
    echo -e "${GREEN}下载成功。${NC}"
else
    echo -e "${RED}错误：下载脚本失败。请检查网络或仓库地址。${NC}"
    exit 1
fi

# 4. 赋予执行权限
echo -e "${YELLOW}--> 赋予核心脚本执行权限...${NC}"
sudo chmod +x "$TARGET_FILE"

# 5. 创建或更新全局命令软链接
if [ ! -f "$JB_COMMAND_PATH" ] || [ ! -L "$JB_COMMAND_PATH" ]; then
    echo -e "${YELLOW}--> 创建 'jb' 全局命令 (${JB_COMMAND_PATH})...${NC}"
    # 创建软链接
    sudo ln -sf "$TARGET_FILE" "$JB_COMMAND_PATH"
else
    echo -e "${YELLOW}--> 'jb' 全局命令已存在，已确保链接指向最新脚本。${NC}"
fi

# 6. 提示完成
echo -e "========================================="
echo -e "${GREEN}安装/更新成功！${NC}"
echo -e "项目已安装至: ${INSTALL_DIR}"
echo -e "现在您可以在任何地方输入 'jb' 来运行您的脚本了！"
echo -e "========================================="
