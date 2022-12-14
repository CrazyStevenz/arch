#!/bin/bash

# Enable GDM
echo "Enabling GDM..."
sudo systemctl enable gdm

# Enable bluetooth
echo "Enabling bluetooth..."
sudo systemctl enable bluetooth

# Enable bluetooth on startup
echo "Enabling bluetooth on startup"
sudo sed -i 's/#AutoEnable=false/AutoEnable=true/g' /etc/bluetooth/main.conf

read -r -p "Install zenstates.sh (can break your ryzen cpu if it's not configured correctly)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
      # Undervolt ryzen cpu
      echo "Undervolting ryzen cpu..."
      bash ./scripts/add-system-service.sh zenstates
fi

read -r -p "Install fstab (can break system if it's not configured correctly)? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    # Auto mount disks on startup
    echo "Adding mounts to fstab..."
    ( (cat /etc/fstab settings/txt-to-append/fstab.txt > ~/.fstab.txt.new) && (sudo mv /etc/fstab /etc/fstab.old) && (sudo mv ~/.fstab.txt.new /etc/fstab) )

    # Create folders for HDD mounts and change permissions now and on startup
    echo "Creating folders for mounts..."
    ( (sudo mkdir /mnt/Games) && (sudo mkdir /mnt/SSDGames) )
fi

# Enable nvidia overclocking
(lspci | grep NVIDIA > /dev/null) && ( (echo "Enabling nvidia overclocking...") && (sudo nvidia-xconfig --cool-bits=32) )

# Maximize nvidia GPU power limit on startup
echo "Maximizing Nvidia GPU power limit..."
(lspci | grep NVIDIA > /dev/null) && ( (echo "Maximizing Nvidia GPU power limit...") && (bash ./scripts/add-system-service.sh nv-power-limit) )

# Set hard/soft memlock limits to 2 GBs (required by RPCS3)
echo "Settings memory limits required by RPCS3..."
(echo "*        hard    memlock        2147483648
*        soft    memlock        2147483648" | sudo tee -a /etc/security/limits.conf)

# nvm installer
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

# Add feedback to sudo password
echo "Adding password feedback to sudo..."
echo "Defaults pwfeedback" | sudo tee -a /etc/sudoers

# Enable os prober
echo "Enabling os prober..."
sudo sed -i 's/#\(GRUB_DISABLE_OS_PROBER="false"\)/\1/g' /etc/default/grub

# Update grub
echo "Updating grub..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Enable firefox wayland support
echo "Enabling firefox wayland support..."
cp apps/zsh/.zprofile ~/.zprofile

# Add mozilla custom profile
echo "Adding custom mozilla profile..."
randomPath="$HOME/.mozilla/firefox/$RANDOM.privacy"
( (mkdir -p "$randomPath") && (cp settings/firefox/user-overrides.js "$randomPath"/user-overrides.js) && (git clone https://github.com/arkenfox/user.js.git) && (cp user.js/updater.sh "$randomPath"/updater.sh) && (sed -i "s|path-to-mozilla-updater|$randomPath|" ~/.config/zsh/zsh-personal.sh) && (yes | bash "$randomPath"/updater.sh) && (rm -rf user.js) )

# Force QT applications to follow GTK theme and cursor size
echo "XDG_CURRENT_DESKTOP=Gnome
QT_QPA_PLATFORMTHEME=Plata-Noir-Compact
XCURSOR_SIZE=24" | sudo tee -a /etc/environment

# Add nvidia gpu fan control (wayland)
(lspci | grep NVIDIA > /dev/null) && ( (echo "Adding nvidia gpu fan control script for wayland...") && (cp scripts/.nvidia-fan-control-wayland.sh ~/.config/zsh/scripts/.nvidia-fan-control-wayland.sh) )

# Add noise suppression to pipewire
echo "Adding noise suppression to pipewire..."
( (mkdir -p ~/.config/pipewire) && (cp /usr/share/pipewire/pipewire.conf ~/.config/pipewire/pipewire.conf) && (sed -i "/libpipewire-module-session-manager/a $(cat settings/txt-to-append/noise-suppression.txt)" ~/.config/pipewire/pipewire.conf) )

# Enable avahi service
echo "Enabling avahi service..."
sudo systemctl enable avahi-daemon.service

# Setup sunshine setcap
echo "Setting sunshine setcap..."
sudo setcap cap_sys_admin+p /usr/bin/sunshine

# Add proton remove script to zsh scripts
pip list | grep -F protonup-ng && (echo "Adding proton ge version remover script...") && (cp scripts/.protondown.sh ~/.config/zsh/scripts/.protondown.sh)

# Add post install script to startup
echo "Adding post install script to startup..."
( (mkdir -p ~/.config/autostart) && (cp scripts/.post-install.sh ~/.post-install.sh) && (cp apps/startup/post-install.desktop ~/.config/autostart/post-install.desktop) )
