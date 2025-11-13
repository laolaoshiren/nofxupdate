#!/bin/bash

# =========================================================
# 自动更新与启动脚本 (jb Command)
# 目标：进入 /root/nofx 目录，检查更新，执行构建和启动。
# =========================================================

# --- 配置 ---
TARGET_DIR="/root/nofx"
NOFX_SERVICE_REPO_URL="https://github.com/NoFxAiOS/nofx"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "========================================="
echo -e "### 自动更新与启动脚本 (jb Command) ###"
echo -e "========================================="

# ---------------------------------------------------------
# 步骤 1: 检查目标目录并处理首次克隆
# ---------------------------------------------------------
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}警告：目标目录 ${TARGET_DIR} 不存在。将尝试自动克隆仓库。${NC}"
    
    # 尝试创建父目录
    mkdir -p "$(dirname "$TARGET_DIR")"

    # 执行克隆
    if git clone "$NOFX_SERVICE_REPO_URL" "$TARGET_DIR"; then
        echo -e "${GREEN}成功：仓库已克隆到 ${TARGET_DIR}${NC}"
        
        # 首次克隆后直接运行服务
        cd "$TARGET_DIR" || { echo -e "${RED}错误：无法进入 ${TARGET_DIR} 目录。${NC}"; exit 1; }
        
        echo -e "${YELLOW}执行首次构建和启动：./start.sh start --build${NC}"
        ./start.sh start --build

        echo -e "\n${GREEN}部署和启动完成。${NC}"
        
        # 询问是否查看日志
        while true; do
            read -r -p "是否要立即查看服务日志 (./start.sh logs)? (y/n): " choice
            case "$choice" in
                y|Y ) 
                    echo -e "${YELLOW}执行：./start.sh logs${NC}"
                    ./start.sh logs
                    break;;
                n|N ) 
                    echo -e "好的，下次见！"
                    break;;
                * ) 
                    echo "无效输入，请输入 'y' 或 'n'.";;
            esac
        done

        exit 0
    else
        echo -e "${RED}致命错误：无法克隆仓库 ${NOFX_SERVICE_REPO_URL} 到 ${TARGET_DIR}。请检查网络和权限。${NC}"
        exit 1
    fi
fi

# ---------------------------------------------------------
# 步骤 2: 检查更新
# ---------------------------------------------------------

# 进入目标目录
cd "$TARGET_DIR" || { echo -e "${RED}错误：无法进入 ${TARGET_DIR} 目录。${NC}"; exit 1; }

# 确保目录是 Git 仓库
if [ ! -d ".git" ]; then
    echo -e "${RED}错误：${TARGET_DIR} 目录不是一个 Git 仓库。请手动初始化或克隆。${NC}"
    exit 1
fi

echo -e "${YELLOW}1. 正在获取远程更新... (git fetch)${NC}"
git fetch

# 检查本地分支是否落后于远程分支
UPSTREAM='@{u}'
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ "$LOCAL" = "$REMOTE" ]; then
    # ---------------------------------------------------------
    # 情况 A: 没有更新
    # ---------------------------------------------------------
    echo -e "${GREEN}2. 检查结果：当前分支已是最新版本，无需更新。${NC}"
    
    # 询问是否查看日志
    while true; do
        read -r -p "是否要立即查看服务日志 (./start.sh logs)? (y/n): " choice
        case "$choice" in
            y|Y ) 
                echo -e "${YELLOW}执行：./start.sh logs${NC}"
                ./start.sh logs
                break;;
            n|N ) 
                echo -e "好的，下次见！"
                break;;
            * ) 
                echo "无效输入，请输入 'y' 或 'n'.";;
        esac
    done

elif [ "$LOCAL" = "$BASE" ]; then
    # ---------------------------------------------------------
    # 情况 B: 发现更新
    # ---------------------------------------------------------
    echo -e "${YELLOW}2. 检查结果：发现新版本，正在执行 git pull...${NC}"
    
    # 执行 git pull
    if git pull; then
        echo -e "${GREEN}3. Git Pull 成功。${NC}"
        
        # 执行构建和启动脚本
        echo -e "${YELLOW}4. 执行构建和启动：./start.sh start --build${NC}"
        ./start.sh start --build

        # 最后执行查看日志
        echo -e "${YELLOW}5. 执行：./start.sh logs${NC}"
        ./start.sh logs
        
        echo -e "\n${GREEN}更新、构建和日志查看流程已完成。${NC}"
    else
        echo -e "${RED}错误：Git Pull 失败。请手动检查冲突。${NC}"
    fi

elif [ "$REMOTE" = "$BASE" ]; then
    # ---------------------------------------------------------
    # 情况 C: 本地有新的提交 (通常不涉及 --build)
    # ---------------------------------------------------------
    echo -e "${YELLOW}2. 检查结果：本地有新的提交，远程无更新。${NC}"
    
    # 询问是否查看日志
    while true; do
        read -r -p "是否要立即查看服务日志 (./start.sh logs)? (y/n): " choice
        case "$choice" in
            y|Y ) 
                echo -e "${YELLOW}执行：./start.sh logs${NC}"
                ./start.sh logs
                break;;
            n|N ) 
                echo -e "好的，下次见！"
                break;;
            * ) 
                echo "无效输入，请输入 'y' 或 'n'.";;
        esac
    done

else
    # ---------------------------------------------------------
    # 情况 D: 分支分叉 (需要手动解决)
    # ---------------------------------------------------------
    echo -e "${RED}错误：分支已分叉，无法自动合并。请进入 ${TARGET_DIR} 手动解决冲突。${NC}"
fi

echo -e "========================================="
echo "脚本执行完毕。"
