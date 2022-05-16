#!/usr/bin/env -S bash -e

# Cleaning the TTY.
clear

# Cosmetics (colours for text).
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print (function).
print () {
    echo -e "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}
# Alert user of bad input (function).
incEcho () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Virtualization check (function).
virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   print "KVM has been detected."
                print "Installing guest tools."
                pacstrap /mnt qemu-guest-agent >/dev/null
                print "Enabling specific services for the guest tools."
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
        vmware  )   print "VMWare Workstation/ESXi has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt open-vm-tools >/dev/null
                    print "Enabling specific services for the guest tools."
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    print "VirtualBox has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt virtualbox-guest-utils >/dev/null
                    print "Enabling specific services for the guest tools."
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
        microsoft ) print "Hyper-V has been detected."
                    print "Installing guest tools."
                    pacstrap /mnt hyperv >/dev/null
                    print "Enabling specific services for the guest tools."
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
    esac
}

# User enters a password for the LUKS Container (function).
lukspass_selector () {
    read -r -s -p "Insert the password for the LUKS container (you're not going to see the password): " password
    if [ -z "$password" ]; then
        incEcho "You need to enter a password for the LUKS Container in order to continue."
        return 1
    fi
    echo
    read -r -s -p "Insert the password for the LUKS container again: " password2
    echo
    if [ "$password" != "$password2" ]; then
        incEcho "Passwords don't match, please try again."
        return 1
    fi
    return 0
}

# User enters a password for the user account (function).
userpass_selector () {
    read -r -s -p "Set a user password for $username: " userpass
    if [ -z "$userpass" ]; then
        incEcho "\nYou need to enter a password for $username."
        return 1
    fi
    echo
    read -r -s -p "Insert password again: " userpass2
    echo
    if [ "$userpass" != "$userpass2" ]; then
        incEcho "Passwords don't match, try again."
        return 1
    fi
    return 0
}

# User enters a password for the root account (function).
rootpass_selector () {
    read -r -s -p "Set a root password: " rootpass
    if [ -z "$rootpass" ]; then
        incEcho "\nYou need to enter a root password."
        return 1
    fi
    echo
    read -r -s -p "Password (again): " rootpass2
    echo
    if [ "$rootpass" != "$rootpass2" ]; then
        incEcho "Passwords don't match, try again."
        return 1
    fi
    return 0
}

# User enters a hostname (function).
hostname_selector () {
    read -r -p "Please enter the hostname: " hostname
    if [ -z "$hostname" ]; then
        incEcho "You need to enter a hostname in order to continue."
        return 1
    fi
    return 0
}

# User chooses the locale (function).
locale_selector () {
    read -r -p "Please insert the locale you use (format: xx_XX. Enter empty to use en_US, or \"/\" to search locales): " locale
    case $locale in
        '') locale="en_US.UTF-8"
            print "$locale will be the default locale."
            return 0;;
        '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/      (Charset:&)/' /etc/locale.gen | less -M
             clear
             return 1;;
        *) if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< $locale) " /etc/locale.gen; then
               incEcho "The specified locale doesn't exist or isn't supported."
               return 1
           fi
           return 0
    esac
}

# User chooses the console keyboard layout (function).
keyboard_selector () {
    read -r -p "Please insert the keyboard layout to use in console (enter empty to use US, or \"/\" to look up for keyboard layouts): " kblayout
    case $kblayout in
        '') kblayout="no-latin1"
            print "Norwegian will be used as the default console keymap."
            return 0;;
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq $kblayout; then
               incEcho "The specified keymap doesn't exist."
               return 1
           fi
           print "Changing console layout to $kblayout."
           loadkeys $kblayout
           return 0
    esac

}

# Welcome screen.
print "Welcome to the first part 1/2 in the process of installing Arch Linux."

# Setting up keyboard layout.
until keyboard_selector; do : ; done

# Choosing the target for the installation.
print "Available disks for the installation:"
PS3="Please select the disk NUMBER (e.g. 1) where Arch Linux is going to be installed: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme|vd");
do
    DISK=$ENTRY
    print "Arch Linux will be installed to $DISK."
    break
done

# Warn user about deletion of old partition scheme.
echo -en "${BOLD}${BRED}This will delete the current partition table on $DISK once installation starts. Do you agree [y/N]?:${RESET} "
read -r disk_response
if ! [[ "${disk_response,,}" =~ ^(yes|y)$ ]]; then
    print "Quitting."
    exit
fi

# Setting up LUKS password.
until lukspass_selector; do : ; done

# User choses the locale.
until locale_selector; do : ; done

# User choses the hostname.
until hostname_selector; do : ; done

# User chooses username.
read -r -p "Please enter name for a user account (enter empty to not create one): " username
until userpass_selector; do : ; done
until rootpass_selector; do : ; done

# Deleting old partition scheme.
print "Wiping $DISK."
wipefs -af "$DISK" &>/dev/null
sgdisk -Zo "$DISK" &>/dev/null

# Creating a new partition scheme.
print "Creating the partitions on $DISK."
parted -s "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart CRYPTROOT 513MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
CRYPTROOT="/dev/disk/by-partlabel/CRYPTROOT"

# Informing the Kernel of the changes.
print "Informing the Kernel about the disk changes."
partprobe "$DISK"

# Formatting the ESP as FAT32.
print "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 $ESP &>/dev/null

# Creating a LUKS Container for the root partition.
print "Creating LUKS Container for the root partition."
echo -n "$password" | cryptsetup luksFormat "$CRYPTROOT" -d -
echo -n "$password" | cryptsetup open "$CRYPTROOT" cryptroot -d -
BTRFS="/dev/mapper/cryptroot"

# Formatting the LUKS Container as BTRFS.
print "Formatting the LUKS container as BTRFS."
mkfs.btrfs $BTRFS &>/dev/null
mount $BTRFS /mnt

# Creating BTRFS subvolumes.
print "Creating BTRFS subvolumes."
subvols=(snapshots var_pkgs var_log home root srv)
for subvol in '' "${subvols[@]}"; do
    btrfs su cr /mnt/@"$subvol"
done

# Mounting the newly created subvolumes.
umount /mnt
print "Mounting the newly created subvolumes."
mountopts="ssd,noatime,compress-force=zstd:3,discard=async"
mount -o $mountopts,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,root,srv,.snapshots,var/{log,cache/pacman/pkg},boot}
for subvol in "${subvols[@]:2}"; do
    mount -o "$mountopts",subvol=@"$subvol" "$BTRFS" /mnt/"${subvol//_//}"
done
mount -o $mountopts,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o $mountopts,subvol=@var_pkgs $BTRFS /mnt/var/cache/pacman/pkg
chattr +C /mnt/var/log
mount $ESP /mnt/boot/

# Pacstrap (setting up a base sytem onto the new root).
print "Installing the base system (it may take a while)."
pacstrap /mnt --needed base linux-zen intel-ucode linux-firmware linux-zen-headers networkmanager btrfs-progs grub grub-btrfs git rsync efibootmgr snapper reflector base-devel snap-pac zram-generator nvidia-dkms nvidia-utils nvidia-settings >/dev/null

# Setting up the hostname.
echo "$hostname" > /mnt/etc/hostname

# Generating /etc/fstab.
print "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Configure selected locale and console keymap
sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Virtualization check.
virt_check

# Configuring /etc/mkinitcpio.conf.
print "Configuring /etc/mkinitcpio.conf."
cat > /mnt/etc/mkinitcpio.conf <<EOF
MODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)
HOOKS=(base systemd autodetect keyboard keymap sd-vconsole modconf block sd-encrypt filesystems)
COMPRESSION=(zstd)
EOF

# Setting up LUKS2 encryption in grub.
print "Setting up grub config."
UUID=$(blkid -s UUID -o value $CRYPTROOT)
sed -i "\,^GRUB_CMDLINE_LINUX=\"\",s,\",&rd.luks.name=$UUID=cryptroot root=$BTRFS," /mnt/etc/default/grub
sed -i 's/GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/g' /mnt/etc/default/grub
sudo sed -i '/GRUB_SAVEDEFAULT=.*/d' /mnt/etc/default/grub
sudo sed -i '$aGRUB_SAVEDEFAULT=true' /mnt/etc/default/grub

# Configuring the system.
arch-chroot /mnt /bin/bash -e <<EOF

    # Setting up timezone.
    echo "Setting up the timezone."
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

    # Setting up clock.
    echo "Setting up the system clock."
    hwclock --systohc

    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null

    # Generating a new initramfs.
    echo "Creating a new initramfs."
    mkinitcpio -P &>/dev/null

    # Snapper configuration
    echo "Configuring Snapper."
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots &>/dev/null
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots

    # Installing GRUB.
    echo "Installing GRUB on /boot."
    grub-install --target=x86_64-efi --efi-directory=/boot/ --bootloader-id=GRUB &>/dev/null

    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

EOF

# Setting root password.
print "Setting root password."
echo "root:$rootpass" | arch-chroot /mnt chpasswd

# Setting user password.
if [ -n "$username" ]; then
    print "Adding the user $username to the system with root privilege."
    arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$username"
    sed -i '/^# %wheel ALL=(ALL) ALL/s/^# //' /mnt/etc/sudoers
    sed -i '82s/.//' /mnt/etc/sudoers
    echo "$username ALL=(ALL) ALL" >> /mnt/etc/sudoers.d/$username
    print "Setting user password for $username."
    echo "$username:$userpass" | arch-chroot /mnt chpasswd
fi

# Boot backup hook.
print "Configuring /boot backup when pacman transactions are made."
mkdir /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/50-bootbackup.hook <<EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
EOF

#Create DWM-session for DM
print "Creating dwm session for ly."
mkdir /mnt/usr/share/xsessions
cat > /mnt/usr/share/xsessions/dwm.desktop <<EOF
[Desktop Entry]
Encoding=UTF-8
Name=Dwm
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=XSession
EOF

# ZRAM configuration.
print "Configuring ZRAM."
cat > /mnt/etc/systemd/zram-generator.conf <<EOF
[zram0]
zram-size = min(ram, 8192)
EOF

# Pacman eye-candy features.
print "Enabling colours, animations, and parallel in pacman."
sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf

# Enabling various services.
print "Enabling Reflector, automatic snapshots, BTRFS scrubbing and systemd-oomd."
for service in NetworkManager reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfs.path systemd-oomd
do
    systemctl enable "$service" --root=/mnt &>/dev/null
done

# Finishing up.
print "Done! Reboot, login and run script #2"
exit