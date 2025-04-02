#!make
-include settings.env
-include secrets.env

LINK_FILE=ln -sv

.PHONY: all
ifeq ($(UNAME_S), Darwin)
all: set-nvim set-fish set-bashrc set-alacritty set-git set-aerospace
else
all: set-nvim set-fish set-bashrc set-alacritty set-git set-i3 set-picom set-redshift set-dunst 
endif

.PHONY: force-all
force-all: 
	@echo "Force setting up all..."
	$(LINK_FILE)='ln -sfv'
	all	

.PHONY: install-yay
install-yay:
	@echo "Installing yay..."
	@sudo pacman -S --noconfirm git base-devel fakeroot make gcc
	@git clone https://aur.archlinux.org/yay.git
	@cd yay && makepkg -si --noconfirm && cd ..
	@rm -rf yay
	@echo "Complete installing yay!"

.PHONY: set-fish
set-fish:
	@echo "Setting up fish..."
	@mkdir -p $${HOME}/.config/fish
	# true is used to ignore error if the file already exists
	@$(LINK_FILE) $${PWD}/dotfiles/fish/config.fish $${HOME}/.config/fish/config.fish || true
	@echo "Complete setting fish!"

.PHONY: set-nvim
set-nvim:
	@echo "Setting up nvim..."
	@mkdir -p $${HOME}/.config/nvim
	@mkdir -p $${HOME}/.nvim/tmp
	# true is used to ignore error if the file already exists
	@$(LINK_FILE) $${PWD}/dotfiles/nvim/init.vim $${HOME}/.config/nvim/init.vim || true
	@echo "Complete setting nvim!"

.PHONY: set-bashrc
set-bashrc:
	@echo "Setting up bashrc..."
	@$(LINK_FILE) $${PWD}/dotfiles/bashrc/.bashrc $${HOME}/.bashrc || true
	@echo "Complete setting bashrc!"	

.PHONY: set-alacritty
set-alacritty:
	@echo "Setting up alacritty..."
	@mkdir -p $${HOME}/.config/alacritty
	# true is used to ignore error if the file already exists
	@$(LINK_FILE) $${PWD}/dotfiles/alacritty/alacritty.toml $${HOME}/.config/alacritty/alacritty.toml || true
	@echo "Installing alacritty theme..."
	@rm -rf $${HOME}/.config/alacritty/themes
	@mkdir -p $${HOME}/.config/alacritty/themes
	@git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
	@echo "Complete setting alacritty!"

.PHONY: set-git
set-git:
	@echo "Setting up git..."
	@read -p 'Enter git name: ' gitname; \
	read -p 'Enter git email: ' gitemail; \
	sed -e 's/SECRET_GIT_NAME/'$${gitname}'/g' -e 's/SECRET_GIT_EMAIL/'$${gitemail}'/g' dotfiles/git/.gitconfig > dotfiles/git/.gitconfig.tmp 
	@$(LINK_FILE) $${PWD}/dotfiles/git/.gitconfig.tmp $${HOME}/.gitconfig || true
	@echo "Complete setting git!"

.PHONY: set-i3
set-i3:
	@echo "Setting up i3..."
	@mkdir -p $${HOME}/.config/i3
	@sed \
		-e 's,XRANDR_SCREEN_SETTING_COMMAND,'${XRANDR_SCREEN_SETTING_COMMAND}',g' \
		-e 's,BACKGROUND_IMAGE_PATH,'${BACKGROUND_IMAGE_PATH}',g' \
		-e 's,I3_WORKSPACE_NUMBER_SETTINGS,'${I3_WORKSPACE_NUMBER_SETTINGS}',g' \
		dotfiles/i3/config> dotfiles/i3/config.tmp
	@$(LINK_FILE) $${PWD}/dotfiles/i3/config.tmp $${HOME}/.config/i3/config || true
	@echo "Complete setting i3!"

.PHONY: set-picom
set-picom:
	@echo "Setting up picom..."
	@mkdir -p $${HOME}/.config/picom
	@$(LINK_FILE) $${PWD}/dotfiles/picom/picom.conf $${HOME}/.config/picom/picom.conf || true
	@echo "Complete setting picom!"

.PHONY: set-redshift
set-redshift:
	@echo "Setting up redshift..."
	@mkdir -p $${HOME}/.config/redshift
	@$(LINK_FILE) $${PWD}/dotfiles/redshift/redshift.conf $${HOME}/.config/redshift.conf || true
	@echo "Complete setting redshift!"

.PHONY: set-dunst
set-dunst:
	@echo "Setting up dunst..."
	@mkdir -p $${HOME}/.config/dunst
	@$(LINK_FILE) $${PWD}/dotfiles/dunst/dunstrc $${HOME}/.config/dunst/dunstrc || true
	@echo "Complete setting dunst!"

.PHONY: set-aerospace
ifeq ($(UNAME_S), Darwin)
set-aerospace:
	@echo "Setting up aerospace..."
	@echo "You are not using macOS"
else
set-aerospace:
	@echo "Setting up aerospace..."
	@mkdir -p $${HOME}/.config/aerospace
	@$(LINK_FILE) $${PWD}/dotfiles/aerospace/aerospace.toml $${HOME}/.config/aerospace/aerospace.toml || true
	@echo "Complete setting aerospace!"
endif