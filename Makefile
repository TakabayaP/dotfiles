#!make
-include settings.env
-include secrets.env

.PHONY: all
all: set-nvim set-fish set-bashrc set-alacritty set-git

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
	@ln -sv $${PWD}/dotfiles/fish/config.fish $${HOME}/.config/fish/config.fish || true
	@echo "Complete setting fish!"

.PHONY: set-nvim
set-nvim:
	@echo "Setting up nvim..."
	@mkdir -p $${HOME}/.config/nvim
	# true is used to ignore error if the file already exists
	@ln -sv $${PWD}/dotfiles/nvim/init.vim $${HOME}/.config/nvim/init.vim || true
	@echo "Complete setting nvim!"

.PHONY: set-bashrc
set-bashrc:
	@echo "Setting up bashrc..."
	@ln -sv $${PWD}/dotfiles/bashrc/.bashrc $${HOME}/.bashrc || true
	@echo "Complete setting bashrc!"	

.PHONY: set-alacritty
set-alacritty:
	@echo "Setting up alacritty..."
	@mkdir -p $${HOME}/.config/alacritty
	# true is used to ignore error if the file already exists
	@ln -sv $${PWD}/dotfiles/alacritty/alacritty.yml $${HOME}/.config/alacritty/alacritty.yml || true
	@echo "Installing alacritty theme..."
	@mkdir -p $${HOME}/.config/alacritty/themes
	@git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
	@echo "Complete setting alacritty!"

.PHONY: set-git
	set-git:
	@echo "Setting up git..."
	@set -a && source $${PWD}/secrets.env && set +a \
	&& sed -e 's/SECRET_GIT_NAME/'$${GIT_NAME}'/g' -e 's/SECRET_GIT_EMAIL/'$${GIT_EMAIL}'/g' dotfiles/git/.gitconfig > dotfiles/git/.gitconfig.tmp 
	@ln -sv $${PWD}/dotfiles/git/.gitconfig.tmp $${HOME}/.gitconfig || true
	@echo "Complete setting git!"

.PHONY: set-i3
set-i3:
	@echo "Setting up i3..."
	@mkdir -p $${HOME}/.config/i3
	@sed -e 's,XRANDR_SCREEN_SETTING_COMMAND,'${XRANDR_SCREEN_SETTING_COMMAND}',g' -e 's,BACKGROUND_IMAGE_PATH,'${BACKGROUND_IMAGE_PATH}',g' dotfiles/i3/config> dotfiles/i3/config.tmp
	@ln -sv $${PWD}/dotfiles/i3/config.tmp $${HOME}/.config/i3/config || true
	@echo "Complete setting i3!"

.PHONY: set-picom
set-picom:
	@echo "Setting up picom..."
	@mkdir -p $${HOME}/.config/picom
	@ln -sv $${PWD}/dotfiles/picom/picom.conf $${HOME}/.config/picom/picom.conf || true
	@echo "Complete setting picom!"

.PHONY: set-redshift
set-redshift:
	@echo "Setting up redshift..."
	@mkdir -p $${HOME}/.config/redshift
	@ln -sv $${PWD}/dotfiles/redshift/redshift.conf $${HOME}/.config/redshift.conf || true
	@echo "Complete setting redshift!"