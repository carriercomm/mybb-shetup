#! /usr/bin/env bash

set -e

#############################################################################
## Utilities & Libraries
#############################################################################

. general.sh
. files.sh
. input.sh
. php.sh
. mysql.sh

. ../lib/shFlags/src/shflags

#############################################################################
## Business Logic
#############################################################################

welcome_ascii_art() {
    echo "
      __  __       ____  ____
     |  \/  |     |  _ \|  _ \
     | \  / |_   _| |_) | |_) |
     | |\/| | | | |  _ <|  _ <
     | |  | | |_| | |_) | |_) |
     |_|  |_|\__, |____/|____/
              __/ |
             |___/
    "
    echo "
    Because free never tasted so good!

    "
}

welcome_message() {
    clear

    welcome_ascii_art

    info "Welcome to mybb-shetup, the MyBB shell installer. This script will help you set up a copy of MyBB in a minute!"
    pause "Press [ENTER] to continue... or press CTRL+C to quit."

    clear
}

dir_select() {
    input_reply "Where would you like to install MyBB to (FULL PATH)?" "" install

    if [ -d "$install" ]; then
        cd $install
    else
        if input_yn "The path you entered does not exist. Would you like to create it?" "Y"; then
            info "Creating $install..."
            mkdir -p $install
            cd $install
            install_root=$(pwd)
        else
            abort "Declined option to create path. Canceling installation."
        fi
    fi
}

branch_select() {
    input_reply "What branch would you like to download?" "MASTER/stable/feature" branch
}

command_pick() {
    if command_exists git; then
        download_command="git clone https://github.com/mybb/mybb.git -b $branch"
        download_command_used="git"
    elif command_exists wget; then
        download_command="wget --content-disposition https://github.com/mybb/mybb/archive/$branch.zip"
        download_command_used="wget"
    elif command_exists curl; then
        download_command="curl https://github.com/mybb/mybb/archive/$branch.zip -o mybb.zip"
        download_command_used="curl"
    elif command_exists lynx; then
        download_command="lynx -crawl -dump https://github.com/mybb/mybb/archive/$branch.zip > mybb.zip"
        download_command_used="lynx"
    else
        abort "git, wget, curl, or lynx are required to install MyBB. Please install one and try again."
    fi
}

install_confirm() {
    if input_yn "Do you want to install MyBB $branch to $install_dir?" "Y"; then
        download
    else
        abort "Aborting by user choice."
    fi
}

download() {
    command_pick
    if [ $download_command_used = "git" ]; then
        $download_command
    else
        $download_command
        if command_exists unzip; then
            unzip mybb.zip
        else
            abort "Unzip is required to install MyBB. Please install it using your package manager"
        fi
    fi
}

browser_open() {
    url="http://$server_hostname:$server_port/install"

    if command_exists xdg-open; then # Linux
        xdg-open $url
    else # OSX
        open $url
    fi
}

#############################################################################
## Bootstrap
#############################################################################

main() {
    welcome_message
    dir_select
    branch_select
    install_confirm
    files_unfold
    files_config_rename
    files_chmod
    if input_yn "Do you want to set up the MySQL database for MyBB too?" "Y"; then
        mysql_setup
    else
        return 0;
    fi
}

main "$@"
