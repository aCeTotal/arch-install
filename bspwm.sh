#!/bin/bash

# Variables
country=Norway
kbmap=no
gpu_output=DP-1
screen_resolution=2560x1440
screen_refreshrate=100

# Options
nvidia_gpu=true #Enable if NVIDIA GPU
amd_gpu=false   #Enable if AMD GPU
aur_helper=true #AUR-helper YAY
install_sddm=true #SDDM display manager
gaming=true #Gaming packages
gen_xprofile=true #Generate .xprofile
enable_multilib=true #Enabling multilib, for packages like Steam 

sudo timedatectl set-ntp true
sudo hwclock --systohc
sudo reflector -c $country -a 12 --sort rate --save /etc/pacman.d/mirrorlist
pacman -S --noconfirm archlinux-keyring
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

sudo firewall-cmd --add-port=1025-65535/tcp --permanent
sudo firewall-cmd --add-port=1025-65535/udp --permanent
sudo firewall-cmd --reload
sudo virsh net-autostart default

if [[ $aur_helper = true ]]; then
    pacman -S --noconfirm --needed git base-devel
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay/;makepkg -si --noconfirm;cd
fi

# Install packages
sudo pacman -S --noconfirm --needed bspwm sxhkd dmenu terminator xorg polkit-gnome nitrogen lxappearance thunar blender gimp discord
yay -S polybar
# Install fonts
sudo pacman -S --noconfirm dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji

# Enable multilib and install steam
if [[ $enable_multilib = true ]]; then
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm --needed
fi

# Install Gaming packages
if [[ $gaming = true ]]; then
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
fi

# Install sddm
if [[ $install_sddm = true ]]; then
    sudo pacman -S --noconfirm sddm
    sudo systemctl enable sddm
fi

# .xprofile
if [[ $gen_xprofile = true ]]; then
cat > ~/.xprofile << EOF
setxkbmap $kbmap &
picom -f --experimental-backend &
nitrogen --restore & 
xrandr --output $gpu_output --mode $screen_resolution --rate $screen_refreshrate &
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &

polybar &

EOF
fi

# NVIDIA UPDATE HOOK
if [[ $nvidia_gpu = true ]]; then
sudo cat > /etc/pacman.d/hooks/nvidia.hook << EOF
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=linux-zen

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux-zen) exit 0; esac; done; /usr/bin/mkinitcpio -P'

EOF
fi

reboot