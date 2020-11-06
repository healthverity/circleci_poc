#!/bin/bash

wait_for_input() {
    local _prompt _response

    if [ "$1" ]; then _prompt="$1"; else _prompt="Input"; fi
    _prompt="$_prompt: "

    _response=""
    while [[ -z $_response ]]
    do
        read -r -p "$_prompt" _response
    done
    echo $_response
}

confirm() {
#
# syntax: confirm [<prompt>]
#
# Prompts the user to enter Yes or No and returns 0/1.
#
    local _prompt _default _response
    
    if [ "$1" ]; then _prompt="$1"; else _prompt="Are you sure"; fi
    _prompt="$_prompt [y/n] ?"
    
    # Loop forever until the user enters a valid response (Y/N or Yes/No).
    while true; do
        read -r -p "$_prompt " _response
        case "$_response" in
        [Yy][Ee][Ss]|[Yy]) # Yes or Y (case-insensitive).
            _RETURN=0
            break
            ;;
        [Nn][Oo]|[Nn])  # No or N.
            _RETURN=1
            break
            ;;
        *) # Anything else (including a blank) is invalid.
            ;;
        esac
    done
    echo $_RETURN
}

IFS='%'
CHOOSE_CONFIG=0

while [[ $CHOOSE_CONFIG == 0 ]]
do
    CONFIG=$(wait_for_input "Enter the name of the desired configuration (q/Q to quit)")

    if [[ $CONFIG == [qQ] || $CONFIG == [qQ][uU][iI][tT] ]]
    then
        echo "Exitting repo setup"
        exit 0
    elif [[ ! -d $CONFIG || -z $CONFIG ]]
    then
        echo "Specified config directory $CONFIG doesn't exist."
    else
        echo "Setting up repo to use $CONFIG"

        shopt -s dotglob # Move hidden files
        mv ./$CONFIG/* .
        rmdir ./$CONFIG
        rm .config

        if [[ -a "init_config.sh" ]]
        then
            echo "Running init_config.sh for $CONFIG"
            ./init_config.sh
            rm init_config.sh
        fi

        CHOOSE_PROMPT=$(echo -e "Would you like to pick another configuration?\nWarning: overlapping files will be ovewritten\nif they are in the next configuration chosen")
        CHOOSE_CONFIG=$(confirm $CHOOSE_PROMPT)
    fi

done

echo "Removing unused configurations"
find . -name .config -execdir pwd \; | xargs rm -rf

SEARCH='[Pp]ennyworth'
REPO_NAME=$(basename `git rev-parse --show-toplevel`)
echo "Changing all instances of 'pennyworth' in files to $REPO_NAME"
find . -type f | while read line; do
    if [[ $(echo $line | grep -i 'git') ]]; then
        continue
    fi
    LC_ALL=C sed -i '' -E "s/$SEARCH/$REPO_NAME/g" $line
done

rm setup_repo.sh
