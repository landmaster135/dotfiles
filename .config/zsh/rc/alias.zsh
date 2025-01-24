#==============================================================#
##          General aliases                                   ##
#==============================================================#

# common
alias tree="pwd;find . | sort | sed '1d;s/^\.//;s/\/\([^/]*\)$/|--\1/;s/\/[^/|]*/| /g'"
alias nano='nano -m'
alias mv='mv -i'
alias cp='cp -irf'
alias cl='clear'
alias wc-l='awk '\''END { print NR, FILENAME }'\'''
alias fc='fc -r'
alias ..='cd ..'
alias ps-fa='ps -fA'

# ls
alias ls='ls --color=auto'
alias la='ls -AF --color=auto'
alias l1='ls -1A --color=auto'
alias lal='ls -alF --color=auto'
alias lsoi='lsof -i'

# grep
alias grep='grep -H -n -I --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias histgrep='history | grep'
alias ps-grep='ps -fA | grep -e UID -e'

# disk
alias df='df -h'
alias du='du -sh'
alias rm-cache='apt-get clean' # Clear cache of apt packages. (But that access is denied in Cloud Shell due to insufficient permissions.)
alias rm-auto='apt-get autoremove' # Remove unnecessary packages that have no dependencies.
alias rm-log='sudo journalctl --vacuum-time=2weeks' # Remove unnecessary log files. System log files are retained for an extended period.
alias emptrash='rm -rf ~/.local/share/Trash/*' # Empty rubbish bin.

# git
alias git-ba='git branch -a'
alias git-a='git add .'
alias git-c='git commit -m'
alias git-publish='BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD); git push --set-upstream origin "$BRANCH_NAME"; unset BRANCH_NAME;'
alias git-push-afo='git push --all --force origin'

# chmod
alias 644='chmod 644'
alias 755='chmod 755'
alias 777='chmod 777'

#==============================================================#
##          Python aliases                                    ##
#==============================================================#

# pip
alias pip-i='pip install --no-cache-dir'
alias pip-ip='pip install --no-cache-dir -r requirements.txt'
alias pip-id='pip install --no-cache-dir -r requirements/dev.txt'
alias pip-vu='pip -V; sudo python3 -m pip install --upgrade pip'
alias pip-l='pip list'

# virtual env
alias py-ve='python -m venv .venv'
alias py-va='source .venv/bin/activate'
alias py-vd='deactivate'
alias py-vi='py-ve; py-va; pip-id;'

# uvicorn
alias uvi='uvicorn app:app --reload --port 8000 --host 0.0.0.0'
alias uvi-kill='sudo lsof -t -i tcp:8000 | xargs kill -9'

# python
alias py='python'
alias py-sa='python src/app.py'
alias py-sm='python src/main.py'

# pytest
alias pyt-d='python -m pytest --durations=0 --tb=short'
alias pyt-c='python -m pytest --cov=src --cov-branch --tb=short'
alias pyt-r='python -m pytest -n auto --cov=src --cov-branch --cov-report=html --tb=short'

#==============================================================#
##          PostgreSQL aliases                                ##
#==============================================================#

# setting
alias getja='sudo apt-get install language-pack-ja -y'

# postgresql
alias pg-re='sudo /sbin/service postgresql restart'
alias pg-start='sudo /sbin/service postgresql start'
alias pg-stop='sudo /sbin/service postgresql stop'
alias su-pg='sudo su - postgres'
alias pg-status='sudo /sbin/service postgresql status'

#==============================================================#
##          Gcloud aliases                                    ##
#==============================================================#

# common
alias gc='gcloud'
alias gc-fd='gcloud functions deploy'
alias gc-sjc='gcloud scheduler jobs create'
alias gc-init='gcloud init'
alias gc-initco='gcloud init --console-only'
alias gc-auth='gcloud auth application-default login'

# cloud shell editor
# alias teachme='cloudshell launch-tutorial'

#==============================================================#
##          Go aliases                                        ##
#==============================================================#

# Go
alias go-list='go list -m -u all'
alias go-mi='go mod init'
alias go-mt='go mod tidy'
alias go-t='go test -v -coverpkg=./mypkg ./...'
alias go-b='go build'
alias go-predeploy='cd mypkg; go mod init a.b/mypkg; go mod tidy; cd ..'
