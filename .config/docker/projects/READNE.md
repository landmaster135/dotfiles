# Docker Projects

## Port management and resource usage
| Service | Port | TSD Proxy | ram_container_uses_mib | disk_image_uses_mib |
| --- | --- | --- | --- | --- |
| DatHub | 5173 | 5173 | 20 | 650 |
| Devbox | - | - | - | - |
| AdGuard Home | 46073 | 80 | - | - |
| Dockhand | 3100 | 3100 | 70 | 635 |
| File Browser | 8180 | 8180 | 12 | 52 |
| Grafana | 3000 | 36411 | - | - |
| Immich | 2283 | 2283 | 750 | 4096 |
| Jellyfin | 8096 | 8096 | 182 | 2048 |
| Kavita | 5000 | 38977 | - | - |
| Komga | 25600 | 25600 | - | - |
| Memos (SQLite) | 5230 | 5230 | - | - |
| Memos Postgres | 5240 | 5240 | 43 | 700 |
| Memos Postgres Staging | 5241 | 5241 | 43 | 700 |
| Netdata | 19999 | 19999 | 17 | 1490 |
| n8n | 5678 | 5678 | - | - |
| Obsidian | 8090 | 8090 | - | - |
| Qdrant | 6334 | 6334 | - | - |
| Syncthing | 8384 | 8384 | 17 | 60 |
| Tailscale | - | - | 18 | 157 |
| Tailscale Docker Proxy | - | - | 17 | 82 |
| Vaultwarden | 8000 | 8000 | 8 | 316 |

## Recommendable Build Flow

```mermaid
flowchart TD
  Start([🚀 ビルド開始]) --> A

  A["🐳 **1. Dockhand**\nDockerを快適に利用するために"]
  B["🔒 **2. Tailscale**\nVPNの動作を確認するために"]
  C["🔀 **3. Tailscale Docker Proxy**\nVPNの動作を確認するために"]
  D["📁 **4. File Browser**\nファイルシステム全般の権限を確認するために"]
  E["🗄️ **5. Memos**\nPostgreSQLの権限を確認するために"]
  F["⚙️ **6. その他...**"]

  A --> B
  B --> C
  C --> D
  D --> E
  E --> F
  F --> End

  End([✅ ビルド完了])

  subgraph VPN検証["🔒 VPN検証グループ"]
    B
    C
  end

  style Start fill:#4CAF50,color:#fff,stroke:none
  style End fill:#2196F3,color:#fff,stroke:none
  style A fill:#FF9800,color:#fff,stroke:none
  style B fill:#9C27B0,color:#fff,stroke:none
  style C fill:#9C27B0,color:#fff,stroke:none
  style D fill:#00BCD4,color:#fff,stroke:none
  style E fill:#F44336,color:#fff,stroke:none
  style F fill:#607D8B,color:#fff,stroke:none
  style VPN検証 fill:#f3e5f5,stroke:#9C27B0,stroke-width:2px
```
