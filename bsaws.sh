#!/usr/bin/env bash
#
# 一键部署 cfaw8s.sh DDNS 定时任务
# 用法: bash setup-cfddns.sh
#

set -e

SCRIPT_URL="https://raw.githubusercontent.com/helloworld1479/hojm/master/cfaw8s.sh"
INSTALL_DIR="/opt/cf-ddns"
SCRIPT_PATH="${INSTALL_DIR}/cfaw8s.sh"
CRON_JOB="*/5 * * * * /bin/bash ${SCRIPT_PATH} >/dev/null 2>&1"

echo "===== CFDDNS 一键部署 ====="

# 1. 创建目录
echo "[1/3] 创建目录 ${INSTALL_DIR} ..."
mkdir -p "$INSTALL_DIR"

# 2. 下载脚本
echo "[2/3] 下载 cfaw8s.sh ..."
wget -q -O "$SCRIPT_PATH" "$SCRIPT_URL"
chmod +x "$SCRIPT_PATH"
echo "      已保存到 ${SCRIPT_PATH}"

# 3. 添加定时任务（避免重复添加）
echo "[3/3] 配置 crontab（每 5 分钟执行一次）..."
if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
    echo "      定时任务已存在，跳过"
else
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "      定时任务已添加"
fi

echo ""
echo "===== 部署完成 ====="
echo "脚本路径: ${SCRIPT_PATH}"
echo "执行频率: 每 5 分钟"
echo "查看定时任务: crontab -l"
echo "手动测试运行: bash ${SCRIPT_PATH}"
