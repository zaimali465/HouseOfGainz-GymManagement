#!/bin/bash

ADMIN_PASSWORD="admin"
REGISTRATION_FEE=1000
GOLD_MEMBERSHIP_FEE=5000
SILVER_MEMBERSHIP_FEE=2000

# ANSI color codes
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to display menu options for admin
display_admin_menu() {
    echo "Admin Mode - House of Gainz"
    echo "1. Member Registration"
    echo "2. View Members"
    echo "3. View Recent Joins"
    echo "4. Search Member"
    echo "5. Edit Member Details"
    echo "6. Delete Member"
    echo "7. View Trainers"
    echo "8. Check Pending Fees"
    echo "9. Exit"
}

# Function to display menu options for user
display_user_menu() {
    echo "User Mode - House of Gainz"
    echo "1. Join Gym"
    echo "2. Quit Gym"
    echo "3. Edit Profile"
    echo "4. Pay Membership Fee"
    echo "5. Exit"
}

# Function to register a new member with a specific ID provided by the admin
register_member() {
    echo "Member Registration"
    read -p "Enter Member ID: " member_id
    read -p "Enter Member Name: " member_name
    read -p "Enter Contact Number: " contact_number

    echo "Choose Membership Type:"
    echo "1. Gold"
    echo "2. Silver"
    read -p "Enter your choice: " membership_choice

    if [ "$membership_choice" == "1" ]; then
        membership_type="Gold"
    elif [ "$membership_choice" == "2" ]; then
        membership_type="Silver"
    else
        echo "Invalid choice. Defaulting to Silver."
        membership_type="Silver"
    fi

    fee=$((REGISTRATION_FEE + (membership_type == "Gold" ? GOLD_MEMBERSHIP_FEE : SILVER_MEMBERSHIP_FEE)))

    echo "Name: $member_name"
    echo "Contact Number: $contact_number"
    echo "Membership Type: $membership_type"
    echo "Total Fee: $fee"

    # Save member details to a file (you might want to use a database)
    echo "$member_id|$member_name|$contact_number|$membership_type|$fee|active" >> members.txt

    echo "Member successfully registered! Fee is non-refundable."
    echo -e "${GREEN}Gym Rules:${NC}"
    echo -e "${GREEN}* Slippers not allowed on Treadmill${NC}"
    echo -e "${GREEN}* Discipline is our first priority, so please put the weights back, be respectful to others, no smoking, vapes, etc., and wait for your turn${NC}"
    echo -e "${GREEN}* We offer Prayers in Gym, so during Jamaat, you are not allowed to train in Gym. Either join us or wait outside.${NC}"
    echo -e "${GREEN}* Don't talk because it's not a workout.${NC}"
}

# Function to view all members
view_members() {
    echo "List of Members:"
    awk -F'|' '{printf "ID: %s, Name: %s, Contact: %s, Membership: %s, Fee: $%s, Status: %s\n", $1, $2, $3, $4, $5, $6}' members.txt
}

# Function to view recent joins
view_recent_joins() {
    echo "Recent Joins:"
    grep -E "|Gold|Silver" members.txt | tail -n 5 | awk -F'|' '{printf "ID: %s, Name: %s, Contact: %s, Membership: %s, Fee: $%s, Status: %s\n", $1, $2, $3, $4, $5, $6}'
}

# Function to search for a member
search_member() {
    read -p "Enter Member ID to search: " search_id

    # Search for the member in the file
    found=false
    awk -F'|' -v search_id="$search_id" '$1 == search_id {found=true; printf "ID: %s, Name: %s, Contact: %s, Membership: %s, Fee: $%s, Status: %s\n", $1, $2, $3, $4, $5, $6}' members.txt

    if [ "$found" == "false" ]; then
        echo "Member not found."
    fi
}

# Function to edit member details
edit_member() {
    read -p "Enter Member ID to edit: " edit_id

    # Temporary file to store updated member details
    tmpfile=$(mktemp /tmp/member_edit.XXXXXX)

    # Search for the member and edit details
    while IFS='|' read -r id name contact membership fee status; do
        if [ "$id" == "$edit_id" ]; then
            echo "Editing Member ID: $id"
            read -p "Enter New Contact Number: " new_contact
            echo "$id|$name|$new_contact|$membership|$fee|$status" >> "$tmpfile"
            echo "Member details updated."
        else
            echo "$id|$name|$contact|$membership|$fee|$status" >> "$tmpfile"
        fi
    done < members.txt

    # Replace the original file with the updated one
    mv "$tmpfile" members.txt
}

# Function to delete a member
delete_member() {
    read -p "Enter Member ID to delete: " delete_id

    # Temporary file to store members excluding the one to be deleted
    tmpfile=$(mktemp /tmp/member_delete.XXXXXX)

    # Search for the member and exclude it from the temporary file
    while IFS='|' read -r id name contact membership fee status; do
        if [ "$id" != "$delete_id" ]; then
            echo "$id|$name|$contact|$membership|$fee|$status" >> "$tmpfile"
        else
            echo "Member ID: $id, Name: $name, Contact: $contact, Membership: $membership, Fee: $fee, Status: $status - Deleted"
        fi
    done < members.txt

    # Replace the original file with the updated one
    mv "$tmpfile" members.txt
}

# Function to view trainers
view_trainers() {
    echo "List of Trainers:"
    # Add logic to display trainers (if any)
}

# Function to check pending fees
check_pending_fees() {
    echo "Checking Pending Fees:"
    current_day=$(date +%-d)

    # Notify members if their fees are pending (considering the 1st to 10th as the period to notify)
    if [ "$current_day" -ge 1 ] && [ "$current_day" -le 10 ]; then
        awk -F'|' '$6 == "active" && $5 > 0 {printf "ID: %s, Name: %s, Contact: %s, Membership: %s, Fee: $%s, Status: %s - Fee Pending\n", $1, $2, $3, $4, $5, $6}' members.txt
    else
        echo "Not the fee notification period."
    fi
}

# Function to expire memberships if not renewed for the current month
expire_memberships() {
    current_month=$(date +%m)
    awk -F'|' -v current_month="$current_month" '$6 == "active" && $5 > 0 && $7 != current_month {printf "ID: %s, Name: %s, Contact: %s, Membership: %s, Fee: $%s, Status: %s - Membership Expired\n", $1, $2, $3, $4, $5, $6}' members.txt
}

# Main menu
while true; do
    echo "Welcome to House of Gainz - Gym Management System"
    echo "1. Admin Mode"
    echo "2. User Mode"
    echo "3. Exit"
    read -p "Enter your choice: " main_choice

    case $main_choice in
        1)
            read -s -p "Enter Admin Password: " admin_password
            echo
            if [ "$admin_password" == "$ADMIN_PASSWORD" ]; then
                while true; do
                    display_admin_menu
                    read -p "Enter your choice: " choice

                    case $choice in
                        1) register_member;;
                        2) view_members;;
                        3) view_recent_joins;;
                        4) search_member;;
                        5) edit_member;;
                        6) delete_member;;
                        7) view_trainers;;
                        8) check_pending_fees;;
                        9) echo "Exiting Admin Mode."; break;;
                        *) echo "Invalid choice. Please try again.";;
                    esac
                done
            else
                echo "Incorrect password. Access denied."
            fi
            ;;
        2)
            while true; do
                display_user_menu
                read -p "Enter your choice: " choice

                case $choice in
                    1) register_member;;
                    2) delete_member;;
                    3) edit_member;;
                    4) check_pending_fees;;
                    5) echo "Exiting User Mode."; break;;
                    *) echo "Invalid choice. Please try again.";;
                esac
            done
            ;;
        3)
            expire_memberships
            echo "Exiting House of Gainz. Goodbye!"; exit;;
        *) echo "Invalid choice. Please try again.";;
    esac
done


