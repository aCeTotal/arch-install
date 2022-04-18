#!/bin/bash

#Variables. 

# You should not use your real passwords here. If you do, make sure the script is deleted after you are done.
# You can safely change the root and user password after the install with "passwd" and "passwd lars" command.

username=lars
user_password=123
root_password=12345
hostname=arch-desktop

keyboard_layout=no-latin1

# Options
laptop=false
nvidia_gpu=true
amd_gpu=false






ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime
hwclock --systohc
sed -i '178s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=$keyboard_layout" >> /etc/vconsole.conf
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo root:$root_password | chpasswd 

# You can add xorg to the installation packages, I usually add it at the DE or WM install script
# You can remove the tlp package if you are installing on a desktop or vm

pacman -Syu
pacman -S --noconfirm efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-zen-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

if [[ $laptop = true ]]; then
pacman -S --noconfirm --needed tlp
fi

if [[ $nvidia_gpu = true ]]; then
pacman -S --noconfirm --needed nvidia-dkms nvidia-utils nvidia-settings
fi

if [[ $amd_gpu = true ]]; then
pacman -S --noconfirm --needed xf86-video-amdgpu 
fi

#GRUB SETUP
#grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi
#grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

if [[ $laptop = true ]]; then
systemctl enable tlp
fi

useradd -m $username
echo $username:$root_password | chpasswd
usermod -aG libvirt $username

echo "$username ALL=(ALL) ALL" >> /etc/sudoers.d/$username

printf "\e[1;32mDone! Type exit, umount -a and then reboot!\e[0m"
printf "\e[1;32mAfter reboot, log in with your user and run the next script!\e[0m"

#Since this file may contain important passwords, we will delete it after the script has run once.
rm base-uefi.sh



