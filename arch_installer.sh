#!/bin/bash

# Arch Linux Installer with Beginner and Expert Modes

# Variables
selected_disk=""
partition_scheme=""
de_choice=""
additional_packages=""
network_setup=false
expert_mode=false

# Function to display a main menu
main_menu() {
    mode_choice=$(dialog --title "Arch Linux Installer" --menu "Choose a mode:" 15 50 5 \
        1 "Beginner Mode" \
        2 "Expert Mode" \
        3>&1 1>&2 2>&3)

    case $mode_choice in
        1) beginner_mode ;;
        2) expert_mode ;;
        *) echo "Invalid option" ;;
    esac
}

# Function for Beginner Mode
beginner_mode() {
    dialog --msgbox "Beginner Mode: This mode will guide you through a simple installation process." 10 40
    select_disk
    partition_disk_auto
    install_base
    configure_system
    setup_users
    install_bootloader
    install_desktop_environment
    configure_network
    run_post_install_scripts
    finalize_installation
}

# Function for Expert Mode
expert_mode() {
    expert_mode=true
    while true; do
        choice=$(dialog --title "Expert Mode" --menu "Choose an option:" 20 60 10 \
            1 "Select Disk" \
            2 "Partition Disk" \
            3 "Install Base System" \
            4 "Configure System" \
            5 "Set Up Users" \
            6 "Install Bootloader" \
            7 "Install Desktop Environment" \
            8 "Install Additional Packages" \
            9 "Configure Network" \
            10 "Run Post-Install Scripts" \
            11 "Finalize Installation" \
            12 "Exit" \
            3>&1 1>&2 2>&3)

        case $choice in
            1) select_disk ;;
            2) partition_disk_manual ;;
            3) install_base ;;
            4) configure_system ;;
            5) setup_users ;;
            6) install_bootloader ;;
            7) install_desktop_environment ;;
            8) install_additional_packages ;;
            9) configure_network ;;
            10) run_post_install_scripts ;;
            11) finalize_installation ;;
            12) break ;;
            *) echo "Invalid option" ;;
        esac
    done
}

# Function to select a disk
select_disk() {
    disks=$(lsblk -d -n -o NAME,SIZE)
    disk_choice=$(dialog --title "Select Disk" --menu "Select a disk for installation:" 20 60 5 $(echo "$disks" | awk '{print $1, $2}') 3>&1 1>&2 2>&3)
    if [ -z "$disk_choice" ]; then
        dialog --msgbox "No disk selected. Returning to main menu." 10 40
        return
    fi
    selected_disk="/dev/$disk_choice"
    dialog --msgbox "Selected disk: $selected_disk" 10 40
}

# Function to automatically partition the disk (Beginner Mode)
partition_disk_auto() {
    if [ -z "$selected_disk" ]; then
        dialog --msgbox "No disk selected. Please select a disk first." 10 40
        return
    fi
    dialog --yesno "Are you sure you want to partition $selected_disk? This will erase all data!" 10 40
    if [ $? -eq 0 ]; then
        parted -s "$selected_disk" mklabel gpt
        parted -s "$selected_disk" mkpart primary ext4 1MiB 512MiB
        parted -s "$selected_disk" set 1 boot on
        parted -s "$selected_disk" mkpart primary ext4 512MiB 20GiB
        parted -s "$selected_disk" mkpart primary ext4 20GiB 100%
        mkfs.fat -F32 "${selected_disk}1"
        mkfs.ext4 "${selected_disk}2"
        mkfs.ext4 "${selected_disk}3"
        mount "${selected_disk}2" /mnt
        mkdir /mnt/boot
        mount "${selected_disk}1" /mnt/boot
        mkdir /mnt/home
        mount "${selected_disk}3" /mnt/home
        dialog --msgbox "Disk partitioned and mounted." 10 40
    else
        dialog --msgbox "Partitioning canceled." 10 40
    fi
}

# Function to manually partition the disk (Expert Mode)
partition_disk_manual() {
    if [ -z "$selected_disk" ]; then
        dialog --msgbox "No disk selected. Please select a disk first." 10 40
        return
    fi
    dialog --msgbox "Launching cfdisk for manual partitioning. Press OK to continue." 10 40
    cfdisk "$selected_disk"
    dialog --msgbox "Partitioning complete. Please mount the partitions manually." 10 40
}

# Function to install the base system
install_base() {
    dialog --msgbox "Installing base system..." 10 40
    pacstrap /mnt base linux linux-firmware vim sudo
    dialog --msgbox "Base system installed." 10 40
}

# Function to configure the system
configure_system() {
    dialog --msgbox "Configuring system..." 10 40
    genfstab -U /mnt >> /mnt/etc/fstab
    arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/UTC /etc/localtime"
    arch-chroot /mnt /bin/bash -c "hwclock --systohc"
    arch-chroot /mnt /bin/bash -c "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen"
    arch-chroot /mnt /bin/bash -c "locale-gen"
    arch-chroot /mnt /bin/bash -c "echo 'LANG=en_US.UTF-8' > /etc/locale.conf"
    dialog --msgbox "System configured." 10 40
}

# Function to set up users
setup_users() {
    root_password=$(dialog --title "Set Root Password" --passwordbox "Enter the root password:" 10 40 3>&1 1>&2 2>&3)
    arch-chroot /mnt /bin/bash -c "echo 'root:$root_password' | chpasswd"
    username=$(dialog --title "Create User" --inputbox "Enter a username:" 10 40 3>&1 1>&2 2>&3)
    user_password=$(dialog --title "Set User Password" --passwordbox "Enter the password for $username:" 10 40 3>&1 1>&2 2>&3)
    arch-chroot /mnt /bin/bash -c "useradd -m -G wheel -s /bin/bash $username"
    arch-chroot /mnt /bin/bash -c "echo '$username:$user_password' | chpasswd"
    arch-chroot /mnt /bin/bash -c "echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers"
    dialog --msgbox "Users set up." 10 40
}

# Function to install the bootloader
install_bootloader() {
    dialog --msgbox "Installing bootloader..." 10 40
    arch-chroot /mnt /bin/bash -c "pacman -S grub --noconfirm"
    arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
    arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
    dialog --msgbox "Bootloader installed." 10 40
}

# Function to install a desktop environment
install_desktop_environment() {
    de_choice=$(dialog --title "Install Desktop Environment" --menu "Select a desktop environment:" 15 50 5 \
        1 "GNOME" \
        2 "KDE Plasma" \
        3 "Xfce" \
        4 "None" \
        3>&1 1>&2 2>&3)
    case $de_choice in
        1) arch-chroot /mnt /bin/bash -c "pacman -S gnome gdm --noconfirm"
           arch-chroot /mnt /bin/bash -c "systemctl enable gdm"
           dialog --msgbox "GNOME installed." 10 40 ;;
        2) arch-chroot /mnt /bin/bash -c "pacman -S plasma sddm --noconfirm"
           arch-chroot /mnt /bin/bash -c "systemctl enable sddm"
           dialog --msgbox "KDE Plasma installed." 10 40 ;;
        3) arch-chroot /mnt /bin/bash -c "pacman -S xfce4 lightdm lightdm-gtk-greeter --noconfirm"
           arch-chroot /mnt /bin/bash -c "systemctl enable lightdm"
           dialog --msgbox "Xfce installed." 10 40 ;;
        4) dialog --msgbox "No desktop environment selected." 10 40 ;;
        *) dialog --msgbox "Invalid option." 10 40 ;;
    esac
}

# Function to install additional packages
install_additional_packages() {
    packages=$(dialog --title "Install Additional Packages" --inputbox "Enter packages to install (space-separated):" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$packages" ]; then
        arch-chroot /mnt /bin/bash -c "pacman -S $packages --noconfirm"
        dialog --msgbox "Additional packages installed." 10 40
    else
        dialog --msgbox "No packages selected." 10 40
    fi
}

# Function to configure network
configure_network() {
    arch-chroot /mnt /bin/bash -c "pacman -S networkmanager --noconfirm"
    arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager"
    dialog --msgbox "NetworkManager installed and enabled." 10 40
}

# Function to run post-install scripts
run_post_install_scripts() {
    dialog --msgbox "Running post-install scripts..." 10 40
    # Add your custom scripts here
    dialog --msgbox "Post-install scripts completed." 10 40
}

# Function to finalize installation
finalize_installation() {
    dialog --msgbox "Installation complete! Unmounting and rebooting..." 10 40
    umount -R /mnt
    reboot
}

# Main function
main() {
    if ! command -v dialog &> /dev/null; then
        echo "Dialog is not installed. Please install it first."
        exit 1
    fi
    main_menu
}

# Run the script
main