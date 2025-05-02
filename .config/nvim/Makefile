# Define the source and target directories
SOURCE_DIR := $(HOME)/nvim/.config
TARGET_DIR := $(HOME)/.config

# Define the list of files to symlink and their respective source locations
AEROSPACE_SOURCE := $(SOURCE_DIR)/nvim/aerospace
SKETCHYBAR_SOURCE := $(SOURCE_DIR)/nvim/sketchybar
WEZTERM_SOURCE := $(SOURCE_DIR)/nvim/.wezterm.lua
ZSH_SOURCE := $(SOURCE_DIR)/nvim/.zshrc

# Define the target locations for each config file
AEROSPACE_TARGET := $(TARGET_DIR)/aerospace
SKETCHYBAR_SOURCE := $(TARGET_DIR)/sketchybar
WEZTERM_TARGET := $(HOME)/.wezterm.lua
ZSH_TARGET := $(HOME)/.zshrc

# Default target
.PHONY: all
all: symlinks

# Create symlinks for each config file
.PHONY: symlinks
symlinks: install-oh-my-zsh install-brew install-neovim install-wezterm install-aerospace install-janky-borders install-sketchybar symlink-aerospace symlink-sketchybar symlink-wezterm symlink-zsh install-theme
	@echo "Setup complete!"

.PHONY: install-oh-my-zsh
install-oh-my-zsh:
	@echo "Checking for oh my zsh..."
	@if ! command -v brew >/dev/null; then \
		echo "Installing Homebrew..."; \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
	else \
		echo "Oh my zsh is already installed."; \
	fi

.PHONY: install-brew
install-brew:
	@echo "Checking for Homebrew..."
	@if ! command -v brew >/dev/null; then \
		echo "Installing Homebrew..."; \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
	else \
		echo "Homebrew is already installed."; \
	fi

.PHONY: install-neovim
install-neovim:
	@echo "Checking for Neovim..."
	@if ! command -v nvim >/dev/null; then \
		echo "Installing Neovim..."; \
		brew install neovim; \
	else \
		echo "Neovim is already installed."; \
	fi

.PHONY: install-wezterm
install-wezterm:
	@echo "Checking for Wezterm..."
	@if ! command -v wezterm >/dev/null; then \
		echo "Installing Wezterm..."; \
		brew install --cask wezterm; \
	else \
		echo "Wezterm is already installed."; \
	fi

.PHONY: install-aerospace
install-aerospace:
	@echo "Checking for Aerospace..."
	@if ! command -v aerospace >/dev/null; then \
		echo "Installing Aerospace..."; \
		brew install --cask nikitabobko/tap/aerospace; \
	else \
		echo "Wezterm is already installed."; \
	fi

.PHONY: install-janky-borders
install-janky-borders:
	@echo "Checking for Janky Borders..."
	@if ! command -v borders >/dev/null; then \
		echo "Installing AJanky Borders..."; \
		brew tap FelixKratz/formulae; \
		brew install borders; \
	else \
		echo "Janky Borders is already installed."; \
	fi

.PHONY: install-sketchybar
install-sketchybar:
	@echo "Checking for Sketchybar..."
	@if ! command -v borders >/dev/null; then \
		echo "Installing Sketchybar..."; \
		brew tap FelixKratz/formulae; \
		brew install sketchybar; \
	else \
		echo "Sketchybar is already installed."; \
	fi

.PHONY: install-theme
install-theme:
	@echo "Checking for powerlevel10k..."
	@if ! command -v borders >/dev/null; then \
		echo "Installing powerlevel10k..."; \
		brew install powerlevel10k; \
	else \
		echo "powerlevel10k is already installed."; \
	fi

# Specific rules to create symlink for each file
.PHONY: symlink-aerospace
symlink-aerospace: 
	@echo "Creating symlink for aerospace"
	@ln -sfn $(AEROSPACE_SOURCE) $(AEROSPACE_TARGET)

.PHONY: symlink-sketchybar
symlink-sketchybar: 
	@echo "Creating symlink for sketchybar"
	@ln -sfn $(SKETCHYBAR_SOURCE) $(SKETCHYBAR_TARGET)

.PHONY: symlink-wezterm
symlink-wezterm:
	@echo "Creating symlink for wezterm"
	@ln -sf $(WEZTERM_SOURCE) $(WEZTERM_TARGET)

.PHONY: symlink-zsh
symlink-zsh:
	@echo "Creating symlink for zsh"
	@ln -sf $(ZSH_SOURCE) $(ZSH_TARGET)

# Clean symlinks (does not remove the original config files)
.PHONY: clean
clean:
	@echo "Removing symlinks..."
	@rm -rf $(YABAI_TARGET) $(AEROSPACE_TARGET) $(WEZTERM_TARGET)

# Install configuration (create symlinks)
.PHONY: install
install: symlinks
	@echo "Configuration installed!"

# Uninstall configuration (remove symlinks)
.PHONY: uninstall
uninstall: clean
	@echo "Configuration uninstalled!"
