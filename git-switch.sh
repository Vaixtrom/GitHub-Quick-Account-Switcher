#!/bin/bash

# ============================================
# GIT ACCOUNT SWITCHER v1.0 (macOS/Linux)
# Easily switch between multiple GitHub accounts
# ============================================

CONFIG_DIR="$HOME/.git-switcher"
CONFIG_FILE="$CONFIG_DIR/accounts.txt"
SSH_DIR="$HOME/.ssh"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Ensure SSH directory exists
mkdir -p "$SSH_DIR"

# Function to pause and wait for input
pause() {
    read -p "Press [Enter] key to continue..."
}

# Function to add a new account
add_account() {
    clear
    echo "======================================================"
    echo "              ADD NEW GITHUB ACCOUNT"
    echo "======================================================"
    echo ""
    echo "  Enter the details for your GitHub account:"
    echo ""
    
    read -p "  GitHub Username: " acc_name
    [[ -z "$acc_name" ]] && return

    read -p "  GitHub Email: " acc_email
    [[ -z "$acc_email" ]] && return

    # Create safe key filename (replace spaces with underscores)
    key_name="id_ed25519_${acc_name// /_}"

    echo ""
    echo "------------------------------------------------------"
    echo "  Generating SSH key for $acc_name..."
    echo "------------------------------------------------------"

    if [ -f "$SSH_DIR/$key_name" ]; then
        echo ""
        echo "  SSH key already exists for this account."
        echo "  Using existing key."
    else
        # Generate new SSH key
        ssh-keygen -t ed25519 -C "$acc_email" -f "$SSH_DIR/$key_name" -N ""
        
        if [ $? -ne 0 ]; then
            echo ""
            echo "  ERROR: Failed to generate SSH key."
            pause
            return
        fi
    fi

    # Save to config file
    echo "$acc_name|$acc_email|$key_name" >> "$CONFIG_FILE"

    echo ""
    echo "======================================================"
    echo "  ACCOUNT ADDED SUCCESSFULLY!"
    echo "======================================================"
    echo ""
    echo "  NOW YOU NEED TO ADD THE SSH KEY TO GITHUB:"
    echo ""
    echo "  1. Go to: https://github.com/settings/keys"
    echo "     (Make sure you're logged in as $acc_name)"
    echo ""
    echo "  2. Click 'New SSH key'"
    echo ""
    echo "  3. Title: Enter any name (e.g., 'My Mac')"
    echo ""
    echo "  4. Key type: Select 'Authentication Key'"
    echo ""
    echo "  5. Key: Copy and paste this PUBLIC key:"
    echo ""
    echo "------------------------------------------------------"
    cat "$SSH_DIR/$key_name.pub"
    echo "------------------------------------------------------"
    echo ""
    echo "  6. Click 'Add SSH key'"
    echo ""
    echo "======================================================"
    echo ""
    echo "  The public key has also been copied to:"
    echo "  $SSH_DIR/$key_name.pub"
    echo ""
    pause
}

# Function to remove an account
remove_account() {
    clear
    echo "======================================================"
    echo "             REMOVE GITHUB ACCOUNT"
    echo "======================================================"
    echo ""
    echo "  Select account to remove:"
    echo ""

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "  No accounts configured."
        pause
        return
    fi

    local i=1
    while IFS='|' read -r name email key; do
        echo "  $i) $name ($email)"
        ((i++))
    done < "$CONFIG_FILE"

    echo ""
    echo "  c) Cancel"
    echo ""
    read -p "Select: " choice

    [[ "$choice" == "c" || "$choice" == "C" ]] && return

    # Validate input is a number
    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        return
    fi

    # Get details of the account to remove
    # sed -n "${choice}p" prints just that line
    local line=$(sed -n "${choice}p" "$CONFIG_FILE")
    
    if [ -z "$line" ]; then
        echo "Invalid selection."
        pause
        return
    fi

    IFS='|' read -r r_name r_email r_key <<< "$line"

    # Remove from file
    # sed -i.bak is used for compatibility with macOS sed
    sed -i.bak "${choice}d" "$CONFIG_FILE" && rm "${CONFIG_FILE}.bak"

    echo ""
    echo "  Removed account: $r_name"
    echo ""
    
    read -p "  Delete SSH key file too? (y/n): " del_key
    if [[ "$del_key" == "y" || "$del_key" == "Y" ]]; then
        rm -f "$SSH_DIR/$r_key"
        rm -f "$SSH_DIR/$r_key.pub"
        echo "  SSH key deleted."
    fi

    pause
}

# Function to switch account
switch_account() {
    local choice=$1
    
    # Get account details
    local line=$(sed -n "${choice}p" "$CONFIG_FILE")
    IFS='|' read -r s_name s_email s_key <<< "$line"

    echo ""
    echo "Switching to $s_name..."

    # Set git config
    git config --global user.name "$s_name"
    git config --global user.email "$s_email"

    # Update SSH config
    cat > "$SSH_DIR/config" <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_DIR/$s_key
    IdentitiesOnly yes
EOF
    # Set permissions for SSH config
    chmod 600 "$SSH_DIR/config"

    echo ""
    echo "======================================================"
    echo "  SWITCHED TO: $s_name"
    echo "  Email: $s_email"
    echo "  SSH Key: $s_key"
    echo "======================================================"
    echo ""
    pause
}

# Function to test connection
test_connection() {
    clear
    echo "======================================================"
    echo "         TESTING GITHUB SSH CONNECTION"
    echo "======================================================"
    echo ""
    echo "  Current account:"
    echo "   $(git config --global user.name)"
    echo ""
    echo "  Connecting to GitHub..."
    echo ""
    ssh -T git@github.com
    echo ""
    echo "======================================================"
    pause
}

# Function to show current key
show_key() {
    clear
    echo "======================================================"
    echo "           CURRENT SSH PUBLIC KEY"
    echo "======================================================"
    echo ""

    # Find current key from SSH config
    local current_key=""
    if [ -f "$SSH_DIR/config" ]; then
        # Grep IdentityFile, verify it exists
        current_key=$(grep "IdentityFile" "$SSH_DIR/config" | awk '{print $2}')
        # Remove path prefix to get just filename if needed, or use full path
    fi

    if [ -z "$current_key" ]; then
        echo "  No SSH key currently configured in $SSH_DIR/config"
        echo ""
        pause
        return
    fi
    
    # The config path might have ~ or $HOME, expand if necessary or just cat directly if absolute
    # But usually ssh config uses full paths or ~
    # Let's try to cat the .pub version
    
    local pub_key="${current_key}.pub"
    
    # Expand tilde if present
    pub_key="${pub_key/#\~/$HOME}"

    echo "  Key file: $current_key"
    echo ""
    echo "  PUBLIC KEY (copy this to GitHub):"
    echo ""
    echo "------------------------------------------------------"
    if [ -f "$pub_key" ]; then
        cat "$pub_key"
    else
        echo "  Public key file not found at: $pub_key"
    fi
    echo "------------------------------------------------------"
    echo ""
    pause
}

# Function to show help
show_help() {
    clear
    echo "======================================================"
    echo "                   HELP / GUIDE"
    echo "======================================================"
    echo ""
    echo "  HOW TO USE THIS TOOL:"
    echo ""
    echo "  1. ADD ACCOUNTS"
    echo "     Press 'a' to add a new GitHub account."
    echo "     You'll need your GitHub username and email."
    echo "     A new SSH key will be generated automatically."
    echo ""
    echo "  2. ADD SSH KEY TO GITHUB"
    echo "     After adding an account, you MUST add the SSH"
    echo "     public key to your GitHub account:"
    echo "     - Go to https://github.com/settings/keys"
    echo "     - Click 'New SSH key'"
    echo "     - Select 'Authentication Key'"
    echo "     - Paste the public key shown"
    echo ""
    echo "  3. SWITCH ACCOUNTS"
    echo "     Simply press the number of the account you"
    echo "     want to switch to. This will update:"
    echo "     - Git global user.name and user.email"
    echo "     - SSH configuration for GitHub"
    echo ""
    echo "  4. TEST CONNECTION"
    echo "     Press 't' to verify your SSH connection works."
    echo "     You should see: 'Hi username! You've successfully...'"
    echo ""
    pause
}


# ============================================
# MAIN LOOP
# ============================================

# First run check
if [ ! -f "$CONFIG_FILE" ]; then
    clear
    echo "======================================================"
    echo "      WELCOME TO GIT ACCOUNT SWITCHER v1.0"
    echo "======================================================"
    echo ""
    echo "  This tool helps you easily switch between multiple"
    echo "  GitHub accounts on the same computer."
    echo ""
    echo "  Let's set up your first GitHub account!"
    echo ""
    pause
    add_account
fi

while true; do
    clear
    echo "======================================================"
    echo "           GIT ACCOUNT SWITCHER v1.0"
    echo "======================================================"
    echo ""
    
    # Show current account
    current_name=$(git config --global user.name)
    current_email=$(git config --global user.email)
    echo "  Current: $current_name <$current_email>"
    echo ""
    echo "------------------------------------------------------"
    echo "  ACCOUNTS:"
    echo "------------------------------------------------------"
    
    count=0
    if [ -f "$CONFIG_FILE" ]; then
        while IFS='|' read -r name email key; do
            ((count++))
            echo "  $count) $name ($email)"
        done < "$CONFIG_FILE"
    fi
    
    if [ $count -eq 0 ]; then
        echo "  No accounts configured. Press 'a' to add one."
    fi

    echo ""
    echo "------------------------------------------------------"
    echo "  OPTIONS:"
    echo "------------------------------------------------------"
    echo "  a) Add new account"
    echo "  r) Remove account"
    echo "  t) Test GitHub SSH connection"
    echo "  k) Show current SSH public key"
    echo "  h) Help / Setup guide"
    echo "  q) Quit"
    echo "======================================================"
    echo ""
    read -p "Select option: " choice

    case $choice in
        [0-9]*)
            if [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
                switch_account "$choice"
            fi
            ;;
        a|A) add_account ;;
        r|R) remove_account ;;
        t|T) test_connection ;;
        k|K) show_key ;;
        h|H) show_help ;;
        q|Q) exit 0 ;;
        *) 
            echo "Invalid option."
            sleep 1
            ;;
    esac
done