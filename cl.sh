#!/bin/bash

# ================================================================
# 智能磁盘空间清理脚本
# 支持: CentOS, Debian, Ubuntu
# 功能: 自动检测占用大的目录和文件，交互式选择删除
# ================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo -e "${BLUE}检测到操作系统: $OS $VER${NC}"
}

# 打印标题
print_header() {
    echo -e "\n${GREEN}================================================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================================================${NC}\n"
}

# 打印警告
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 打印错误
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# 打印成功
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "请使用 root 用户或 sudo 运行此脚本"
        exit 1
    fi
}

# 显示当前磁盘使用情况
show_disk_usage() {
    print_header "当前磁盘使用情况"
    df -h | grep -E '^/dev/|Filesystem'
    echo ""
}

# 分析目录占用（可配置层级）
analyze_directory() {
    local target_dir=$1
    local depth=${2:-1}
    local limit=${3:-20}
    
    print_header "分析目录: $target_dir (层级: $depth)"
    print_warning "正在扫描，请稍候..."
    
    if [ $depth -eq 1 ]; then
        du -sh ${target_dir}/* 2>/dev/null | sort -hr | head -${limit}
    else
        du -h --max-depth=$depth ${target_dir} 2>/dev/null | sort -hr | head -${limit}
    fi
}

# 查找大文件
find_large_files() {
    local target_dir=$1
    local size_mb=${2:-100}
    
    print_header "查找大于 ${size_mb}MB 的文件"
    print_warning "正在扫描，请稍候..."
    
    find ${target_dir} -type f -size +${size_mb}M -exec ls -lh {} \; 2>/dev/null | \
        awk '{print $5 "\t" $9}' | sort -hr | head -20
}

# 交互式删除确认
confirm_delete() {
    local path=$1
    local size=$2
    
    echo -e "\n${YELLOW}准备删除:${NC} $path"
    echo -e "${YELLOW}大小:${NC} $size"
    echo -e -n "${YELLOW}确认删除? (y/n): ${NC}"
    read -r response
    
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 删除文件或目录
delete_item() {
    local path=$1
    
    if [ -d "$path" ]; then
        rm -rf "$path"
        if [ $? -eq 0 ]; then
            print_success "已删除目录: $path"
            return 0
        else
            print_error "删除失败: $path"
            return 1
        fi
    elif [ -f "$path" ]; then
        rm -f "$path"
        if [ $? -eq 0 ]; then
            print_success "已删除文件: $path"
            return 0
        else
            print_error "删除失败: $path"
            return 1
        fi
    else
        print_error "路径不存在: $path"
        return 1
    fi
}

# aaPanel 专用清理
clean_aapanel() {
    print_header "aaPanel 清理选项"
    
    # 检查是否安装了 aaPanel
    if [ ! -d "/www" ]; then
        print_error "未检测到 aaPanel 安装目录 (/www)"
        return
    fi
    
    echo "1. 清理数据库备份 (/www/backup/database)"
    echo "2. 清理网站备份 (/www/backup/site)"
    echo "3. 清理网站日志 (/www/wwwlogs)"
    echo "4. 查看所有备份目录"
    echo "5. 返回主菜单"
    echo -e -n "\n${YELLOW}请选择 (1-5): ${NC}"
    read -r choice
    
    case $choice in
        1)
            clean_database_backups
            ;;
        2)
            clean_site_backups
            ;;
        3)
            clean_web_logs
            ;;
        4)
            analyze_directory "/www/backup" 2 20
            ;;
        5)
            return
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# 清理数据库备份
clean_database_backups() {
    local backup_dir="/www/backup/database"
    
    if [ ! -d "$backup_dir" ]; then
        print_error "数据库备份目录不存在"
        return
    fi
    
    print_header "数据库备份清理"
    
    local total_files=$(ls "$backup_dir" 2>/dev/null | wc -l)
    local total_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
    
    echo -e "${BLUE}备份文件总数:${NC} $total_files"
    echo -e "${BLUE}总占用空间:${NC} $total_size"
    echo ""
    
    if [ $total_files -eq 0 ]; then
        print_warning "备份目录为空"
        return
    fi
    
    # 显示最新的备份
    echo -e "${BLUE}最新的 5 个备份:${NC}"
    ls -lt "$backup_dir" | head -6
    echo ""
    
    echo "清理策略:"
    echo "1. 保留最近 7 天的备份"
    echo "2. 保留最近 30 天的备份"
    echo "3. 保留最近 90 天的备份"
    echo "4. 按日期范围删除（自定义）"
    echo "5. 删除所有备份（危险）"
    echo "6. 返回"
    echo -e -n "\n${YELLOW}请选择 (1-6): ${NC}"
    read -r strategy
    
    case $strategy in
        1)
            delete_old_backups "$backup_dir" 7
            ;;
        2)
            delete_old_backups "$backup_dir" 30
            ;;
        3)
            delete_old_backups "$backup_dir" 90
            ;;
        4)
            delete_backups_by_date "$backup_dir"
            ;;
        5)
            if confirm_delete "$backup_dir/*" "$total_size"; then
                rm -f "$backup_dir"/*
                print_success "已删除所有备份"
            else
                print_warning "取消删除"
            fi
            ;;
        6)
            return
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# 按天数删除旧备份
delete_old_backups() {
    local backup_dir=$1
    local days=$2
    
    print_warning "准备删除 $days 天前的备份..."
    
    # 统计将被删除的文件
    local count=$(find "$backup_dir" -type f -mtime +$days 2>/dev/null | wc -l)
    
    if [ $count -eq 0 ]; then
        print_warning "没有找到 $days 天前的备份文件"
        return
    fi
    
    echo -e "${YELLOW}将删除 $count 个备份文件${NC}"
    echo -e -n "${YELLOW}确认删除? (y/n): ${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        find "$backup_dir" -type f -mtime +$days -delete
        print_success "已删除 $days 天前的备份"
        
        # 显示清理后的情况
        local new_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
        local new_count=$(ls "$backup_dir" 2>/dev/null | wc -l)
        echo -e "${GREEN}剩余文件数: $new_count${NC}"
        echo -e "${GREEN}当前占用: $new_size${NC}"
    else
        print_warning "取消删除"
    fi
}

# 按日期范围删除备份
delete_backups_by_date() {
    local backup_dir=$1
    
    echo -e -n "${YELLOW}输入起始日期 (格式: YYYYMM, 例如: 202401): ${NC}"
    read -r start_date
    
    echo -e -n "${YELLOW}输入结束日期 (格式: YYYYMM, 例如: 202410): ${NC}"
    read -r end_date
    
    # 验证日期格式
    if ! [[ "$start_date" =~ ^[0-9]{6}$ ]] || ! [[ "$end_date" =~ ^[0-9]{6}$ ]]; then
        print_error "日期格式错误"
        return
    fi
    
    print_warning "准备删除 $start_date 到 $end_date 之间的备份..."
    
    # 使用 find 和 正则匹配删除
    local pattern="*_${start_date}*"
    local count=0
    
    # 列出将要删除的文件（预览）
    echo -e "${BLUE}将要删除的文件示例:${NC}"
    for file in "$backup_dir"/*; do
        filename=$(basename "$file")
        # 提取文件名中的日期部分 (YYYYMMDD)
        if [[ $filename =~ ([0-9]{8}) ]]; then
            file_date=${BASH_REMATCH[1]:0:6}  # 取前6位 YYYYMM
            if [ "$file_date" -ge "$start_date" ] && [ "$file_date" -le "$end_date" ]; then
                ((count++))
                if [ $count -le 5 ]; then
                    echo "  - $filename"
                fi
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_warning "没有找到匹配的备份文件"
        return
    fi
    
    echo -e "${YELLOW}共找到 $count 个文件${NC}"
    echo -e -n "${YELLOW}确认删除? (y/n): ${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        for file in "$backup_dir"/*; do
            filename=$(basename "$file")
            if [[ $filename =~ ([0-9]{8}) ]]; then
                file_date=${BASH_REMATCH[1]:0:6}
                if [ "$file_date" -ge "$start_date" ] && [ "$file_date" -le "$end_date" ]; then
                    rm -f "$file"
                fi
            fi
        done
        print_success "删除完成"
    else
        print_warning "取消删除"
    fi
}

# 清理网站备份
clean_site_backups() {
    local backup_dir="/www/backup/site"
    
    if [ ! -d "$backup_dir" ]; then
        print_error "网站备份目录不存在"
        return
    fi
    
    analyze_directory "$backup_dir" 1 20
    
    echo -e -n "\n${YELLOW}是否要清理此目录? (y/n): ${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        delete_old_backups "$backup_dir" 30
    fi
}

# 清理网站日志
clean_web_logs() {
    local log_dir="/www/wwwlogs"
    
    if [ ! -d "$log_dir" ]; then
        print_error "日志目录不存在"
        return
    fi
    
    print_header "网站日志清理"
    
    local total_size=$(du -sh "$log_dir" 2>/dev/null | awk '{print $1}')
    echo -e "${BLUE}日志目录大小:${NC} $total_size"
    echo ""
    
    echo "1. 删除 30 天前的日志"
    echo "2. 删除 60 天前的日志"
    echo "3. 删除 90 天前的日志"
    echo "4. 查看大日志文件"
    echo "5. 返回"
    echo -e -n "\n${YELLOW}请选择 (1-5): ${NC}"
    read -r choice
    
    case $choice in
        1|2|3)
            local days=$((choice * 30))
            delete_old_backups "$log_dir" $days
            ;;
        4)
            find_large_files "$log_dir" 50
            ;;
        5)
            return
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# 通用清理模式
generic_cleanup() {
    print_header "通用清理模式"
    
    echo "1. 分析根目录 (/) - 第1层"
    echo "2. 分析根目录 (/) - 第2层"
    echo "3. 分析自定义目录"
    echo "4. 查找大文件（全局）"
    echo "5. 清理系统缓存"
    echo "6. 返回主菜单"
    echo -e -n "\n${YELLOW}请选择 (1-6): ${NC}"
    read -r choice
    
    case $choice in
        1)
            analyze_directory "/" 1 20
            interactive_delete
            ;;
        2)
            analyze_directory "/" 2 30
            interactive_delete
            ;;
        3)
            echo -e -n "${YELLOW}输入要分析的目录 (例如: /var): ${NC}"
            read -r custom_dir
            if [ -d "$custom_dir" ]; then
                echo -e -n "${YELLOW}输入分析层级 (1-3): ${NC}"
                read -r depth
                analyze_directory "$custom_dir" $depth 20
                interactive_delete
            else
                print_error "目录不存在"
            fi
            ;;
        4)
            echo -e -n "${YELLOW}输入搜索目录 (默认 /): ${NC}"
            read -r search_dir
            search_dir=${search_dir:-/}
            
            echo -e -n "${YELLOW}输入文件大小阈值MB (默认 100): ${NC}"
            read -r size_mb
            size_mb=${size_mb:-100}
            
            find_large_files "$search_dir" $size_mb
            interactive_delete_files
            ;;
        5)
            clean_system_cache
            ;;
        6)
            return
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
}

# 交互式删除（针对目录列表）
interactive_delete() {
    echo -e -n "\n${YELLOW}输入要删除的目录路径 (完整路径，输入 q 退出): ${NC}"
    read -r dir_path
    
    if [ "$dir_path" == "q" ]; then
        return
    fi
    
    if [ ! -e "$dir_path" ]; then
        print_error "路径不存在: $dir_path"
        interactive_delete
        return
    fi
    
    local size=$(du -sh "$dir_path" 2>/dev/null | awk '{print $1}')
    
    if confirm_delete "$dir_path" "$size"; then
        delete_item "$dir_path"
        
        # 显示清理后的磁盘情况
        echo ""
        show_disk_usage
    else
        print_warning "取消删除"
    fi
    
    # 继续还是退出
    echo -e -n "${YELLOW}继续删除其他目录? (y/n): ${NC}"
    read -r continue_response
    if [[ "$continue_response" =~ ^[Yy]$ ]]; then
        interactive_delete
    fi
}

# 交互式删除文件
interactive_delete_files() {
    echo -e -n "\n${YELLOW}输入要删除的文件路径 (完整路径，输入 q 退出): ${NC}"
    read -r file_path
    
    if [ "$file_path" == "q" ]; then
        return
    fi
    
    if [ ! -f "$file_path" ]; then
        print_error "文件不存在: $file_path"
        interactive_delete_files
        return
    fi
    
    local size=$(ls -lh "$file_path" | awk '{print $5}')
    
    if confirm_delete "$file_path" "$size"; then
        delete_item "$file_path"
        
        echo ""
        show_disk_usage
    else
        print_warning "取消删除"
    fi
    
    echo -e -n "${YELLOW}继续删除其他文件? (y/n): ${NC}"
    read -r continue_response
    if [[ "$continue_response" =~ ^[Yy]$ ]]; then
        interactive_delete_files
    fi
}

# 清理系统缓存
clean_system_cache() {
    print_header "清理系统缓存"
    
    echo "1. 清理 APT 缓存 (Debian/Ubuntu)"
    echo "2. 清理 YUM/DNF 缓存 (CentOS/RHEL)"
    echo "3. 清理临时文件 (/tmp)"
    echo "4. 清理日志文件 (/var/log)"
    echo "5. 全部清理"
    echo "6. 返回"
    echo -e -n "\n${YELLOW}请选择 (1-6): ${NC}"
    read -r choice
    
    case $choice in
        1)
            if command -v apt-get &> /dev/null; then
                apt-get clean
                apt-get autoclean
                print_success "APT 缓存已清理"
            else
                print_error "此系统不支持 APT"
            fi
            ;;
        2)
            if command -v yum &> /dev/null; then
                yum clean all
                print_success "YUM 缓存已清理"
            elif command -v dnf &> /dev/null; then
                dnf clean all
                print_success "DNF 缓存已清理"
            else
                print_error "此系统不支持 YUM/DNF"
            fi
            ;;
        3)
            if confirm_delete "/tmp/*" ""; then
                rm -rf /tmp/*
                print_success "临时文件已清理"
            fi
            ;;
        4)
            echo -e -n "${YELLOW}删除多少天前的日志? (默认 30): ${NC}"
            read -r days
            days=${days:-30}
            find /var/log -type f -name "*.log" -mtime +$days -delete
            find /var/log -type f -name "*.gz" -mtime +$days -delete
            print_success "旧日志已清理"
            ;;
        5)
            # 全部清理
            [ -x "$(command -v apt-get)" ] && apt-get clean && apt-get autoclean
            [ -x "$(command -v yum)" ] && yum clean all
            [ -x "$(command -v dnf)" ] && dnf clean all
            
            if confirm_delete "/tmp/* 和 30天前的日志" ""; then
                rm -rf /tmp/* 2>/dev/null
                find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null
                find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null
                print_success "系统缓存全部清理完成"
            fi
            ;;
        6)
            return
            ;;
        *)
            print_error "无效选择"
            ;;
    esac
    
    # 显示清理后结果
    echo ""
    show_disk_usage
}

# 主菜单
main_menu() {
    while true; do
        clear
        print_header "智能磁盘清理工具"
        detect_os
        show_disk_usage
        
        echo "请选择操作模式:"
        echo "1. aaPanel 专用清理（推荐）"
        echo "2. 通用清理模式"
        echo "3. 快速分析（查看占用最大的目录）"
        echo "4. 系统缓存清理"
        echo "5. 退出"
        echo -e -n "\n${YELLOW}请选择 (1-5): ${NC}"
        read -r main_choice
        
        case $main_choice in
            1)
                clean_aapanel
                ;;
            2)
                generic_cleanup
                ;;
            3)
                print_header "快速分析 - Top 20 目录"
                analyze_directory "/" 1 20
                echo -e -n "\n${YELLOW}按回车继续...${NC}"
                read
                ;;
            4)
                clean_system_cache
                ;;
            5)
                print_success "感谢使用！"
                exit 0
                ;;
            *)
                print_error "无效选择，请重试"
                sleep 2
                ;;
        esac
    done
}

# ================================================================
# 脚本入口
# ================================================================

check_root
main_menu
