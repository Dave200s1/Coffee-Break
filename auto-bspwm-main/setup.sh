#!/usr/bin/bash

# Author: David Stefanov 

# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Global variables
dir=$(pwd)
fdir="$HOME/.local/share/fonts"
user=$(whoami)

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n${redColour}[!] Exiting...\n${endColour}"
	exit 1
}

function banner() {
    echo -e "\n${turquoiseColour}     (  )   (   )  )"
    sleep 0.05
    echo -e "     ) (   )  (  ("
    sleep 0.05
    echo -e "     ( )  (    ) )"
    sleep 0.05
    echo -e "     _____________"
    sleep 0.05
    echo -e "    <_____________> ___"
    sleep 0.05
    echo -e "    |             |/ _ \\"
    sleep 0.05
    echo -e "    |               | | |"
    sleep 0.05
    echo -e "    |               |_| |"
    sleep 0.05
    echo -e " ___|             |\\___/"
    sleep 0.05
    echo -e "/    \\___________/    \\"
    sleep 0.05
    echo -e "\\_____________________/${endColour}"
}

if [ "$user" == "root" ]; then
	banner
	echo -e "\n\n${redColour}[!] You should not run the script as the root user!\n${endColour}"
    	exit 1
else
	banner
	sleep 1
	
	# Enable AUR support in pamac
	echo -e "\n${blueColour}[*] Enabling AUR support in pamac...${endColour}"
	sleep 2
	
	# Verbesserte AUR-Aktivierung
	sudo sed -i '/^#EnableAUR/ s/^#//' /etc/pamac.conf 2>/dev/null
	if ! grep -q '^EnableAUR' /etc/pamac.conf; then
		echo 'EnableAUR' | sudo tee -a /etc/pamac.conf >/dev/null
	fi
	echo -e "${greenColour}[+] AUR support verified${endColour}"
	sleep 1.5

	# Installiere Build-Essentials
	echo -e "\n${blueColour}[*] Installing build essentials...${endColour}"
	sudo pacman -S --needed --noconfirm base-devel git 2>/dev/null
	echo -e "${greenColour}[+] Build tools installed${endColour}"
	sleep 1.5

	echo -e "\n\n${blueColour}[*] Installing necessary packages for the environment...\n${endColour}"
	sleep 2
	
	# Install official packages
	echo -e "${blueColour}[*] Installing official packages...${endColour}"
	sudo pacman -S --noconfirm alacritty chromium rofi feh xclip ranger scrot wmname imagemagick cmatrix htop neofetch python-pip procps-ng fzf lsd bat pamixer flameshot clang curl ttf-font-awesome ninja python-pywal
	official_exit=$?
	
	# Install AUR packages with individual error handling
	echo -e "\n${yellowColour}[*] Installing AUR packages (may take several minutes)...${endColour}"
	
	# Funktion für AUR-Installation mit erweitertem Logging
	install_aur_pkg() {
		local pkg=$1
		echo -e "\n${blueColour}[*] Installing $pkg...${endColour}"
		
		# Erster Versuch mit Pamac
		if pamac build --no-confirm "$pkg" 2>&1 | tee /tmp/aur_install.log; then
			echo -e "${greenColour}[+] $pkg installed successfully via Pamac${endColour}"
			return 0
		else
			echo -e "${yellowColour}[!] Pamac failed for $pkg, trying manual installation...${endColour}"
			
			# Manueller Installationsversuch
			cd /tmp || return 1
			git clone "https://aur.archlinux.org/${pkg}.git"
			cd "$pkg" || {
				echo -e "${redColour}[-] Failed to enter $pkg directory!${endColour}"
				cd "$dir"
				return 1
			}
			
			# Spezielle Behandlung für i3lock-fancy-git
			if [[ "$pkg" == "i3lock-fancy-git" ]]; then
				sudo pacman -S --needed --noconfirm jq  # Zusätzliche Abhängigkeit
			fi
			
			makepkg -si --noconfirm
			makepkg_status=$?
			cd "$dir"
			
			if [ $makepkg_status -eq 0 ]; then
				echo -e "${greenColour}[+] $pkg manually installed successfully${endColour}"
				return 0
			else
				echo -e "${redColour}[-] Manual installation failed for $pkg${endColour}"
				return 1
			fi
		fi
	}

	# Installiere Pakete einzeln mit verbesserter Fehlerbehandlung
	aur_exit=0
	failed_pkgs=()
	for pkg in scrub i3lock-fancy-git tty-clock; do
		if ! install_aur_pkg "$pkg"; then
			failed_pkgs+=("$pkg")
			aur_exit=1
		fi
	done
	
	# Zeige fehlgeschlagene Pakete an
	if [ ${#failed_pkgs[@]} -gt 0 ]; then
		echo -e "\n${redColour}[-] Failed to install: ${failed_pkgs[*]}${endColour}"
		echo -e "${yellowColour}[!] You can try manual installation with:"
		echo -e "cd /tmp && git clone https://aur.archlinux.org/<package>.git"
		echo -e "cd <package> && makepkg -si${endColour}"
	fi
	
	# Check both installation results
	if [ $official_exit -ne 0 ] || [ $aur_exit -ne 0 ]; then
		echo -e "\n${redColour}[-] Some packages failed to install! Continuing with setup...${endColour}"
		sleep 3
	else
		echo -e "\n${greenColour}[+] All packages installed successfully${endColour}"
		sleep 1.5
	fi
 
	echo -e "\n${blueColour}[*] Starting installation of necessary dependencies for the environment...\n${endColour}"
	sleep 0.5

	echo -e "\n${purpleColour}[*] Installing necessary dependencies for bspwm...\n${endColour}"
	sleep 2
	# Install dependencies using pacman
 	sudo pacman -S --needed libxcb xcb-util xcb-util-wm xcb-util-keysyms
	exit_code=$?
	
	if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
		echo -e "\n${redColour}[-] Failed to install some dependencies for bspwm!\n${endColour}"
		exit 1
	else
		echo -e "\n${greenColour}[+] Done\n${endColour}"
		sleep 1.5
	fi

	echo -e "\n${purpleColour}[*] Installing necessary dependencies for polybar...\n${endColour}"
	sleep 2

	sudo pacman -S --needed --noconfirm cmake pkgconf python-sphinx cairo libxcb xcb-util libxcb xcb-proto  xcb-util-image xcb-util-wm libxkbcommon-x11 xcb-util-cursor libpulse jsoncpp libmpdclient curl libnl
	exit_code=$?
	if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
		echo -e "\n${redColour}[-] Failed to install some dependencies for polybar!\n${endColour}"
		exit 1
	else
		echo -e "\n${greenColour}[+] Done\n${endColour}"
		sleep 1.5
	fi

	echo -e "\n${purpleColour}[*] Installing necessary dependencies for picom...\n${endColour}"
	sleep 2

	sudo pacman -S --needed --noconfirm meson libxext libxcb xcb-util-renderutil xcb-util-image pixman dbus libconfig mesa pcre2 pcre libevdev uthash libev libx11 
	exit_code=$?
	
	if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
		echo -e "\n${redColour}[-] Failed to install some dependencies for picom!\n${endColour}"
		exit 1
	else
		echo -e "\n${greenColour}[+] Done\n${endColour}"
		sleep 1.5
	fi

	echo -e "\n${blueColour}[*] Starting installation of the tools...\n${endColour}"
	sleep 0.5
	mkdir -p ~/tools && cd ~/tools || exit

	echo -e "\n${purpleColour}[*] Installing bspwm...\n${endColour}"
	sleep 2
	# Check if bspwm is already installed via package manager
	if ! command -v bspwm &> /dev/null; then
		# Clone and build from source
		git clone https://github.com/baskerville/bspwm.git
		cd bspwm || { echo -e "\n${redColour}[-] Failed to enter bspwm directory!\n${endColour}"; exit 1; }
		make -j$(nproc)
		sudo make install
		install_status=$?
		
		if [ $install_status -ne 0 ] && [ $install_status -ne 130 ]; then
			echo -e "\n${redColour}[-] Failed to build and install bspwm from source!\n${endColour}"
			# Attempt to install from official repositories as fallback
			echo -e "\n${yellowColour}[*] Attempting to install from official repositories...\n${endColour}"
			sudo pacman -S --noconfirm bspwm
			if [ $? -ne 0 ]; then
				echo -e "\n${redColour}[-] Failed to install bspwm!\n${endColour}"
				exit 1
			fi
		fi
		cd ..
	else
		echo -e "\n${yellowColour}[!] bspwm is already installed. Skipping...\n${endColour}"
	fi

	echo -e "\n${greenColour}[+] bspwm installed successfully\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Installing sxhkd...\n${endColour}"
	sleep 2
	# Check if sxhkd is already installed
	if ! command -v sxhkd &> /dev/null; then
		git clone https://github.com/baskerville/sxhkd.git
		cd sxhkd || { echo -e "\n${redColour}[-] Failed to enter sxhkd directory!\n${endColour}"; exit 1; }
		make -j$(nproc)
		sudo make install
		if [ $? -ne 0 ] && [ $? -ne 130 ]; then
			echo -e "\n${redColour}[-] Failed to install sxhkd!\n${endColour}"
			exit 1
		else
			echo -e "\n${greenColour}[+] Done\n${endColour}"
			sleep 1.5
		fi
		cd ..
	else
		echo -e "\n${yellowColour}[!] sxhkd is already installed. Skipping...\n${endColour}"
	fi

	echo -e "\n${purpleColour}[*] Installing polybar...\n${endColour}"
	sleep 2

	# Check if polybar is already installed
	if ! command -v polybar &> /dev/null; then
	    # Clean previous attempts completely
	    rm -rf ~/tools/polybar ~/tools/polybar-build 2>/dev/null
	    
	    # Install ALL required dependencies
	    echo -e "${blueColour}[*] Installing comprehensive dependencies...${endColour}"
	    sudo pacman -S --needed --noconfirm \
	        freetype2 libxft pango cairo xcb-proto xcb-util-image \
	        xcb-util-wm xcb-util-cursor alsa-lib libpulse jsoncpp \
	        libmpdclient curl libnl libuv wireless_tools
	
	    # First try AUR installation with explicit freetype linking
	    echo -e "${blueColour}[*] Attempting optimized AUR installation...${endColour}"
	    if LDFLAGS="-lfreetype" pamac build --no-confirm polybar-git; then
	        echo -e "${greenColour}[+] polybar installed successfully via AUR${endColour}"
	    else
	        echo -e "${redColour}[-] AUR installation failed, trying manual build...${endColour}"
	        
	        # Manual build with proper directory handling
	        mkdir -p ~/tools/polybar-build
	        cd ~/tools/polybar-build
	        
	        git clone --depth 1 --recursive https://github.com/polybar/polybar.git
	        cd polybar
	        
	        # Apply critical build fixes
	        export LDFLAGS="-lfreetype -lfontconfig -lpango-1.0 -lpangocairo-1.0"
	        mkdir -p build
	        cd build
	        
	        cmake .. \
	            -DCMAKE_CXX_FLAGS="-Wno-narrowing -Wno-error=deprecated-declarations" \
	            -DWITH_ALL=ON \
	            -DBUILD_TESTS=OFF \
	            -DENABLE_CCACHE=OFF
	        
	        if make -j$(nproc) && sudo make install; then
	            echo -e "${greenColour}[+] polybar manually installed successfully${endColour}"
	            sudo ldconfig  # Refresh library cache
	        else
	            # Ultimate fallback - install from Arch repos
	            echo -e "${yellowColour}[!] Trying Arch official package...${endColour}"
	            if sudo pacman -S --noconfirm polybar; then
	                echo -e "${greenColour}[+] Installed stable polybar from official repos${endColour}"
	            else
	                echo -e "${redColour}[-] All installation methods failed${endColour}"
	                echo -e "${yellowColour}[!] Try: 1) Update system 2) Use older GCC version${endColour}"
	                exit 1
	            fi
	        fi
	    fi
	else
	    echo -e "${yellowColour}[!] polybar is already installed. Skipping...${endColour}"
	fi

	echo -e "\n${purpleColour}[*] Installing picom...\n${endColour}"
	sleep 2
	# Check if picom is already installed
	if ! command -v picom &> /dev/null; then
		git clone https://github.com/ibhagwan/picom.git
		cd picom || { echo -e "\n${redColour}[-] Failed to enter picom directory!\n${endColour}"; exit 1; }
		git submodule update --init --recursive
		meson --buildtype=release . build
		ninja -C build
		sudo ninja -C build install
		if [ $? -ne 0 ] && [ $? -ne 130 ]; then
			echo -e "\n${redColour}[-] Failed to install picom!\n${endColour}"
			exit 1
		else
			echo -e "\n${greenColour}[+] Done\n${endColour}"
			sleep 1.5
		fi
		cd ..
	else
		echo -e "\n${yellowColour}[!] picom is already installed. Skipping...\n${endColour}"
	fi

	echo -e "\n${purpleColour}[*] Installing Fish shell for user $user...\n${endColour}"
	sleep 2

	# Install fish shell
	sudo pacman -S --needed --noconfirm fish
	install_status=$?

	if [ $install_status -ne 0 ] && [ $install_status -ne 130 ]; then
		echo -e "\n${redColour}[-] Failed to install Fish shell for user $user!\n${endColour}"
		exit 1
	else
		# Install Fisher plugin manager and tide prompt
		echo -e "\n${yellowColour}[*] Configuring Fish shell plugins...\n${endColour}"
		
		# Create config directory if needed
		mkdir -p ~/.config/fish
		
		# Install Fisher
		fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher" 2>/dev/null
		fisher_status=$?
		
		# Install tide prompt
		fish -c "fisher install IlanCosman/tide@v5" 2>/dev/null
		tide_status=$?
		
		# Verify installations
		if [ $fisher_status -ne 0 ] || [ $tide_status -ne 0 ]; then
			echo -e "\n${yellowColour}[!] Partial success: Fish installed but plugin configuration had issues${endColour}"
			echo -e "${yellowColour}    You may need to manually run:"
			echo -e "    fish -c 'fisher install jorgebucaran/fisher IlanCosman/tide@v5'${endColour}"
		fi
		
		echo -e "\n${greenColour}[+] Fish shell installed and configured\n${endColour}"
		sleep 1.5
	fi

	echo -e "\n${blueColour}[*] Starting configuration of fonts, wallpaper, configuration files, fish config, and scripts...\n${endColour}"
	sleep 0.5

	echo -e "\n${purpleColour}[*] Configuring fonts...\n${endColour}"
	sleep 2
	mkdir -p "$fdir"
	cp -rv "$dir/fonts/"* "$fdir"
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Configuring wallpaper...\n${endColour}"
	sleep 2
	mkdir -p ~/Wallpapers
	cp -rv "$dir/wallpapers/"* ~/Wallpapers/
	
	# Apply wallpaper using pywal
	if command -v wal &> /dev/null; then
		wal -nqi ~/Wallpapers/Pic1.png
		sudo wal -nqi ~/Wallpapers/Pic1.png
	else
		echo -e "\n${yellowColour}[!] pywal not installed. Skipping wallpaper setup${endColour}"
	fi
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Configuring configuration files...\n${endColour}"
	sleep 2
	mkdir -p ~/.config
	cp -rv "$dir/config/"* ~/.config/
	
	mkdir -p ~/.config/alacritty
	cp -v "$dir/alacritty.yml" ~/.config/alacritty/
	
	# Add fish config if exists in repo
	if [ -f "$dir/config.fish" ]; then
		mkdir -p ~/.config/fish
		cp -v "$dir/config.fish" ~/.config/fish/
	fi
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Configuring fish shell files...\n${endColour}"
	sleep 2
	# Set fish as default shell
	fish_path=$(which fish)
	if [ -n "$fish_path" ]; then
		sudo chsh -s "$fish_path" "$user"
		sudo chsh -s "$fish_path" root
	else
		echo -e "\n${redColour}[-] Fish shell not found! Cannot set as default shell${endColour}"
	fi
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Configuring scripts...\n${endColour}"
	sleep 2
	sudo mkdir -p /usr/local/bin/
	sudo cp -v "$dir/scripts/whichSystem.py" /usr/local/bin/
	
	# Create polybar scripts directory if it doesn't exist
	mkdir -p ~/.config/polybar/shapes/scripts/
	cp -rv "$dir/scripts/"*.sh ~/.config/polybar/shapes/scripts/
	touch ~/.config/polybar/shapes/scripts/target
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Configuring necessary permissions and symbolic links...\n${endColour}"
	sleep 2
	chmod -R +x ~/.config/bspwm/
	chmod +x ~/.config/polybar/launch.sh
	chmod +x ~/.config/polybar/shapes/scripts/*.sh
	sudo chmod +x /usr/local/bin/whichSystem.py
	
	# Configure root polybar scripts
	sudo mkdir -p /root/.config/polybar/shapes/scripts/
	sudo touch /root/.config/polybar/shapes/scripts/target
	sudo ln -sf ~/.config/polybar/shapes/scripts/target /root/.config/polybar/shapes/scripts/target
	
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${purpleColour}[*] Cleaning up...\n${endColour}"
	sleep 2
	if [ -d "$HOME/tools" ]; then
		rm -rfv ~/tools
	fi
	
	# Only remove the current directory if it's not the home directory
	if [ "$dir" != "$HOME" ]; then
		rm -rfv "$dir"
	else
		echo -e "\n${yellowColour}[!] Skipping removal of current directory (HOME directory)${endColour}"
	fi
	echo -e "\n${greenColour}[+] Done\n${endColour}"
	sleep 1.5

	echo -e "\n${greenColour}[+] Environment configured :D\n${endColour}"
	sleep 1.5

	while true; do
		echo -en "\n${yellowColour}[?] It's necessary to restart the system. Do you want to restart now? ([y]/n) ${endColour}"
		read -r
		REPLY=${REPLY:-"y"}
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			echo -e "\n\n${greenColour}[+] Restarting...\n${endColour}"
			sleep 1
			sudo reboot
		elif [[ $REPLY =~ ^[Nn]$ ]]; then
			exit 0
		else
			echo -e "\n${redColour}[!] Invalid response\n${endColour}"
		fi
	done
fi
