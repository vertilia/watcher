#!/bin/sh

#
# handler plugin for watcher
# sends telegram notification on not_found event
#

#
# plugin environment:
# - use telegram_send.sh as template
# - define _usage(), _option() and _validate() same as telegram versions
# - implement _on_not_found() as a call to telegram_send()
#

#
# include telegram_send.sh plugin
#
[ -x "$(dirname `which "$0"`)/plugins/telegram_send.sh" ] \
    && . "$(dirname `which "$0"`)/plugins/telegram_send.sh" \
    || { echo "Cannot locate telegram_send.sh library in $(dirname `which "$0"`)/plugins" >&2; exit 10; }

#
# use interface implementations from telegram_send.sh
#
tg_nf_usage() { telegram_usage; }
tg_nf_option() { telegram_option "$@"; }
tg_nf_validate() { telegram_validate; }

#
# send Telegram notification when expected string not found on page
#
tg_nf_on_not_found() { telegram_send; }
