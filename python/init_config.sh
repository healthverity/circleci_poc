#!/bin/bash

PYTEST_DEFAULT="pytest >= 6.1.0, < 7.0.0"
COVERAGE_DEFAULT="coverage >= 5.3, < 6.0"
PYTEST_COV_DEFAULT="pytest-cov >= 2.10.0, < 3.0.0"
PYLINT_DEFAULT="pylint >= 2.6.0, < 3.0.0"

# UAT requirements
SBASE_DEFAULT="seleniumbase >= 1.49.0, < 2.0.0"
BOTO3_DEFAULT="boto3 >= 1.15.0, < 2.0.0"
PSYCOPG2_DEFAULT="psycopg2-binary >= 2.8.4, < 3.0.0"

UAT_MAKE_VARS="BROWSER ?= chrome\nMODULE ?= test_login.py\nSTAGE ?= local\nHEADED ?= headed\nUSE_DB ?= --db # Export as empty to prevent use: export USE_DB=\nREPORT_DIR ?= report\nREPORT_NAME ?= cettie_report.html"
UAT_MAKE_TARGETS="
install-webdrivers:
\tvenv/bin/sbase install chromedriver latest
\tvenv/bin/sbase install geckodriver latest
\tvenv/bin/sbase install edgedriver latest

setup-uat: create-venv install-webdrivers

uat:
\tvenv/bin/pytest --browser \$(BROWSER) \\
\t\t--stage \$(STAGE) \\
\t\t--html \$(REPORT_DIR)/\$(REPORT_NAME) \\
\t\t--\$(HEADED) \\
\t\t\$(USE_DB)

uat-module:
\tvenv/bin/pytest \$(MODULE) \\
\t\t--browser \$(BROWSER) \\
\t\t--stage \$(STAGE) \\
\t\t--html \$(REPORT_DIR)/\$(REPORT_NAME) \\
\t\t--\$(HEADED) \\
\t\t\$(USE_DB)"

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

insert_string_into_file() {
    local _search _add _command _file

    _search=$1
    _add=$2
    _command=$3
    _file=$4

    echo | awk -v SEARCH_STR=$_search -v ADD_STR=$_add $_command $_file > $_file.bak && mv $_file.bak $_file
}

# So these AWK command variables keep their formatting
IFS=

AWK_INSERT_BEFORE='{
if ($0 == SEARCH_STR) {
    print ADD_STR;
    print $0
}
else {
    print $0
}
}'
AWK_INSERT_AFTER='{
if ($0 == SEARCH_STR) {
    print $0;
    print ADD_STR
}
else {
    print $0
}
}'

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
            break
        fi
        echo "Entered Python version doesn't follow the format of #.#"
    done
fi

USE_UAT=$(confirm "Will this project have a GUI and need automated UAT")
if [[ $USE_UAT == 0 ]]
then
    # Add make targets for UAT
    printf $UAT_MAKE_TARGETS >> Makefile
    # Add environment vars used in UAT make targets
    insert_string_into_file 'LINT_THRESHOLD ?= 9' $UAT_MAKE_VARS $AWK_INSERT_AFTER Makefile
    # Add UAT requirements to test-requirements.txt
    echo $SBASE_DEFAULT >> test/test-requirements.txt
    echo $BOTO3_DEFAULT >> test/test-requirements.txt
    echo $PSYCOPG2_DEFAULT >> test/test-requirements.txt
else
    rm -rf test/uat
fi

echo "Would you like to change the versions of the"
echo "included testing modules? The defaults are:"
echo $PYTEST_DEFAULT
echo $COVERAGE_DEFAULT
echo $PYTEST_COV_DEFAULT
echo $PYLINT_DEFAULT
if [[ $USE_UAT == 0 ]]
then
    echo $SBASE_DEFAULT
    echo $BOTO3_DEFAULT
    echo $PSYCOPG2_DEFAULT
fi
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
    if [[ $USE_UAT == 0 ]]
    then
        change_version "seleniumbase" "$SBASE_DEFAULT"
        change_version "boto3" "$BOTO3_DEFAULT"
        change_version "psycopg2" "$PSYCOPG2_DEFAULT"
    fi
fi
