#!/bin/bash
echo "🚀 开始部署 Telegram 中文通知..."

cd /tmp
wget -q https://raw.githubusercontent.com/helloworld1479/hojm/master/tg_msg.py
wget -q https://raw.githubusercontent.com/helloworld1479/hojm/master/base_task.py
wget -q https://raw.githubusercontent.com/helloworld1479/hojm/master/site_push.py

cp /www/server/panel/mod/base/msg/tg_msg.py /www/server/panel/mod/base/msg/tg_msg.py.bak 2>/dev/null
cp /www/server/panel/mod/base/push_mod/base_task.py /www/server/panel/mod/base/push_mod/base_task.py.bak 2>/dev/null
cp /www/server/panel/mod/base/push_mod/site_push.py /www/server/panel/mod/base/push_mod/site_push.py.bak 2>/dev/null

cp /tmp/tg_msg.py /www/server/panel/mod/base/msg/
cp /tmp/base_task.py /www/server/panel/mod/base/push_mod/
cp /tmp/site_push.py /www/server/panel/mod/base/push_mod/

rm -rf /www/server/panel/mod/base/msg/__pycache__
rm -rf /www/server/panel/mod/base/push_mod/__pycache__

rm -f /tmp/tg_msg.py /tmp/base_task.py /tmp/site_push.py

echo "✅ 部署完成！"
