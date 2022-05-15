#!/bin/bash

# Variables
country=Norway
kbmap=no
gpu_output=DP-1
screen_resolution=2560x1440
screen_refreshrate=100

sudo virsh net-autostart default

#Enable multilib
sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Sy --noconfirm --needed

#Install yay AUR-helper
sudo pacman -S --noconfirm --needed git base-devel
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay/;makepkg -si --noconfirm;cd

# Install packages
sudo pacman -S --noconfirm --needed xorg picom nitrogen alacritty efibootmgr volumeicon blueman network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-zen-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font
# Install fonts
sudo pacman -S --noconfirm --needed dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji

#Install dwm
print "Compiling DWM."
mkdir ~/.config
cd ~/.config
git clone https://github.com/aCeTotal/dwm.git
cd dwm
config.h
make
sudo make install
cd ..

#Install dmenu
print "Compiling DMENU."
git clone https://github.com/aCeTotal/dmenu.git
cd dmenu
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
yay -S pkg-config
yay -S cmake
yay -S heroic-games-launcher-bin
yay -S python-evdev
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
mkdir ~/.dwm
cat > ~/.dwm/autostart.sh << EOF
#!/bin/bash

#statusbar
dwmblocks &

#NORWEGIAN KEYBOARD LAYOUT
setxkbmap no &

#Composition
picom --experimental-backend &

#WALLPAPER MANAGER
nitrogen --restore & 

#MONITOR SETUP
xrandr --output $gpu_output --mode $screen_resolution --rate $screen_refreshrate &

#NVIDIA - MAX PERFORMANCE
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &

#SYSTRAY APPLETS
volumeicon #Volume
blueman-applet #Bluetooth
nm-applet #Networkmanager
EOF

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

reboot