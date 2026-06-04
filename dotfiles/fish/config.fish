set -g fish_greeting
alias vim='nvim'
alias vi='nvim'
alias cat='bat --paging never'
alias gf='git push -f'
alias cdg='cd $(git rev-parse --show-toplevel)'

# Added by LM Studio CLI tool (lms)
set -gx PATH $PATH /Users/katsumi.kobayashi/.lmstudio/bin
