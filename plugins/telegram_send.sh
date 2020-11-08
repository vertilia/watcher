#!/bin/sh

# dependency: curl
# see: https://core.telegram.org/bots/api#sendmessage

#
# plugin template:
# - list of declared callbacks in the interface:
#   - ${PLUGIN_NAME}_usage() - called to display plugin options
#   - ${PLUGIN_NAME}_option(string[] $options) - receives the list of unrecognised options
#   - ${PLUGIN_NAME}_validate() - validates environment after all args processed
# - list of event listeners
#   - ${PLUGIN_NAME}_on_not_found(string $response) - fires when expected message not found on page
#   - ${PLUGIN_NAME}_on_found(string $response) - fires when expected message not found on page
#   - ${PLUGIN_NAME}_on_recent(string $response) - fires when expected message not found on page
#   - ${PLUGIN_NAME}_on_error(int $err) - fires when error occurs during page load
#

#
# notification parameters for Telegram
#
TG_SEND_TOKEN=
TG_SEND_CHAT_ID=
TG_SEND_MSG=

#
# displayed in usage message of caller script
# telegram_usage()
#
telegram_usage()
{
    echo "Telegram options:
 --tg-token TOKEN	Telegram bot token, required
 --tg-chat-id CHAT	Telegram chat id, required
 --tg-msg STRING	Telegram chat message, required"
}

#
# called during argument parsing phase of caller script
# returns the number of args to shift
# returns 0 if argument $1 is unknown
# telegram_option(string[] $arguments)
#
telegram_option()
{
    case "$1" in
    # telegram parameters
    --tg-token)
        TG_SEND_TOKEN="$2"
        return 2
        ;;
    --tg-chat-id)
        TG_SEND_CHAT_ID="$2"
        return 2
        ;;
    --tg-msg)
        TG_SEND_MSG="$2"
        return 2
        ;;
    esac
}

#
# verifies the environment after all options processed
# on error outputs error message and returns corresponding error code
# telegram_validate()
#
telegram_validate()
{
    if [ -z "$TG_SEND_TOKEN" ]; then
        echo "Error: Telegram token not provided"
        return 11
    fi
    if [ -z "$TG_SEND_CHAT_ID" ]; then
        echo "Error: Telegram chat ID not provided"
        return 12
    fi
    if [ -z "$TG_SEND_MSG" ]; then
        echo "Error: Telegram chat message not provided"
        return 13
    fi
}

#
# telegram_send()
#
telegram_send()
{
    curl \
        -s \
        -X POST \
        -d chat_id="$TG_SEND_CHAT_ID" \
        -d text="$TG_SEND_MSG" \
        https://api.telegram.org/bot$TG_SEND_TOKEN/sendMessage
}
