#!/bin/bash
echo "🚀 开始部署 Telegram 中文通知（兼容版）..."

# 备份文件
cp /www/server/panel/mod/base/push_mod/site_push.py /www/server/panel/mod/base/push_mod/site_push.py.bak
cp /www/server/panel/mod/base/push_mod/base_task.py /www/server/panel/mod/base/push_mod/base_task.py.bak
cp /www/server/panel/mod/base/msg/tg_msg.py /www/server/panel/mod/base/msg/tg_msg.py.bak
echo "✓ 已备份原文件"

# 翻译 site_push.py 标题
echo "📝 翻译告警标题..."
sed -i 's/SSL Certificate expiration/SSL 证书过期提醒/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/Site Certificate (SSL) expiration/网站 SSL 证书过期/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/Certificate (SSL) Expiration/SSL 证书过期/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/aaPanel login alarm/面板登录提醒/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/SSH login alert/SSH 登录提醒/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/SSH login failure alarm/SSH 登录失败告警/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/aaPanel safety alarm/面板安全告警/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/Service Stop Alert/服务停止告警/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/Site expiration reminders/网站到期提醒/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/aaPanel password expiration date/面板密码过期提醒/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/aaPanel update reminders/面板更新提醒/g' /www/server/panel/mod/base/push_mod/site_push.py
sed -i 's/Project stop alarm/项目停止告警/g' /www/server/panel/mod/base/push_mod/site_push.py

# 修改 base_task.py 消息头格式
echo "📝 修改消息格式..."
sed -i 's/#### {}/📌 {}/g' /www/server/panel/mod/base/push_mod/base_task.py
sed -i 's/>Server:/🖥️ 服务器:/g' /www/server/panel/mod/base/push_mod/base_task.py
sed -i 's/>SendingTime:/📅 发送时间:/g' /www/server/panel/mod/base/push_mod/base_task.py
sed -i 's/">IPAddress.*Internal)"/""/' /www/server/panel/mod/base/push_mod/base_task.py

# 修改 tg_msg.py 中的 <br> 为 \n
echo "📝 修复换行符..."
sed -i 's/<br>/\\n/g' /www/server/panel/mod/base/push_mod/base_task.py

# 清除缓存
echo "🧹 清除缓存..."
rm -rf /www/server/panel/mod/base/push_mod/__pycache__
rm -rf /www/server/panel/mod/base/msg/__pycache__

echo ""
echo "✅ 部署完成！"
echo "📌 请到面板测试 Telegram 通知"
