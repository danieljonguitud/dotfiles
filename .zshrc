# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Aliases
alias vim="nvim"
alias python=/usr/bin/python3
alias drs="darwin-rebuild switch --flake ~/dotfiles/nix/darwin#simple"

export AWS_PROFILE=daniel-dev

export PATH=$PATH:$HOME/.local/opt/go/bin

export CONFIG_DIR='~/.config'
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" # This loads nvm
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/dj/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
