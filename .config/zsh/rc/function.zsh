#==============================================================#
##         New Commands                                      ##
#==============================================================#
function getpids() {
  echo `ps x | grep $1 | awk '{print $1}'`
}

function du-ah() {
  # e.g. du-ah / 20
  du -ah $1 | sort -rh | head -n $2
}

function git-erase() {
  # e.g. git-erase credential.json
  git filter-branch --force --index-filter "git rm --cached --ignore-unmatch $1" -- --all
}
