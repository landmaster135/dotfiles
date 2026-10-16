# Usage

## Install scripts

```bash
rsync -avz <install_file_path> <user>@<remote-host>:/tmp/
ssh <user>@<remote-host> "sudo bash /tmp/<install_file_path>"
```

## Docker Compose

```bash
rsync -avz --progress --delete <docker_compose_project_dir_path>/ <user>@<remote-host>:~/docker-compose-projects/
ssh <user>@<remote-host> "cd ~/docker-compose-projects/<project_name> && sudo docker compose up -d"
```

Build Dockhand container

```bash
ssh <user>@<remote-host> "cd ~/docker-compose-projects/dockhand && sudo docker compose up -d"
```
