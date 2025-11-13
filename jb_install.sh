#!/bin/bash

# =========================================================
# jb 自动化安装程序
# 目标：将 update_and_start.sh 部署到 /opt/jb_project/
# 并创建全局 jb 命令。集成环境依赖检查与安装。
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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}### jb 自动化安装程序 (含依赖安装) ###${NC}"
echo -e "${CYAN}=========================================${NC}"

# 确保APT缓存是最新的
echo -e "${YELLOW}--> 正在更新 APT 包列表...${NC}"
sudo apt update

# --- 依赖检查与安装 ---
# 检查是否为 Debian/Ubuntu 系统
if ! command -v apt &> /dev/null; then
    echo -e "${RED}错误：本安装脚本仅支持使用 'apt' 的系统 (Debian/Ubuntu)。${NC}"
    exit 1
fi

# 1. 检查并安装 Git
if ! command -v git &> /dev/null
then
    echo -e "${YELLOW}--> Git 未安装。正在安装 Git...${NC}"
    sudo apt install -y git
else
    echo -e "${GREEN}--> Git 已安装。${NC}"
fi

# 2. 检查并安装 Docker (使用官方一键脚本)
if ! command -v docker &> /dev/null
then
    echo -e "${YELLOW}--> Docker 未安装。正在使用官方脚本安装 Docker...${NC}"
    # 官方推荐安装方式
    curl -fsSL https://get.docker.com | bash
    # 注意：安装后需要重启或手动将当前用户添加到 docker 组 (本次安装使用 sudo)
    echo -e "${GREEN}Docker 安装完成。可能需要重新登录或重启才能使当前用户无 sudo 使用 docker 命令。${NC}"
else
    echo -e "${GREEN}--> Docker 已安装。${NC}"
fi

# 3. 检查并安装 btop (用于系统监控)
if ! command -v btop &> /dev/null
then
    echo -e "${YELLOW}--> btop 未安装。正在安装 btop...${NC}"
    sudo apt install -y btop
else
    echo -e "${GREEN}--> btop 已安装。${NC}"
fi


# --- 部署核心脚本 ---

# 1. 确保安装目录存在
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}--> 正在创建安装目录 ${INSTALL_DIR}...${NC}"
    sudo mkdir -p "$INSTALL_DIR"
else
    echo -e "${YELLOW}--> 目录 ${INSTALL_DIR} 已存在。将进行覆盖更新。${NC}"
fi

# 2. 从 GitHub 下载并更新核心脚本
echo -e "${YELLOW}--> 正在从 GitHub 下载最新核心脚本并覆盖更新...${NC}"
DOWNLOAD_URL="${REPO_URL}/${SCRIPT_NAME}"
TARGET_FILE="${INSTALL_DIR}/${SCRIPT_NAME}"

# 使用 curl 下载文件到目标路径
if sudo curl -fsSL "$DOWNLOAD_URL" -o "$TARGET_FILE"; then
    echo -e "${GREEN}下载成功。${NC}"
else
    echo -e "${RED}错误：下载脚本失败。请检查网络或仓库地址。${NC}"
    exit 1
fi

# 3. 赋予执行权限
echo -e "${YELLOW}--> 赋予核心脚本执行权限...${NC}"
sudo chmod +x "$TARGET_FILE"

# 4. 创建或更新全局命令软链接
if [ ! -f "$JB_COMMAND_PATH" ] || [ ! -L "$JB_COMMAND_PATH" ]; then
    echo -e "${YELLOW}--> 创建 'jb' 全局命令 (${JB_COMMAND_PATH})...${NC}"
    # 创建软链接
    sudo ln -sf "$TARGET_FILE" "$JB_COMMAND_PATH"
else
    echo -e "${YELLOW}--> 'jb' 全局命令已存在，已确保链接指向最新脚本。${NC}"
fi

# 5. 提示完成
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}安装/更新成功！${NC}"
echo -e "项目已安装至: ${INSTALL_DIR}"
echo -e "现在您可以在任何地方输入 '※※${RED}jb${NC}※※' 来运行您的脚本了！"
echo -e "========================================="
