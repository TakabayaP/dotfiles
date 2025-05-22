if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_greeting
end

alias vim='nvim'
alias vi='nvim'
alias cat='bat --paging never'
alias gf='git push -f'
alias cdg='cd $(git rev-parse --show-toplevel)'
