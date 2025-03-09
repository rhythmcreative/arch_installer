#!/usr/bin/env zsh
#
# disk-menu.sh - An Advanced TUI for disk management using whiptail
#
# This script provides a comprehensive text-based interface for disk operations including:
# - Partitioning (viewing, creating, deleting, formatting)
# - LUKS encryption management
# -# Ensure the script exits on error
set -e

# Colors for better UI
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Constants
TEMP_DIR="/tmp/disk-menu"
BACKUP_DIR="$HOME/disk-backups"

# Function to check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        whiptail --title "Error" --msgbox "This script must be run as root to perform disk operations." 8 78
        exit 1
    fi
}

# Function to show error messages
show_error() {
    whiptail --title "Error" --msgbox "$1" 8 78
}

# Function to show success messages
show_success() {
    whiptail --title "Success" --msgbox "$1" 8 78
}

# Function to confirm actions
confirm_action() {
    whiptail --title "Confirm" --yesno "$1" 8 78
    return $?
}

# Function to get a list of available disks
get_disks() {
    # Get disk information and format it for whiptail menu
    lsblk -dp -o NAME,SIZE,MODEL | grep -v loop | grep "^/" | awk '{print $1 " " $2 " " substr($0, index($0,$3))}'
}

# Function to get detailed disk information
get_detailed_disk_info() {
    local disk="$1"
    
    echo "Detailed information for disk: $disk\n"
    echo "================================================================="
    
    # General disk information
    echo "${CYAN}Disk Model:${NORMAL}"
    lsblk -d -o MODEL "$disk" | tail -n 1
    
    echo "\n${CYAN}Disk Size:${NORMAL}"
    lsblk -d -o SIZE "$disk" | tail -n 1
    
    echo "\n${CYAN}Disk Type:${NORMAL}"
    lsblk -d -o TRAN,ROTA "$disk" | tail -n 1 | awk '{print $1 == "" ? "Unknown" : $1, $2 == "1" ? "(HDD)" : "(SSD)"}'
    
    # Partition information
    echo "\n${CYAN}Partition Table Type:${NORMAL}"
    parted -s "$disk" print | grep "Partition Table" | cut -d: -f2 | tr -d ' '
    
    echo "\n${CYAN}Partition Layout:${NORMAL}"
    lsblk -p "$disk" -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,UUID | sed 's/^/  /'
    
    # SMART information if available
    if command -v smartctl &> /dev/null; then
        echo "\n${CYAN}SMART Health Status:${NORMAL}"
        smartctl -H "$disk" 2>/dev/null | grep "overall-health" || echo "  SMART not available for this device"
    fi
    
    # Check if disk has RAID
    if command -v mdadm &> /dev/null; then
        echo "\n${CYAN}RAID Information:${NORMAL}"
        mdadm --detail --scan | grep "$disk" || echo "  Not part of a RAID array"
    fi
    
    # Check for encrypted partitions
    echo "\n${CYAN}LUKS Encrypted Partitions:${NORMAL}"
    lsblk -p "$disk" -o NAME,FSTYPE | grep "crypto_LUKS" || echo "  No encrypted partitions found"
    
    echo "================================================================="
}

# Function to get a list of partitions for a disk
get_partitions() {
    local disk="$1"
    lsblk -p "$disk" -o NAME | grep -v "^$disk$" || echo ""
}
# Function to create disk selection menu
select_disk() {
    local disks=($(get_disks))
    local disk_count=$(echo "$disks" | wc -l)
    
    if [[ $disk_count -eq 0 ]]; then
        whiptail --title "Error" --msgbox "No disks found!" 8 78
        exit 1
    fi
    
    # Prepare the menu items for whiptail
    local menu_items=()
    local i=1
    
    while read -r line; do
        local disk_name=$(echo "$line" | awk '{print $1}')
        local disk_size=$(echo "$line" | awk '{print $2}')
        local disk_model=$(echo "$line" | awk '{print substr($0, index($0,$3))}')
        menu_items+=("$disk_name" "$disk_size - $disk_model")
        ((i++))
    done < <(echo "$disks")
    
    # Display the menu and get user selection
    local selected_disk=$(whiptail --title "Disk Selection" --menu "Select a disk:" 20 78 $disk_count "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo "$selected_disk"
}
# Function to view partitions of a selected disk
view_partitions() {
    local disk=$1
    
    local partitions=$(lsblk -p "$disk" -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL,UUID)
    
    whiptail --title "Partitions of $disk" --scrolltext --msgbox "$partitions" 20 78
}

# Function to display detailed disk information
view_detailed_disk_info() {
    local disk=$1
    
    local disk_info=$(get_detailed_disk_info "$disk")
    
    whiptail --title "Detailed Information for $disk" --scrolltext --msgbox "$disk_info" 24 80
}
# Function to create a new partition
create_partition() {
    local disk=$1
    
    # Confirm before proceeding
    whiptail --title "Confirm" --yesno "This will launch cfdisk to create partitions on $disk. Continue?" 8 78
    
    if [[ $? -eq 0 ]]; then
        cfdisk "$disk"
        whiptail --title "Success" --msgbox "Partition creation process completed." 8 78
    fi
}

# Function to delete a partition
delete_partition() {
    local disk=$1
    
    # Get a list of partitions for the selected disk
    local partitions=$(lsblk -p "$disk" -o NAME | grep -v "$disk$")
    
    if [[ -z "$partitions" ]]; then
        whiptail --title "Error" --msgbox "No partitions found on $disk!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE,FSTYPE,MOUNTPOINT,LABEL | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Select Partition to Delete" --menu "Select a partition:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm deletion
    whiptail --title "Confirm Deletion" --yesno "WARNING: This will delete the partition $selected_partition and all data on it! Continue?" 8 78
    
    if [[ $? -eq 0 ]]; then
        # Check if mounted
        local mount_point=$(lsblk -p "$selected_partition" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
        
        if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
            whiptail --title "Error" --msgbox "The partition $selected_partition is mounted at $mount_point. Unmount it first." 8 78
            return
        fi
        
        # Delete partition
        if fdisk "$disk" << EOF
d
$(echo "$selected_partition" | sed "s|$disk||" | tr -d 'p')
w
EOF
        then
            whiptail --title "Success" --msgbox "Partition $selected_partition deleted successfully." 8 78
            # Refresh partition table
            partprobe "$disk"
        else
            whiptail --title "Error" --msgbox "Failed to delete partition $selected_partition." 8 78
        fi
    fi
}

# Function to format a partition
format_partition() {
    local disk=$1
    
    # Get a list of partitions for the selected disk
    local partitions=$(lsblk -p "$disk" -o NAME | grep -v "$disk$")
    
    if [[ -z "$partitions" ]]; then
        whiptail --title "Error" --msgbox "No partitions found on $disk!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE,FSTYPE,MOUNTPOINT,LABEL | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Select Partition to Format" --menu "Select a partition:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Select filesystem type
    local fs_type=$(whiptail --title "Select Filesystem Type" --menu "Select a filesystem type:" 15 78 6 \
        "ext4" "Extended Filesystem 4" \
        "ext3" "Extended Filesystem 3" \
        "ext2" "Extended Filesystem 2" \
        "btrfs" "B-Tree Filesystem" \
        "xfs" "XFS Filesystem" \
        "f2fs" "Flash-Friendly Filesystem" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm format
    whiptail --title "Confirm Format" --yesno "WARNING: This will format $selected_partition with $fs_type filesystem and erase ALL data on it! Continue?" 8 78
    
    if [[ $? -eq 0 ]]; then
        # Check if mounted
        local mount_point=$(lsblk -p "$selected_partition" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
        
        if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
            whiptail --title "Error" --msgbox "The partition $selected_partition is mounted at $mount_point. Unmount it first." 8 78
            return
        fi
        
        # Format partition based on selected filesystem type
        case "$fs_type" in
            ext4)
                if mkfs.ext4 "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as ext4." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as ext4." 8 78
                fi
                ;;
            ext3)
                if mkfs.ext3 "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as ext3." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as ext3." 8 78
                fi
                ;;
            ext2)
                if mkfs.ext2 "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as ext2." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as ext2." 8 78
                fi
                ;;
            btrfs)
                if mkfs.btrfs "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as btrfs." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as btrfs." 8 78
                fi
                ;;
            xfs)
                if mkfs.xfs "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as xfs." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as xfs." 8 78
                fi
                ;;
            f2fs)
                if mkfs.f2fs "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as f2fs." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as f2fs." 8 78
                fi
                ;;
        esac
    fi

}

# Function to create a swap partition
create_swap() {
    local disk=$1
    
    # Get partitions
    local partitions=$(get_partitions "$disk")
    
    if [[ -z "$partitions" ]]; then
        whiptail --title "Error" --msgbox "No partitions found on $disk!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE,FSTYPE,MOUNTPOINT,LABEL | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Select Partition for Swap" --menu "Select a partition:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm
    if ! whiptail --title "Confirm" --yesno "This will create a swap partition on $selected_partition and ERASE ALL DATA on it! Continue?" 8 78; then
        return
    fi
    
    # Check if mounted
    local mount_point=$(lsblk -p "$selected_partition" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
    
    if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
        whiptail --title "Error" --msgbox "The partition $selected_partition is mounted at $mount_point. Unmount it first." 8 78
        return
    fi
    
    # Create swap
    if mkswap "$selected_partition"; then
        whiptail --title "Success" --msgbox "Swap partition created on $selected_partition." 8 78
        
        # Ask if want to activate swap
        if whiptail --title "Confirm" --yesno "Do you want to activate the swap partition now?" 8 78; then
            if swapon "$selected_partition"; then
                whiptail --title "Success" --msgbox "Swap partition activated successfully." 8 78
            else
                whiptail --title "Error" --msgbox "Failed to activate swap partition." 8 78
            fi
        fi
    else
        whiptail --title "Error" --msgbox "Failed to create swap partition on $selected_partition." 8 78
    fi
}

# Function to activate a swap partition
activate_swap() {
    # Get all partitions that have swap signature but are not active
    local swaps=$(lsblk -o NAME,FSTYPE,MOUNTPOINT | grep "swap" | grep -v "\[SWAP\]" | awk '{print "/dev/"$1}')
    
    if [[ -z "$swaps" ]]; then
        whiptail --title "Error" --msgbox "No inactive swap partitions found!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r swap; do
        local part_info=$(lsblk -p "$swap" -o SIZE | tail -n 1)
        menu_items+=("$swap" "$part_info")
        ((i++))
    done < <(echo "$swaps")
    
    # Display menu and get user selection
    local selected_swap=$(whiptail --title "Activate Swap" --menu "Select a swap partition to activate:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Activate swap
    if swapon "$selected_swap"; then
        whiptail --title "Success" --msgbox "Swap partition $selected_swap activated successfully." 8 78
    else
        whiptail --title "Error" --msgbox "Failed to activate swap partition $selected_swap." 8 78
    fi
}

# Function to deactivate a swap partition
deactivate_swap() {
    # Get all active swap partitions
    local active_swaps=$(lsblk -o NAME,MOUNTPOINT | grep "\[SWAP\]" | awk '{print "/dev/"$1}')
    
    if [[ -z "$active_swaps" ]]; then
        whiptail --title "Error" --msgbox "No active swap partitions found!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r swap; do
        local part_info=$(lsblk -p "$swap" -o SIZE | tail -n 1)
        menu_items+=("$swap" "$part_info")
        ((i++))
    done < <(echo "$active_swaps")
    
    # Display menu and get user selection
    local selected_swap=$(whiptail --title "Deactivate Swap" --menu "Select a swap partition to deactivate:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Deactivate swap
    if swapoff "$selected_swap"; then
        whiptail --title "Success" --msgbox "Swap partition $selected_swap deactivated successfully." 8 78
    else
        whiptail --title "Error" --msgbox "Failed to deactivate swap partition $selected_swap." 8 78
    fi
}

# Function to manage swap
swap_management() {
    local disk=$1
    
    while true; do
        local operation=$(whiptail --title "Swap Management" --menu "Choose an operation:" 15 78 5 \
            "1" "Create Swap Partition" \
            "2" "Activate Swap Partition" \
            "3" "Deactivate Swap Partition" \
            "4" "View Swap Status" \
            "5" "Return to Main Menu" 3>&1 1>&2 2>&3)
        
        # Return if user cancels
        if [[ $? -ne 0 ]]; then
            return
        fi
        
        
        case "$operation" in
            1)
                create_swap "$disk"
                ;;
            2)
                activate_swap
                ;;
            3)
                deactivate_swap
                ;;
            4)
                # View swap status
                local swap_info=$(swapon --show)
                if [[ -z "$swap_info" ]]; then
                    swap_info="No active swap partitions found."
                fi
                whiptail --title "Swap Status" --scrolltext --msgbox "$swap_info" 20 78
                ;;
            5)
                return
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid option: $operation" 8 78
                ;;
        esac
    done
}

# Function to create an encrypted LUKS partition
create_luks_partition() {
    local disk=$1
    
    # Get partitions
    local partitions=$(get_partitions "$disk")
    
    if [[ -z "$partitions" ]]; then
        whiptail --title "Error" --msgbox "No partitions found on $disk!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE,FSTYPE,MOUNTPOINT,LABEL | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Select Partition for Encryption" --menu "Select a partition:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm
    if ! whiptail --title "Confirm" --yesno "This will encrypt $selected_partition with LUKS and ERASE ALL DATA on it! Continue?" 8 78; then
        return
    fi
    
    # Check if mounted
    local mount_point=$(lsblk -p "$selected_partition" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
    
    if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
        whiptail --title "Error" --msgbox "The partition $selected_partition is mounted at $mount_point. Unmount it first." 8 78
        return
    fi
    
    # Get encryption passphrase
    local passphrase=$(whiptail --title "Set Encryption Passphrase" --passwordbox "Enter a strong passphrase for encryption:" 10 78 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm passphrase
    local confirm_passphrase=$(whiptail --title "Confirm Passphrase" --passwordbox "Confirm your passphrase:" 10 78 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Check if passphrases match
    if [[ "$passphrase" != "$confirm_passphrase" ]]; then
        whiptail --title "Error" --msgbox "Passphrases do not match!" 8 78
        return
    fi
    
    # Create LUKS partition
    echo -n "$passphrase" | cryptsetup luksFormat --type luks2 "$selected_partition" -
    
    if [[ $? -eq 0 ]]; then
        whiptail --title "Success" --msgbox "Encrypted LUKS partition created on $selected_partition." 8 78
        
        # Ask if want to open the encrypted partition
        if whiptail --title "Confirm" --yesno "Do you want to open the encrypted partition now?" 8 78; then
            # Get the name for the decrypted device
            local crypt_name=$(whiptail --title "Set Device Name" --inputbox "Enter a name for the decrypted device:" 10 78 "cryptvol" 3>&1 1>&2 2>&3)
            
            # Return if user cancels
            if [[ $? -ne 0 ]]; then
                return
            fi
            
            # Open LUKS partition
            echo -n "$passphrase" | cryptsetup open "$selected_partition" "$crypt_name" -
            
            if [[ $? -eq 0 ]]; then
                whiptail --title "Success" --msgbox "Encrypted partition opened as /dev/mapper/$crypt_name" 8 78
                
                # Ask if want to format the opened device
                if whiptail --title "Confirm" --yesno "Do you want to format the decrypted device now?" 8 78; then
                    # Select filesystem type
                    local fs_type=$(whiptail --title "Select Filesystem Type" --menu "Select a filesystem type:" 15 78 6 \
                        "ext4" "Extended Filesystem 4" \
                        "ext3" "Extended Filesystem 3" \
                        "ext2" "Extended Filesystem 2" \
                        "btrfs" "B-Tree Filesystem" \
                        "xfs" "XFS Filesystem" \
                        "f2fs" "Flash-Friendly Filesystem" 3>&1 1>&2 2>&3)
                    
                    # Return if user cancels
                    if [[ $? -ne 0 ]]; then
                        return
                    fi
                    
                    # Format the opened device
                    case "$fs_type" in
                        ext4)
                            mkfs.ext4 "/dev/mapper/$crypt_name" && \
                            whiptail --title "Success" --msgbox "Decrypted device formatted as ext4." 8 78
                            ;;
                        ext3)
                            mkfs.ext3 "/dev/mapper/$crypt_name" && \
                            whiptail --title "Success" --msgbox "Decrypted device formatted as ext3." 8 78
                            ;;
                        ext2)
                            mkfs.ext2 "/dev/mapper/$crypt_name" && \
                            whiptail --title "Success" --msgbox "Decrypted device formatted as ext2." 8 78
                            ;;
                        btrfs)
                            mkfs.btrfs "/dev/mapper/$crypt_name" && \
                            whiptail --title "Success" --msgbox "Decrypted device formatted as btrfs." 8 78
                            ;;
                        xfs)
                            mkfs.xfs "/dev/mapper/$crypt_name" && \
                            whiptail --title "Success" --msgbox "Decrypted device formatted as xfs." 8 78
                            ;;
                        f2fs)
                            mkfs.f2fs "/dev/mapper/$crypt_name" && \
                            whiptail --title "Success" --msgbox "Decrypted device formatted as f2fs." 8 78
                            ;;
                    esac
                fi
            else
                whiptail --title "Error" --msgbox "Failed to open encrypted partition." 8 78
            fi
        fi
    else
        whiptail --title "Error" --msgbox "Failed to create encrypted LUKS partition." 8 78
    fi
}

# Function to open/unlock a LUKS encrypted partition
open_luks_partition() {
    # Get all LUKS partitions
    local luks_partitions=$(lsblk -o NAME,FSTYPE | grep "crypto_LUKS" | awk '{print "/dev/"$1}')
    
    if [[ -z "$luks_partitions" ]]; then
        whiptail --title "Error" --msgbox "No LUKS encrypted partitions found!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$luks_partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Open LUKS Partition" --menu "Select an encrypted partition to open:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Get the name for the decrypted device
    local crypt_name=$(whiptail --title "Set Device Name" --inputbox "Enter a name for the decrypted device:" 10 78 "cryptvol" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Check if the name is already in use
    if [[ -e "/dev/mapper/$crypt_name" ]]; then
        whiptail --title "Error" --msgbox "Device name /dev/mapper/$crypt_name already exists! Choose a different name." 8 78
        return
    fi
    
    # Open LUKS partition
    if cryptsetup open "$selected_partition" "$crypt_name"; then
        whiptail --title "Success" --msgbox "Encrypted partition opened as /dev/mapper/$crypt_name" 8 78
    else
        whiptail --title "Error" --msgbox "Failed to open encrypted partition." 8 78
    fi
}

# Function to close/lock a LUKS encrypted partition
close_luks_partition() {
    # Get all opened LUKS mapped devices
    local mapped_devices=$(ls /dev/mapper/ | grep -v "control")
    
    if [[ -z "$mapped_devices" ]]; then
        whiptail --title "Error" --msgbox "No opened LUKS partitions found!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r device; do
        local device_info=$(lsblk -p "/dev/mapper/$device" -o SIZE | tail -n 1)
        menu_items+=("$device" "$device_info")
        ((i++))
    done < <(echo "$mapped_devices")
    
    # Display menu and get user selection
    local selected_device=$(whiptail --title "Close LUKS Partition" --menu "Select a device to close:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Check if the device is mounted
    local mount_point=$(lsblk -p "/dev/mapper/$selected_device" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
    
    if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
        whiptail --title "Error" --msgbox "The device /dev/mapper/$selected_device is mounted at $mount_point. Unmount it first." 8 78
        return
    fi
    
    # Close LUKS device
    if cryptsetup close "$selected_device"; then
        whiptail --title "Success" --msgbox "LUKS device /dev/mapper/$selected_device closed successfully." 8 78
    else
        whiptail --title "Error" --msgbox "Failed to close LUKS device /dev/mapper/$selected_device." 8 78
    fi
}

# Function to manage LUKS encryption
luks_management() {
    local disk=$1
    
    while true; do
        local operation=$(whiptail --title "LUKS Encryption Management" --menu "Choose an operation:" 15 78 4 \
            "1" "Create Encrypted LUKS Partition" \
            "2" "Open/Unlock Encrypted Partition" \
            "3" "Close/Lock Encrypted Partition" \
            "4" "Return to Main Menu" 3>&1 1>&2 2>&3)
        
        # Return if user cancels
        if [[ $? -ne 0 ]]; then
            return
        fi
        
        case "$operation" in
            1)
                create_luks_partition "$disk"
                ;;
            2)
                open_luks_partition
                ;;
            3)
                close_luks_partition
                ;;
            4)
                return
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid option: $operation" 8 78
                ;;
        esac
    done
}

# Main function
main() {
    # Check if running as root
    check_root
    
    # Create required directories
    mkdir -p "$TEMP_DIR" "$BACKUP_DIR"
    
    local selected_disk=""
    
    while true; do
        # If no disk is selected, show disk selection menu
        if [[ -z "$selected_disk" ]]; then
            selected_disk=$(select_disk)
            
            # Exit if user cancels
            if [[ $? -ne 0 ]]; then
                exit 0
            fi
        fi
        
        # Show disk operations menu
        local operation=$(whiptail --title "Disk Operations - $selected_disk" --menu "Choose an operation:" 20 78 8 \
            "1" "Basic Partition Management" \
            "2" "LUKS Encryption Management" \
            "3" "Swap Management" \
            "4" "View Detailed Disk Information" \
            "5" "Select Another Disk" \
            "6" "Exit" 3>&1 1>&2 2>&3)
        
        # Exit if user cancels
        if [[ $? -ne 0 ]]; then
            exit 0
        fi
        
        # Perform the selected operation
        case "$operation" in
            1)
                # Basic Partition Management submenu
                local part_op=$(whiptail --title "Basic Partition Management - $selected_disk" --menu "Choose an operation:" 15 78 4 \
                    "1" "View Partitions" \
                    "2" "Create New Partition" \
                    "3" "Delete Partition" \
                    "4" "Format Partition" 3>&1 1>&2 2>&3)
                
                if [[ $? -eq 0 ]]; then
                    case "$part_op" in
                        1)
                            view_partitions "$selected_disk"
                            ;;
                        2)
                            create_partition "$selected_disk"
                            ;;
                        3)
                            delete_partition "$selected_disk"
                            ;;
                        4)
                            format_partition "$selected_disk"
                            ;;
                    esac
                fi
                ;;
            2)
                # LUKS Encryption Management
                luks_management "$selected_disk"
                ;;
            3)
                # Swap Management
                swap_management "$selected_disk"
                ;;
            4)
                # View Detailed Disk Information
                view_detailed_disk_info "$selected_disk"
                ;;
            5)
                # Select Another Disk
                selected_disk=""
                ;;
            6)
                # Exit
                whiptail --title "Exit" --msgbox "Exiting disk manager. Goodbye!" 8 78
                exit 0
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid option: $operation" 8 78
                ;;
        esac
    done
}

# Add a header with information about the script
header() {
    echo "================================================================================"
    echo "${GREEN}Disk Management Menu Tool${NORMAL}"
    echo "================================================================================"
    echo "This script provides a comprehensive interface for disk management operations."
    echo "Including partitioning, encryption, and swap management."
    echo "Use with caution as disk operations can result in data loss."
    echo "================================================================================"
    echo "${YELLOW}Version: 1.0${NORMAL}"
    echo "${YELLOW}Author: System Administrator${NORMAL}"
    echo "================================================================================"
}

# Clear the screen and display the header
clear
header

# Run the main function
main
