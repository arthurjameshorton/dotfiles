alias gs="git status"
alias gapi="git add --patch --interactive"
alias update="git pull; git submodule update --init --recursive"
alias clean="git clean -d -f ."
alias next="git rebase --continue"
# Run a PR search and print the hits as a table of REPO / ID / TITLE / MERGE.
#   $1  the search query (same syntax as GitHub's search box)
#   $2  header of an extra column to append, if you want one
#   $3  jq expression producing that column's cell, given a PullRequest
_pr_table() {
  local headers='REPO\tID\tTITLE\tMERGE'
  local row='[.repository.name, ("#"+(.number|tostring)), .title, (.headRefName + " -> " + .baseRefName)]'
  if [ -n "$2" ]; then
    headers="$headers\t$2"
    row="$row + [$3]"
  fi

  # gh search prs doesn't expose head/base branch fields, so use the
  # GraphQL search instead -- one call gets the PRs and their branches.
  # The query goes in as a GraphQL variable rather than being interpolated
  # into the query text, so quoting in $1 is jq's problem and not the shell's.
  gh api graphql -f q="$1" -f query='
    query($q: String!) {
      search(query: $q, type: ISSUE, first: 100) {
        nodes {
          ... on PullRequest {
            number
            title
            headRefName
            baseRefName
            reviewDecision
            repository { name }
          }
        }
      }
    }' \
    --jq ".data.search.nodes[] | $row | @tsv" |
  # Render our own table so the header underline spans each whole column
  # (gh's tablerender only underlines the header text, not the padding).
  awk -F'\t' -v headers="$headers" '
    BEGIN {
      nh = split(headers, H, "\t")
      for (i = 1; i <= nh; i++) w[i] = length(H[i])
    }
    {
      for (i = 1; i <= NF; i++) {
        cell[NR, i] = $i
        if (length($i) > w[i]) w[i] = length($i)
      }
      nrows = NR
    }
    END {
      line = ""
      for (i = 1; i <= nh; i++)
        line = line "\033[0;2;4;37m" sprintf("%-*s", w[i], H[i]) "\033[0m" (i < nh ? "  " : "")
      print line
      for (r = 1; r <= nrows; r++) {
        line = ""
        for (i = 1; i <= nh; i++) {
          pad = sprintf("%-*s", w[i], cell[r, i])
          if (i == 2) pad = "\033[0;32m" pad "\033[0m"   # green PR id
          line = line pad (i < nh ? "  " : "")
        }
        print line
      }
    }
  '
}

export PATH="$HOME/.scripts:$PATH"
export PATH="/usr/local/cuda/:$PATH"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'



    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

    # matching text is light orange instead of red
    export GREP_COLORS='mt=38;5;214'
fi

# outside the dircolors check because mac doesn't have dircolors: GNU ls takes
# --color, mac's BSD ls takes -G instead
if ls --color=auto /dev/null &>/dev/null; then
    alias ls='ls -p --color=auto'
else
    alias ls='ls -p -G'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'


# I realize this file is called bash_aliases, and this
# is not an alias and the very presence of this if
# statement means it's not always bash. That being
# said, I'd like the same aliases in both bash and
# zsh so I want to include this in both places and
# also since the vanila bashrc already includes this
# file if it exists this seemed like the short term path
# of least resistance

if [ -n "$BASH_VERSION" ]; then

# print a colorized diff
	colordiff() {
	        local red=$(tput setaf 1 2>/dev/null)
	        local green=$(tput setaf 2 2>/dev/null)
	        local cyan=$(tput setaf 6 2>/dev/null)
	        local reset=$(tput sgr0 2>/dev/null)

	        diff -u "$@" | awk "
	        /^\-/ {
	                printf(\"%s\", \"$red\");
	        }
	        /^\+/ {
	                printf(\"%s\", \"$green\");
	        }
	        /^@/ {
	                printf(\"%s\", \"$cyan\");
	        }

	        {
	                print \$0 \"$reset\";
	        }"

	        return "${PIPESTATUS[0]}"
	}
fi

# Work- and machine-specific aliases/functions live here, gitignored so they
# never land in the public repo. Both bash and zsh get them via this file.
if [ -f ~/.bash_aliases.local ]; then
    . ~/.bash_aliases.local
fi
