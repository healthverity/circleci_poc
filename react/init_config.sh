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


# Grab latest version of parker
PARKER_VERSION=$(aws s3 ls s3://healthveritydev/parker/ | tail -n 1 | awk -F " " '{print $NF}')
# TODO see if this can be grabbed programmatically 
PARKER_AWS_ACCESS='AWSAccessKeyId=AKIAYOUNYC773OKNXQUY&Signature=18kIPUyL%2BklZflJl1XggAiq%2FGXw%3D&Expires=1613920193'
PARKER_LINK="https://healthveritydev.s3.amazonaws.com/parker/$PARKER_VERSION?$PARKER_AWS_ACCESS"
PARKER_INTEGRITY_KEY='sha512-LOqcHD7ol+T0HskNvzikvfrZU+58tK2I9ZgHiUzDJb3P76vDAzWHSXAWuRBYFacjPTrUO4ReY+rocdVafxyuEQ=='

CREATE_APP=0
while [[ $CREATE_APP == 0 ]]
do

    APP_NAME=$(wait_for_input "Please enter the name for your React app")

    COMPOSE_NO_TYPESCRIPT="  $APP_NAME:\n    tty: true\n    build:\n      context: ./$APP_NAME\n    volumes:\n      - ./$APP_NAME/src/:/app/src/\n      - ./$APP_NAME/public/index.html:/app/public/index.html\n"
    COMPOSE_TYPESCRIPT="  $APP_NAME:\n    tty: true\n    build:\n      context: ./$APP_NAME\n    volumes:\n      - ./$APP_NAME/src/:/app/src/\n      - ./$APP_NAME/public/index.html:/app/public/index.html\n      - ./APP_NAME/tsconfig.json/:/app/tsconfig.json/\n"

    TYPESCRIPT=$(confirm "Is this app using TypeScript over JavaScript")
    
    if [[ $TYPESCRIPT == 0 ]]
    then
        npx create-react-app $APP_NAME --template typescript
        COMPOSE_ADD=$COMPOSE_TYPESCRIPT
    else
        npx create-react-app $APP/_NAME
        COMPOSE_ADD=$COMPOSE_NO_TYPESCRIPT
    fi

    echo "Adding parker repo dependency to package.json and package-lock.json"
    BABEL_PKG_VERSION=$(grep -A1 '    "@babel/plugin-proposal-class-properties": {' $APP_NAME/package-lock.json -x | tail -n 1 | awk -F " \"" '{print $NF}' | sed 's/",//')
    PARKER_SEARCH="  \"dependencies\": {"
    PARKER_PACKAGE="    \"@healthverity/parker\": \"$PARKER_LINK\","
    PARKER_PACKAGE_LOCK="    \"@healthverity/parker\": {\n      \"version\": \"$PARKER_LINK\",\n      \"integrity\": \"$PARKER_INTEGRITY_KEY\",\n      \"requires\": {\n        \"@babel/plugin-proposal-class-properties\": \"^$BABEL_PKG_VERSION\"\n      }\n    },"
    insert_string_into_file $PARKER_SEARCH $PARKER_PACKAGE $AWK_INSERT_AFTER $APP_NAME/package.json
    insert_string_into_file $PARKER_SEARCH $PARKER_PACKAGE_LOCK $AWK_INSERT_AFTER $APP_NAME/package-lock.json 

    echo "Making Dockerfile for $APP_NAME"
    awk -v APP_NAME=$APP_NAME '{ sub(/app_name/,APP_NAME) }1' Dockerfile.react_app > $APP_NAME/Dockerfile

    echo "Adding service for $APP_NAME to docker-compose.yml"
    COMPOSE_SEARCH='networks:'
    insert_string_into_file $COMPOSE_SEARCH $COMPOSE_ADD $AWK_INSERT_BEFORE "docker-compose.yml"

    echo "Adding start and stop make targets for $APP_NAME to Makefile"
    printf "\nmake start-$APP_NAME:\n\tdocker-compose up -d $APP_NAME\n" >> Makefile
    printf "\nmake stop-$APP_NAME:\n\tdocker-compose stop $APP_NAME\n\tdocker-compose rm -f $APP_NAME\n" >> Makefile

    CREATE_APP=$(confirm "Would you like to make another React app")
done

rm Dockerfile.react_app

echo "Done setting up React apps"
