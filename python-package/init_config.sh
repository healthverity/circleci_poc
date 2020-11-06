#!/bin/bash

PYTEST_DEFAULT="pytest >= 6.1.0, < 7.0.0"
COVERAGE_DEFAULT="coverage >= 5.3, < 6.0"
PYTEST_COV_DEFAULT="pytest-cov >= 2.10.0, < 3.0.0"
PYLINT_DEFAULT="pylint >= 2.6.0, < 3.0.0"

change_version() {
    MODULE="$1"
    DEFAULT=$2
    echo "Default for $MODULE is $DEFAULT"

    echo "If you'd like to keep the default range for $MODULE,"
    echo "simply press enter after this prompt."
    echo "Enter your version pin/range for $MODULE: "
    read NEW_VERSION
    
    if [[ -z $NEW_VERSION ]]
    then
        echo $DEFAULT >> test/test-requirements.txt
    else
        echo "$MODULE $NEW_VERSION" >> test/test-requirements.txt
    fi
    echo ""
}

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

SET_PYTHON_VER=$(confirm "Would you like to set a Python version for this repo")
if [[ $SET_PYTHON_VER == 0 ]]
then
    while true; do
        PYTHON_VER=$(wait_for_input "Please enter your desired Python version")
        if [[ $PYTHON_VER =~ ^[[:digit:]]\.[[:digit:]]? ]]
        then
            sed -i '' "s/alpine/$PYTHON_VER-alpine/g" Dockerfile
            sed -i '' "s/python=3/python=$PYTHON_VER/g" Makefile
            sed -i '' "s/pip3/pip$PYTHON_VER/g" Makefile
            sed -i '' "s/>=3/>=$PYTHON_VER/g" setup.py
            break
        fi
        echo "Entered Python version doesn't follow the format of #.#"
    done
fi

PACKAGE_NAME=$(wait_for_input "What is the name of the package being developed?")
mkdir $PACKAGE_NAME
echo "\"\"\" A package for ___. \"\"\"


__version__ = '0.0.0'
" > $PACKAGE_NAME/__init__.py
shopt -s dotglob # Find hidden files
sed -i '' "s/package_name/$PACKAGE_NAME/g" *   # Replace in files in root directory
sed -i '' "s/package_name/$PACKAGE_NAME/g" */* # And in subdirectories

echo "Would you like to change the versions of the"
echo "included testing modules? The defaults are:"
echo $PYTEST_DEFAULT
echo $COVERAGE_DEFAULT
echo $PYTEST_COV_DEFAULT
echo $PYLINT_DEFAULT
echo ""

CHANGE_ANY=$(confirm "Change")

if [[ $CHANGE_ANY == 0 ]]
then
    echo "When entering the version for a module,"
    echo "you will enter the entire desired portion"
    echo "that appears after the module name in"
    echo "test-requirements.txt, e.g. the ''>= min, < max'"
    echo "portion of $PYTEST_DEFAULT"
    echo ""
    echo > test/test-requirements.txt
    change_version "pytest" "$PYTEST_DEFAULT"
    change_version "coverage" "$COVERAGE_DEFAULT"
    change_version "pytest-cov" "$PYTEST_COV_DEFAULT"
    change_version "pylint" "$PYLINT_DEFAULT"
fi
