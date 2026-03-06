# Usage

## Install scripts

```bash
rsync -avz <install_file_path> user@remote-host:/tmp/
ssh user@remote-host "sudo bash /tmp/<install_file_path>"
```

## Docker Compose

```bash
rsync -avz --progress --delete <docker_compose_project_dir_path>/ user@remote-host:~/999_app_for_nas/dockhand/data/stacks/
ssh user@remote-host "cd ~/999_app_for_nas/dockhand/data/stacks/<project_name> && sudo docker compose up -d"
```
