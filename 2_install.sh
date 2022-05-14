#!/bin/bash

# Variables
country=Norway
kbmap=no
gpu_output=DP-1
screen_resolution=2560x1440
screen_refreshrate=100

    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ $CPU == *"AuthenticAMD"* ]]; then
        microcode="amd-ucode"
    else
        microcode="intel-ucode"
    fi

# Options
nvidia_gpu=true #Enable if NVIDIA GPU
aur_helper=true #AUR-helper YAY
install_ly=true #SDDM display manager
gaming=true #Gaming packages
gen_autostart=true #Generate .xprofile
enable_multilib=true #Enabling multilib, for packages like Steam 

sudo timedatectl set-ntp true
sudo hwclock --systohc
sudo reflector -c $country -a 12 --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -S --noconfirm --needed archlinux-keyring
sudo pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b
sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

sudo virsh net-autostart default

sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
sudo pacman -Sy --noconfirm --needed


sudo pacman -S --noconfirm --needed git base-devel
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay/;makepkg -si --noconfirm;cd

# Install packages
sudo pacman -S --noconfirm --needed xorg picom nitrogen alacritty efibootmgr network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-zen-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font
# Install fonts
sudo pacman -S --noconfirm --needed dina-font tamsyn-font bdf-unifont ttf-bitstream-vera ttf-croscore ttf-dejavu ttf-droid gnu-free-fonts ttf-ibm-plex ttf-liberation ttf-linux-libertine noto-fonts ttf-roboto tex-gyre-fonts ttf-ubuntu-font-family ttf-anonymous-pro ttf-cascadia-code ttf-fantasque-sans-mono ttf-fira-mono ttf-hack ttf-fira-code ttf-inconsolata ttf-jetbrains-mono ttf-monofur adobe-source-code-pro-fonts cantarell-fonts inter-font ttf-opensans gentium-plus-font ttf-junicode adobe-source-han-sans-otc-fonts adobe-source-han-serif-otc-fonts noto-fonts-cjk noto-fonts-emoji

#Install dwm and dmenu
print "Compiling DWM."
mkdir ~/.config
cd ~/.config
git clone https://github.com/aCeTotal/dwm.git
cd dwm
config.h
make
sudo make install
cd ..

print "Compiling DMENU."
git clone https://github.com/aCeTotal/dmenu.git
cd dmenu
rm config.h
make
sudo make install
cd


# Install Gaming packages
if [[ $gaming = true ]]; then
sudo pacman -Sy
sudo pacman -S --noconfirm --needed wine-staging winetricks steam
sudo pacman -S --noconfirm --needed giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader cups samba dosbox
yay -S protonup --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S mangohud --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S gamemode --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S steamtinkerlaunch --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S goverlay-bin --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S pkg-config --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S cmake --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S heroic-games-launcher-bin --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S python-evdev --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
yay -S lutris --answerclean All --answerdiff All --nocleanmenu --nodiffmenu
protonup
fi

# Install ly
if [[ $install_ly = true ]]; then
    cd /tmp
    git clone https://aur.archlinux.org/ly
    cd ly
    makepkg -si
    sudo systemctl enable ly
    cd
fi

# dwm autostart
if [[ $gen_autostart = true ]]; then
mkdir ~/.dwm
cat > ~/.dwm/autostart.sh << EOF
#!/bin/bash

#NORWEGIAN KEYBOARD LAYOUT
setxkbmap $kbmap &

#Composition
picom --experimental-backend &

#WALLPAPER MANAGER
nitrogen --restore & 

#MONITOR SETUP
xrandr --output $gpu_output --mode $screen_resolution --rate $screen_refreshrate &

#NVIDIA - MAX PERFORMANCE
nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1 &

#SYSTRAY APPLETS
nm-applet #Networkmanager

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
Target=linux-tkg-pds

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux-zen) exit 0; esac; done; /usr/bin/mkinitcpio -P'

EOF
fi

reboot