# bash login shells read this and skip .profile once it exists, so hand straight
# off to .profile, which loads .bashrc. On linux that changes nothing; on the mac,
# where Terminal opens login shells, it's the only way .bashrc gets loaded.
[ -f ~/.profile ] && . ~/.profile
