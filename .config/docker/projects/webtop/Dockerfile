FROM lscr.io/linuxserver/webtop:ubuntu-kde

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y git python3 python3-pip

RUN apt-get -y install fonts-takao

ENV PATH "$PATH:/config/.local/bin"
