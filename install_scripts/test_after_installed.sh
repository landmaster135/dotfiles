#!/usr/bin/env bash

#--------------------------------------------------------------#
##          Snippets                                          ##
#--------------------------------------------------------------#

snippet --help
snippet -h
snippet apt --commands-for-disk
snippet common
snippet docker --aliases
snippet docker --build-options
snippet docker --options
snippet docker --run-options
snippet docker --subcommands
snippet git --diff-options
snippet git --options
snippet git --subcommands
snippet psql --commands
snippet tmux --options
snippet tmux --subcommands
snippet general

#--------------------------------------------------------------#
##          Aliases                                           ##
#--------------------------------------------------------------#

# common
tree
nano
echo 'test' > test.txt; echo mkdir test1;
cl
wc-l
ps-fa

# ls
la
l1
lal
# lsoi

# grep
ls | grep .
ls | fgrep .
ls | egrep .
histgrep .
ps-grep .

# disk
df
du-sh
rm-cache
rm-auto
rm-log
emptrash

# git
# skip ...

# chmod
644 test.txt
755 test.txt
777 test.txt
