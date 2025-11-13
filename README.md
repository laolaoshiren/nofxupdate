jb Project Automation System (一键部署)

这个仓库包含了您的项目自动化管理脚本 (update_and_start.sh) 和一键安装脚本 (jb_install.sh)。

安装完成后，您只需要在服务器上输入 jb 即可自动执行 Git 更新、服务构建/启动以及查看日志的全部流程。

🚀 一键安装指南 (推荐)

在您的 Debian/Ubuntu 服务器上（确保已安装 git），以 root 权限 或 sudo 执行以下一行命令即可完成安装：

注意：请将 [RAW_INSTALL_SCRIPT_URL] 替换为您在 GitHub 上 jb_install.sh 文件的 Raw URL。

sudo bash -c "$(curl -fsSL [RAW_INSTALL_SCRIPT_URL])"


安装步骤说明:

下载脚本: curl -fsSL ... 会静默下载 jb_install.sh 的原始内容。

执行脚本: bash -c 会执行下载到的脚本内容。

权限: 使用 sudo 确保脚本有权限将文件克隆到 /opt/jb_project 并创建 /usr/local/bin/jb 全局命令。

🛠️ 使用方法

安装完成后，在终端的任何位置直接输入：

jb


它将自动执行以下操作：

进入项目目录 (/opt/jb_project/nofx)。

执行 git fetch 检查更新。

如果发现更新，执行 git pull 并运行 ./start.sh start --build，最后查看日志 (./start.sh logs)。

如果没有更新，询问您是否要查看日志 (./start.sh logs)。

📂 部署到 GitHub

创建您的 Git 仓库。

将 update_and_start.sh 和 jb_install.sh 文件上传到仓库的根目录。

修改 jb_install.sh 文件中的 REPO_URL 变量，确保它指向您实际的 Git 仓库 URL。

获取 jb_install.sh 的 Raw URL，用于提供给用户进行一键安装。
