#hsc关灵动岛
setprop ro.show.setting.island false
#新子腾初代1.0版本
setprop forbid.install.testapk false
#新子腾升级版2.0＆微卫士
setprop persist.sys.dw.forbid.detectapp false
#还原配置
BUSYBOX="/data/adb/magisk/busybox"
# 检查权限
[ "$(id -u)" -ne 0 ] && echo "❌ 请使用root权限运行！" && exit 1
[ ! -x "$BUSYBOX" ] && echo "❌ BusyBox未找到 ($BUSYBOX)" && exit 1

# 更健壮的RAM获取方式
ram_kb=$($BUSYBOX grep -m1 MemTotal /proc/meminfo | $BUSYBOX tr -s ' ' | $BUSYBOX cut -d' ' -f2)
[ -z "$ram_kb" ] && ram_kb=0
ram_gb=$((ram_kb / 1024 / 1024))
ram_remainder=$(( (ram_kb % (1024*1024)) * 10 / (1024*1024) ))  # 获取小数点后1位

# 更健壮的ROM获取方式
rom_sectors=$(cat /sys/block/mmcblk0/size 2>/dev/null || echo 0)
rom_gb=$((rom_sectors * 512 / 1024 / 1024 / 1024))

# 内存向上取整规则（单位：GB）
if [ $ram_gb -eq 0 ]; then
    match_ram=1
elif [ $ram_gb -eq 1 ] && [ $ram_remainder -ge 1 ]; then
    match_ram=2
elif [ $ram_gb -eq 2 ] && [ $ram_remainder -ge 1 ]; then
    match_ram=3
elif [ $ram_gb -eq 3 ] && [ $ram_remainder -ge 1 ]; then
    match_ram=4
elif [ $ram_gb -eq 4 ] && [ $ram_remainder -ge 1 ]; then
    match_ram=6
else
    match_ram=$ram_gb
fi

# ROM取最接近标准值
rom_options="8 16 32 64"
match_rom=32  # 默认值
min_diff=100
for opt in $rom_options; do
    diff=$((rom_gb > opt ? rom_gb - opt : opt - rom_gb))
    [ $diff -lt $min_diff ] && min_diff=$diff && match_rom=$opt
done

# 显示检测结果
echo "🔍 硬件检测报告"
echo "-----------------------------"
[ "$ram_kb" -eq 0 ] && echo "⚠️ 无法读取RAM信息" || echo "实际 RAM: ${ram_gb}.${ram_remainder} GB → 匹配 ${match_ram} GB"
echo "实际 ROM: ${rom_gb} GB → 匹配 ${match_rom} GB"
echo "-----------------------------"

# 仅当获取到有效数据时才修正
if [ "$ram_kb" -gt 0 ] && [ "$rom_sectors" -gt 0 ]; then
    setprop persist.sys.ram "${match_ram}G"
    setprop persist.sys.rom "${match_rom}G"
    echo "✅ 已修正为:"
    echo "persist.sys.ram = ${match_ram}G"
    echo "persist.sys.rom = ${match_rom}G"
    echo "⚠️ 重启后生效"
else
    echo "❌ 检测失败：无法获取完整硬件信息"
fi
setprop persist.sys.cpu 4
setprop persist.sys.android.version 8.1
setprop persist.sys.logo 4g
setprop persist.sys.5g false
resetprop ro.crypto.state encrypted
sleep 15
# 检查系统 settings 命令是否存在
if ! command -v settings >/dev/null 2>&1; then
    echo "错误：找不到 'settings' 命令，请确保设备支持该命令！" >&2
    exit 1
fi

#hsc开系统全局动画
# 修改动画缩放设置
settings put global window_animation_scale 1
settings put global transition_animation_scale 1
settings put global animator_duration_scale 1

echo "动画设置已成功更改为1秒"
echo "当前设置："
echo "窗口动画缩放: $(settings get global window_animation_scale)"
echo "过渡动画缩放: $(settings get global transition_animation_scale)"
echo "动画程序时长缩放: $(settings get global animator_duration_scale)"
