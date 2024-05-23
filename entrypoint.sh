#!/bin/sh

if [ -n "$SERVER_PORT" ]; then
    echo "Using custom server port: $SERVER_PORT"
else
    echo "Using default server port: 8001"

    SERVER_PORT=8080
fi

function run_client() {
    SERVER_URL="$1"
    LOCALHOST_SERVER_URL="$2"

    STATIC_DIR="./web"
    cp -r /usr/share/pokerogue "$STATIC_DIR"
    ASSETS_DIR="$STATIC_DIR/assets"

    echo "Patching client to use server URL: $SERVER_URL"
    find "$ASSETS_DIR" -type f -exec sed -i.bak "s!http://localhost:8001!$SERVER_URL!g" {} \;
    echo "Patching client to use localhost server URL: $LOCALHOST_SERVER_URL"
    find "$ASSETS_DIR" -type f -exec sed -i.bak "s!https://api.pokerogue.net!$LOCALHOST_SERVER_URL!g" {} \;

    echo "Starting client..."

    cmd="gostatic --files "$STATIC_DIR" --spa --addr ":$SERVER_PORT" $*"
    echo "[$MODE] $cmd"

    exec $cmd
}

function run {
    case "$MODE" in
        api)
            echo "Starting API..."

            cmd="rogueserver $*"
            echo "[$MODE] $cmd"

            exec $cmd
            ;;
        client)
            run_client "$1" "$2"
            ;;
        *)
            echo "Invalid mode: $MODE"
            exit 1
            ;;
    esac
}

set -ev

if [ -n "$STARTUP" ]; then
    echo "Using custom startup command: ${STARTUP}"

    MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
    run $MODIFIED_STARTUP
else
    run "$@"
fi