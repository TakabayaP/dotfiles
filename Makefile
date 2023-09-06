.PHONY: all
all: set-nvim set-fish set-bashrc set-alacritty set-git

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
	@echo "Complete setting alacritty!"

.PHONY: set-git
set-git:
	@echo "Setting up git..."
	@set -a && source $${PWD}/secrets.env && set +a \
	&& sed -e 's/SECRET_GIT_NAME/'$${GIT_NAME}'/g' -e 's/SECRET_GIT_EMAIL/'$${GIT_EMAIL}'/g' dotfiles/git/.gitconfig > dotfiles/git/.gitconfig.tmp 
	@ln -sv $${PWD}/dotfiles/git/.gitconfig.tmp $${HOME}/.gitconfig || true
	@echo "Complete setting git!"