#!/bin/bash

# =========================================================
# 自动更新与启动脚本 (jb Command)
# 功能: 检查 Git 更新 -> 执行 Git Pull -> 启动服务 -> 交互式日志/监控
# =========================================================

# --- 配置 ---
TARGET_DIR="/root/nofx"
NOFX_SERVICE_REPO_URL="https://github.com/NoFxAiOS/nofx"
MAIN_BRANCH="dev" # 假设主分支是 main

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}### 自动更新与启动脚本 (jb Command) ###${NC}"
echo -e "${CYAN}=========================================${NC}"

# 1. 检查目标目录并处理首次克隆
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}警告：目标目录 ${TARGET_DIR} 不存在。正在进行首次克隆...${NC}"
    if sudo git clone "$NOFX_SERVICE_REPO_URL" "$TARGET_DIR"; then
        echo -e "${GREEN}克隆成功。正在进行初始化配置...${NC}"
        
        # 1.1. 进入目录
        cd "$TARGET_DIR" || { echo -e "${RED}错误：无法进入 ${TARGET_DIR}。${NC}"; exit 1; }
        
        # 1.2. 检查并复制 config.json
        if [ ! -f "config.json" ] && [ -f "config.json.example" ]; then
            echo -e "${YELLOW}--> 复制 config.json.example 到 config.json...${NC}"
            # 确保使用 sudo 复制，因为 TARGET_DIR 是 /root/nofx
            sudo cp config.json.example config.json
        fi
        
        # 1.3. 赋予 start.sh 执行权限
        if [ -f "start.sh" ]; then
            echo -e "${YELLOW}--> 赋予 start.sh 执行权限...${NC}"
            sudo chmod +x start.sh 2>/dev/null 
        fi

        # 1.4. 启动服务
        echo -e "${YELLOW}--> 执行首次服务构建和启动 (./start.sh start --build)...${NC}"
        sudo ./start.sh start --build
        
        echo -e "${GREEN}服务初始化和启动完成。${NC}"
        STATUS="INITIAL_CLONE"

    else
        echo -e "${RED}致命错误：Git 克隆失败。请检查网络或仓库地址。${NC}"
        exit 1
    fi
else
    # 2. 目录存在，执行更新检查
    cd "$TARGET_DIR" || { echo -e "${RED}错误：无法进入 ${TARGET_DIR}。${NC}"; exit 1; }

    echo -e "${YELLOW}--> 进入项目目录 ${TARGET_DIR}。${NC}"
    
    # 检查是否为 Git 仓库
    if [ ! -d ".git" ]; then
        echo -e "${RED}错误：${TARGET_DIR} 不是一个有效的 Git 仓库。请手动修复。${NC}"
        exit 1
    fi

    echo -e "${YELLOW}--> 正在执行 git fetch 检查更新...${NC}"
    # 使用 sudo 执行 git fetch
    if sudo git fetch origin "$MAIN_BRANCH"; then
        # 比较本地和远程 HEAD
        LOCAL_HASH=$(git rev-parse HEAD)
        REMOTE_HASH=$(git rev-parse "origin/$MAIN_BRANCH")

        if [ "$LOCAL_HASH" != "$REMOTE_HASH" ]; then
            echo -e "${GREEN}发现新版本！正在执行 git pull...${NC}"
            
            # 使用 --ff-only 避免分支分歧导致脚本中断
            if sudo git pull --ff-only origin "$MAIN_BRANCH"; then
                echo -e "${GREEN}代码拉取成功。${NC}"
                
                # 重新赋予 start.sh 权限以防权限丢失 (安全措施)
                if [ -f "start.sh" ]; then
                    sudo chmod +x start.sh 2>/dev/null 
                fi

                echo -e "${YELLOW}--> 正在执行服务构建和重启 (./start.sh start --build)...${NC}"
                sudo ./start.sh start --build
                echo -e "${GREEN}服务更新和启动完成。${NC}"
                STATUS="UPDATED"
            else
                echo -e "${RED}错误：git pull 失败。本地分支与远程分支有分歧，请手动进入目录执行 'sudo git pull --rebase' 解决。${NC}"
                STATUS="PULL_FAILED"
            fi
        else
            echo -e "${YELLOW}当前已是最新版本，无需更新。${NC}"
            STATUS="NO_UPDATE"
        fi
    else
        echo -e "${RED}错误：git fetch 失败。请检查网络或 Git 配置。${NC}"
        STATUS="FETCH_FAILED"
    fi
fi

# 3. 交互式菜单 (无论是否更新，都提供此选项)
if [ "$STATUS" != "PULL_FAILED" ] && [ "$STATUS" != "FETCH_FAILED" ] ; then
    echo -e "\n${CYAN}=======================${NC}"
    echo -e "${CYAN}请选择后续操作：${NC}"
    
    OPTIONS=(
        "查看 nofx 服务日志 (./start.sh logs)" 
        "执行 btop (系统资源监控)" 
        "退出"
    )
    
    select opt in "${OPTIONS[@]}"
    do
        case $opt in
            "查看 nofx 服务日志 (./start.sh logs)")
                echo -e "${YELLOW}--> 正在执行 ./start.sh logs...${NC}"
                # 确保在正确的目录下执行 logs
                cd "$TARGET_DIR" || { echo -e "${RED}错误：无法进入 ${TARGET_DIR}。${NC}"; exit 1; }
                sudo ./start.sh logs
                break
                ;;
            "执行 btop (系统资源监控)")
                echo -e "${YELLOW}--> 正在执行 btop...${NC}"
                # 检查 btop 是否可用 (依赖于 jb_install.sh 安装)
                if command -v btop &> /dev/null; then
                    btop
                else
                    echo -e "${RED}错误：btop 未安装或不在 PATH 中。请运行安装脚本更新依赖。${NC}"
                fi
                break
                ;;
            "退出")
                echo -e "${CYAN}操作完成，退出脚本。${NC}"
                break
                ;;
            *) echo -e "${RED}无效选项 $REPLY${NC}";;
        esac
    done
fi

echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}脚本执行完毕。${NC}"
