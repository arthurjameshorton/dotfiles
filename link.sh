#!/usr/bin/env bash
# Symlink the dotfiles listed below from this repo into $HOME.
#
# Safe to re-run: links that already point here are left alone, and anything
# else in the way is renamed to <name>.bak-<timestamp> rather than overwritten,
# so nothing is lost. The gitignored *.local files are skipped when missing
# (a fresh clone, e.g. on the mac, won't have them until you make them).
#
# Sticks to bash 3.2 features since that's what the mac ships.
set -eu

# An explicit list rather than globbing the repo, so strays like .zcompdump or
# a mac .DS_Store never get linked into $HOME. Add new dotfiles here.
names=(
    .profile
    .bash_profile
    .bashrc
    .zshrc
    .bash_aliases
    .bash_aliases.local
    .gitconfig
    .gitconfig.local
)

# Wherever this checkout lives (/work on the linux boxes, somewhere in ~ on the
# mac), rather than a hard-coded path.
repo_dir=$(cd "$(dirname "$0")" && pwd -P)
stamp=$(date +%Y%m%d-%H%M%S)

for name in "${names[@]}"; do
    src="$repo_dir/$name"
    dest="$HOME/$name"

    if [ ! -e "$src" ]; then
        echo "skip    $name (not in $repo_dir)"
        continue
    fi

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok      $dest"
        continue
    fi
    # -L as well as -e so a dangling link gets moved aside too
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        mv "$dest" "$dest.bak-$stamp"
        echo "moved   $dest -> $dest.bak-$stamp"
    fi
    ln -s "$src" "$dest"
    echo "linked  $dest -> $src"
done
