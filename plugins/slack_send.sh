#!/bin/sh

# dependency: curl
# see: https://api.slack.com/messaging/webhooks

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
# notification parameters for Slack
#
SLK_SERVICE_ID=
SLK_CHANNEL_ID=
SLK_USER_ID=
SLK_PAYLOAD=

#
# displayed in usage message of caller script
# slack_usage()
#
slack_usage()
{
    echo "Slack options:
 --slk-service-id SERVICE	Slack service ID, required
 --slk-channel-id CHANEL	Slack channel ID, required
 --slk-user-id USER 	Slack channel ID, required
 --slk-payload STRING	Slack json payload, required"
}

#
# called during argument parsing phase of caller script
# returns the number of args to shift
# returns 0 if argument $1 is unknown
# slack_option(string[] $arguments)
#
slack_option()
{
    case "$1" in
    # slack parameters
    --slk-service_id)
        SLK_SERVICE_ID="$2"
        return 2
        ;;
    --slk-channel-id)
        SLK_CHANNEL_ID="$2"
        return 2
        ;;
    --slk-user-id)
        SLK_USER_ID="$2"
        return 2
        ;;
    --slk-payload)
        SLK_PAYLOAD="$2"
        return 2
        ;;
    esac
}

#
# verifies the environment after all options processed
# on error outputs error message and returns corresponding error code
# slack_validate()
#
slack_validate()
{
    if [ -z "$SLK_SERVICE_ID" ]; then
        echo "Error: Slack service ID not provided"
        return 21
    fi
    if [ -z "$SLK_CHANNEL_ID" ]; then
        echo "Error: Slack channel ID not provided"
        return 22
    fi
    if [ -z "$SLK_USER_ID" ]; then
        echo "Error: Slack user ID not provided"
        return 23
    fi
    if [ -z "$SLK_PAYLOAD" ]; then
        echo "Error: Slack json payload not provided"
        return 24
    fi
}

#
# slack_send()
#
slack_send()
{
    curl \
    -X POST \
    --data-urlencode "payload=$SLK_PAYLOAD" \
    "https://hooks.slack.com/services/$SLK_SERVICE_ID/$SLK_CHANNEL_ID/$SLK_USER_ID"
}
