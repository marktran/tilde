#!/usr/bin/env zsh
# */10 * * * * $HOME/bin/battery-notifier.zsh > /dev/null

CURRENT_CHARGE=$(/usr/sbin/ioreg -l |
/usr/bin/grep -i capacity |
/usr/bin/tr '\n' ' | ' |
/usr/bin/awk '{printf("%.0f",$10/$5 * 100)}')

if [[ $CURRENT_CHARGE -lt "15" ]]; then
    /usr/local/bin/growlnotify -a 'System Preferences' 'Low Battery' \
-m "Charge is ${CURRENT_CHARGE}%"
fi
