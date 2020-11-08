#!/bin/sh

# dependencies: curl, grep, printf

#
# curl command line and string to look for
#
CURL=curl
EXPECTED=

#
# notification environment
#
NOTIFY_PERIOD=0
NOTIFY_FILE=/tmp/$(basename "$0" .sh).time

#
# plugin environment
#
PLUGIN=

#
# whether the function is declared
# fn_exists(string $function)
#
fn_exists()
{
    type -t "$1" > /dev/null
}

#
# log event, store timestamp, if not recent send to plugin
# handle_event(string $event, string $response)
#
handle_event()
{
    time_file=`dirname $NOTIFY_FILE`/`basename $NOTIFY_FILE .time`.$1.time
    if [ $(( `date +%s` - `cat "$time_file" || echo 0` )) -gt $NOTIFY_PERIOD ]; then
        date +%s > "$time_file"
        date +"[%F %T] $1"
        [ -n "$PLUGIN" ] && fn_exists "${PLUGIN}_on_$1" && ${PLUGIN}_on_$1 "$2"
    else
        date +"[%F %T] recent $1"
        [ -n "$PLUGIN" ] && fn_exists "${PLUGIN}_on_recent" && ${PLUGIN}_on_recent "$2" "$1"
    fi
}

#
# exit displaying usage and error string
# exit_usage_msg(string $err_msg, int $err_code)
#
exit_usage_msg()
{
    # display base usage message
    echo "Loads a specified page and looks for expected text on it to send
notifications on different events like text found, text not found, recently
notified or error.
Options not listed below are passed as is to curl invocation when loading
the page.
Usage: `basename $0` [options...] [curl-options...]
Options:
 --expect STRING	Expected extended regexp to match on retrieved page,
                	default: null
 --period SECONDS	Do not notify if SECONDS TTL not expired, default: 0
 --plugin PLUGIN	Adds events handlers from PLUGIN.sh file (see README),
                	default: null" >&2

    # if plugin defined display usage message for plugin
    [ -n "$PLUGIN" ] \
        && fn_exists "${PLUGIN}_usage" \
        && msg=`${PLUGIN}_usage` \
        && echo "$msg" >&2

    # display error message
    echo $1 >&2

    # exit with provided error code or 127
    exit ${2:-127}
}

#
# initialise options
#
while [ $# -gt 0 ]; do
    case "$1" in
    # expected text to look for on page
    --expect)
        shift
        EXPECTED="$1"
        shift
        ;;
    # notification environment
    --period)
        shift
        NOTIFY_PERIOD="$1"
        shift
        ;;
    # plugin environment
    --plugin)
        shift
        [ -x "`dirname $1`/`basename $1 .sh`.sh" ] \
            && . "`dirname $1`/`basename $1 .sh`.sh" \
            && PLUGIN="`basename $1 .sh`"
        shift
        ;;
    # pass to plugin if unknown option starts with -
    -*)
        if [ -n "$PLUGIN" ] && fn_exists "${PLUGIN}_option"; then
            # if plugin recognises the option it returns the shift count
            # otherwise it returns 0
            # so use the option as curl option
            ${PLUGIN}_option "$@" && { CURL="$CURL $1"; shift; } || shift $?
        else
            CURL="$CURL $1"
            shift
        fi
        ;;
    # curl option if unknown
    *)
        CURL="$CURL $(printf '%q' "$1")"
        shift
        ;;
    esac
done

#
# check required
#
[ -z "$EXPECTED" ] && exit_usage_msg "Error: expected text not provided" 1
if [ -n "$PLUGIN" ] && fn_exists "${PLUGIN}_validate"; then
	msg=`${PLUGIN}_validate` || exit_usage_msg "$msg" $?
fi

#
# poll the page
#
response=$($CURL)
err=$?

if [ -n "$response" ]; then
    found=$(echo "$response" | egrep "$EXPECTED")
    if [ -z "$found" ]; then
        handle_event "not_found" "$response"
    else
        handle_event "found" "$response"
    fi
else
    date +"[%F %T] error $err"
	[ -n "$PLUGIN" ] && fn_exists "${PLUGIN}_on_error" && ${PLUGIN}_on_error $err
fi
