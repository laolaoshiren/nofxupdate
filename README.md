# Nofx 自动化部署与管理工具 (jb Command)

本项目提供了一个极简的一键安装脚本，用于在 **Debian/Ubuntu** 服务器上快速部署、更新和管理您的 Nofx 服务。

通过全局 `jb` 命令，您可以随时检查 `/root/nofx` 服务的 Git 更新、自动拉取代码、重启服务，并在操作后方便地查看日志或系统监控。

---

## 🚀 快速安装与更新

以下命令将自动完成环境依赖检查（Git, Docker, btop）、核心脚本部署，并创建全局 `jb` 命令。

在您的服务器上执行以下一键命令：

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/laolaoshiren/nofxupdate/main/jb_install.sh)"
