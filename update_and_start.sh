#!/bin/bash

# =========================================================
# 自动更新与启动脚本 (jb Command)
# 功能：检查更新 -> 拉取代码 -> 构建并启动服务 -> 交互式选项
# =========================================================

# --- 配置 ---
TARGET_DIR="/root/nofx"
NOFX_SERVICE_REPO_URL="https://github.com/NoFxAiOS/nofx"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}### 自动更新与启动脚本 (jb Command) ###${NC}"
echo -e "${CYAN}=========================================${NC}"

# --- 辅助函数：交互式菜单 ---
show_interactive_menu() {
    echo -e "\n${YELLOW}--- 请选择下一步操作 ---${NC}"
    PS3="选择序号 (1-2): "
    options=("查看 nofx 服务日志 (./start.sh logs)" "执行 btop 查看系统资源")

    select opt in "${options[@]}" "退出脚本"
    do
        case $opt in
            "查看 nofx 服务日志 (./start.sh logs)")
                echo -e "${YELLOW}--> 正在执行 ./start.sh logs...${NC}"
                # 切换到目标目录执行命令，因为 start.sh 在 nofx 内部
                cd "$TARGET_DIR" || { echo -e "${RED}错误：无法切换到 $TARGET_DIR。${NC}"; exit 1; }
                ./start.sh logs
                break
                ;;
            "执行 btop 查看系统资源")
                echo -e "${YELLOW}--> 正在执行 btop...${NC}"
                btop
                break
                ;;
            "退出脚本")
                echo -e "${GREEN}脚本退出。${NC}"
                break
                ;;
            *) echo "无效选项 $REPLY";;
        esac
    done
}


# --- 1. 检查目录和自动克隆 ---
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}警告：目标目录 ${TARGET_DIR} 不存在。${NC}"
    echo -e "${YELLOW}--> 正在自动克隆 ${NOFX_SERVICE_REPO_URL} 到 ${TARGET_DIR}...${NC}"
    
    # 确保父目录存在
    sudo mkdir -p "$(dirname "$TARGET_DIR")"

    if sudo git clone "$NOFX_SERVICE_REPO_URL" "$TARGET_DIR"; then
        echo -e "${GREEN}克隆成功！${NC}"
        # 克隆成功后，首次运行服务
        cd "$TARGET_DIR" || { echo -e "${RED}错误：无法切换到 $TARGET_DIR。${NC}"; exit 1; }
        echo -e "${YELLOW}--> 首次启动服务并构建: ./start.sh start --build${NC}"
        ./start.sh start --build

        # 首次启动后，询问用户下一步操作
        show_interactive_menu

    else
        echo -e "${RED}错误：自动克隆失败。请检查网络连接、权限或仓库地址。${NC}"
        exit 1
    fi
    exit 0 # 自动克隆流程结束
fi


# --- 2. 检查更新 ---
cd "$TARGET_DIR" || { echo -e "${RED}错误：无法切换到 $TARGET_DIR。${NC}"; exit 1; }

# 确保在 Git 仓库中
if [ ! -d .git ]; then
    echo -e "${RED}错误：${TARGET_DIR} 不是一个 Git 仓库。请检查目录内容。${NC}"
    exit 1
fi

echo -e "${YELLOW}--> 1. 进入 ${TARGET_DIR} 目录，执行 git fetch...${NC}"
sudo git fetch

# 检查是否有新的提交
UPSTREAM='@{u}'
LOCAL=$(sudo git rev-parse @)
REMOTE=$(sudo git rev-parse "$UPSTREAM")
BASE=$(sudo git merge-base @ "$UPSTREAM")

if [ "$LOCAL" = "$REMOTE" ]; then
    # 没有更新
    echo -e "${GREEN}--> 2. [无更新] 本地分支已是最新版本。${NC}"
    
    # 无更新时，执行日志或 btop 选项
    show_interactive_menu
    
elif [ "$LOCAL" = "$BASE" ]; then
    # 有更新
    echo -e "${CYAN}--> 2. [有更新] 检测到新版本，执行 git pull...${NC}"
    if sudo git pull; then
        echo -e "${GREEN}Git Pull 成功！${NC}"
        
        # --- 3. 执行启动命令 ---
        echo -e "${YELLOW}--> 3. 执行启动命令并构建: ./start.sh start --build${NC}"
        ./start.sh start --build
        
        # --- 4. 再次查看日志/btop ---
        show_interactive_menu
    else
        echo -e "${RED}错误：Git Pull 失败。请检查合并冲突或权限。${NC}"
        show_interactive_menu # 失败后也允许查看日志
    fi
    
elif [ "$REMOTE" = "$BASE" ]; then
    # 本地有新的提交，远程没有
    echo -e "${YELLOW}--> 2. [本地有新提交] 请先处理本地更改 (git push)。${NC}"
    show_interactive_menu

else
    # 分支已分叉
    echo -e "${RED}--> 2. [分支分叉] 本地和远程有不同的提交，请手动解决。${NC}"
    show_interactive_menu
fi

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}脚本执行完毕。${NC}"
