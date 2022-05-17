#!/bin/bash

#DESKTOP
#gpu_output=DP-2
#screen_resolution=3440x1440
#screen_refreshrate=100

#LAPTOP
gpu_output=DP-4
screen_resolution=1920x1080
screen_refreshrate=300

#Enable multilib
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Sy --noconfirm --needed

#Install yay AUR-helper
sudo pacman -S --noconfirm --needed git base-devel
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay/;makepkg -si --noconfirm;cd

#################
#  LAPTOP ONLY  #
#################
sudo pacman -S --noconfirm --needed auto-cpufreq tlp modemmanager usb_modeswitch
sudo systemctl enable --now tlp
sudo systemctl enable --now auto-cpufreq.service
sudo systemctl enable --now ModemManager.service

# Install packages
sudo pacman -S --noconfirm --needed xorg efibootmgr polkit-gnome dialog wpa_supplicant nm-connection-editor mtools dosfstools base-devel linux-zen-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils bash-completion openssh rsync reflector acpi acpi_call edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font
# Install fonts
sudo pacman -S --noconfirm --needed hack dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji ttf-font-awesome awesome-terminal-fonts
#Intall programs
sudo pacman -S --noconfirm --needed obs-studio picom nitrogen alacritty blender gimp libreoffice-still pacman-contrib pavucontrol thunar volumeicon networkmanager-openconnect network-manager-applet blueman virt-manager qemu qemu-arch-extra archlinux-wallpaper


#Install sound
sudo pacman -S --noconfirm --needed pipewire-docs wireplumber pipewire pipewire-pulse pipewire-alsa

#Install brave-browser
yay -S brave-bin

#Install NVIDIA Drivers
sudo pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader

#Install AMD Drivers
#sudo pacman -S --needed lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader


#Install dwm
mkdir -p ~/.config
cd ~/.config
git clone https://github.com/aCeTotal/dwm.git
cd ~/.config/dwm
config.h
make
sudo make install

#Install dmenu
cd ~/.config/
git clone https://github.com/aCeTotal/dmenu.git
cd ~/.config/dmenu
rm config.h
make
sudo make install
cd


# Install Gaming packages
sudo pacman -Sy
sudo pacman -S --noconfirm --needed wine-staging winetricks steam
sudo pacman -S --noconfirm --needed giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba dosbox
yay -S protonup
yay -S mangohud
yay -S gamemode
yay -S steamtinkerlaunch
yay -S goverlay-bin
yay -S lutris
protonup

# Install ly
cd /tmp
git clone https://aur.archlinux.org/ly
cd ly
makepkg -si
sudo systemctl enable ly
cd

# dwm autostart
mkdir -p ~/.local/share/dwm/
cat > ~/.local/share/dwm/autostart.sh << EOF
#!/bin/bash

function run {
	if ! pgrep $1 ;
		then
			$@&
		fi
 }

#statusbar
run "dwmblocks"

#NORWEGIAN KEYBOARD LAYOUT
run "setxkbmap no"

#Composition
run "picom --experimental-backend"

#WALLPAPER MANAGER
run "nitrogen --restore" 

#MONITOR SETUP
run "xrandr --output DP-4 --mode 1920x1080 --rate 300"

#NVIDIA - MAX PERFORMANCE
run "nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1"

run "numlockx on"

#SYSTRAY APPLETS
run "blueman-applet"
run "nm-applet"
run "pamac-tray"
run "volumeicon"
EOF
chmod +x ~/.local/share/dwm/autostart.sh

# NVIDIA UPDATE HOOK
sudo cat > /etc/pacman.d/hooks/nvidia.hook << EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=linux-zen
Target=linux-tkg-pds

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux-zen) exit 0; esac; done; /usr/bin/mkinitcpio -P'

EOF

#Enable services
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now cups.service
sudo systemctl enable --now sshd
sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now reflector.timer
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now libvirtd
sudo systemctl enable --now firewalld
sudo systemctl enable --now acpid


#Adding user to libvirt group
usermod -aG libvirt lars
sudo virsh net-autostart default

#Adding dotfiles + dwmblocks to ~/.config
cd ~/.config
git clone https://github.com/aCeTotal/dotfiles.git
git clone https://github.com/aCeTotal/dwmblocks.git
sudo mkdir -p /usr/share/backgrounds
sudo mv ~/.config/dotfiles/backgrounds/ /usr/share/backgrounds/
cd ~/.config/dwmblocks
make
sudo make install
chmod -R +x ~/.config/dwmblocks/statusbar/* && cd

#Setup cursor, icons, theme and config
yay -S lxappearance 
yay -S numlockx
yay -S arc-gtk-theme 
yay -S bibata-cursor-theme
yay -S papirus-icon-theme

rm -rf ~/.config/alacritty
mv ~/.config/dotfiles/alacritty/ ~/.config/alacritty/

rm -rf ~/.config/nitrogen
mv ~/.config/dotfiles/nitrogen/ ~/.config/nitrogen/

rm -rf ~/.config/yay
mv ~/.config/dotfiles/yay/ ~/.config/yay/

rm -rf ~/.config/volumeicon
mv ~/.config/dotfiles/volumeicon/ ~/.config/volumeicon/

rm -rf ~/.config/dotfiles
rm -rf ~/arch-install

reboot