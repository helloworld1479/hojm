#!/bin/bash
echo "🚀 开始部署 Telegram 中文通知..."

cd /tmp

echo "📥 下载 tg_msg.py..."
wget --no-check-certificate https://raw.githubusercontent.com/helloworld1479/hojm/master/tg_msg.py -O tg_msg.py
if [ $? -ne 0 ]; then echo "❌ 下载 tg_msg.py 失败"; exit 1; fi

echo "📥 下载 base_task.py..."
wget --no-check-certificate https://raw.githubusercontent.com/helloworld1479/hojm/master/base_task.py -O base_task.py
if [ $? -ne 0 ]; then echo "❌ 下载 base_task.py 失败"; exit 1; fi

echo "📥 下载 site_push.py..."
wget --no-check-certificate https://raw.githubusercontent.com/helloworld1479/hojm/master/site_push.py -O site_push.py
if [ $? -ne 0 ]; then echo "❌ 下载 site_push.py 失败"; exit 1; fi

echo "💾 备份原文件..."
cp /www/server/panel/mod/base/msg/tg_msg.py /www/server/panel/mod/base/msg/tg_msg.py.bak 2>/dev/null && echo "  ✓ tg_msg.py 已备份"
cp /www/server/panel/mod/base/push_mod/base_task.py /www/server/panel/mod/base/push_mod/base_task.py.bak 2>/dev/null && echo "  ✓ base_task.py 已备份"
cp /www/server/panel/mod/base/push_mod/site_push.py /www/server/panel/mod/base/push_mod/site_push.py.bak 2>/dev/null && echo "  ✓ site_push.py 已备份"

echo "📝 替换文件..."
cp /tmp/tg_msg.py /www/server/panel/mod/base/msg/ && echo "  ✓ tg_msg.py 已替换"
cp /tmp/base_task.py /www/server/panel/mod/base/push_mod/ && echo "  ✓ base_task.py 已替换"
cp /tmp/site_push.py /www/server/panel/mod/base/push_mod/ && echo "  ✓ site_push.py 已替换"

echo "🧹 清除缓存..."
rm -rf /www/server/panel/mod/base/msg/__pycache__
rm -rf /www/server/panel/mod/base/push_mod/__pycache__
echo "  ✓ 缓存已清除"

echo "🗑️ 清理临时文件..."
rm -f /tmp/tg_msg.py /tmp/base_task.py /tmp/site_push.py

echo ""
echo "✅ 部署完成！"
echo "📌 请到面板测试 Telegram 通知是否正常"
