# Game

## 一般設定

```bash
sudo nano /etc/modprobe.d/nvidia.conf
```

下記の内容を記入。`NVreg_DynamicPowerManagement=0x02` はノートPC向けなので、デスクトップなら省略でOKです。ノートなら追加してください。
```ini
options nvidia NVreg_UsePageAttributeTable=1 options nvidia NVreg_InitializeSystemMemoryAllocations=0 options nvidia NVreg_DynamicPowerManagement=0x02 options nvidia NVreg_RegistryDwords=RMIntrLockingMode=1
```

保存後、initramfs を再生成して反映
```bash
sudo mkinitcpio -P
```

再起動後に設定が有効になっているか確認
```bash
cat /proc/driver/nvidia/params | grep -E "UsePageAttributeTable|InitializeSystemMemoryAllocations"

cat /proc/driver/nvidia/params | grep IntrLocking
```

## Steam 設定
起動オプションをこちらに更新してください:
```
PROTON_NVIDIA_LIBS=1 PROTON_NVIDIA_LIBS_NO_32BIT=1 PROTON_USE_NTSYNC=1 PROTON_ENABLE_WAYLAND=1 MANGOHUD=1 prime-run %command%
```

ただし `PROTON_ENABLE_WAYLAND=1` には注意点があります:
| メリット | デメリット |
|---|---|
| レイテンシ・フレームペーシング改善 | Steam オーバーレイが使えなくなる |
| HDR が使いやすくなる | 現時点では実験的機能 |

Steam オーバーレイ（Shift+Tab）をよく使うなら外しておいた方が無難です。使わないなら入れて問題ありません。
