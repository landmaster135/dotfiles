# Fcitx5

# Restart
```bash
nohup fcitx5 > /dev/null 2>&1 &
```

# Settings

## Brave
```bash
cat << 'EOF' > ~/.config/brave-flags.conf
--ozone-platform=x11
--force-device-scale-factor=1
EOF
```
