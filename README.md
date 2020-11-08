# watcher
Lightweight and easily extensible script for polling web pages and sending notifications

## Description

When waiting for specific page to start displaying specific information you normally create a crontab file with `curl` request to retrieve the page, piped to `grep` to find the expected text, piped to another `curl` to send you notification to your preferred messenger.

This script allows you to automate the process by combining on a single crontab line the options for initial `curl` call, the text to search for (as extended regex) and for your custom plugin to handle the events like expected text found, not found, or error condition.

### Simple example

When launching without plugin the script may be useful to just maintain the log of site availability, like in the following example:

```
./watcher.sh -I --url http://www.example.com --expect '200 OK'
```

Which will produce the following output:

```
[2020-11-08 13:04:32] found
```

Automating the call to be launched every minute via the crontab and redirecting the STDOUT to the logfile you can build the database of your site availability.

### Messenger notifications

To notify you on events like error happened loading the page or expected text not found on the page you will need to use `watcher` with a customisable plugin like the one provided in `custom` subfolder. Plugin's purpose is to define the functions that will be called if specific events occur when running the base script. It also defines hooks used to parse command line options and validate configuration before making the request.

For example, when using Telegram notifications we need to pass parameters like Telegram Token, Chat ID and message text from command line using plugin-specific options `--tg-token`, `--tg-chat-id` and `--tg-msg`. Slack plugin will define its own options, like `--slk-service-id`, `--slk-payload` etc.

To facilitate the task some plugins (like Telegram) are already provided in `plugins` folder, so the custom plugins will just reuse the implemented functions by renaming them, like in the following example for custom `tg_nf` plugin:

```
function tg_nf_option() { telegram_option "$@"; }
```

In the following example we will build a one-liner that notifies us by Telegram (sending message to specific chat from your specific bot) if some text stops appearing on the page. This assumes that you already have the API token for your bot and chat ID (you will use them in place of generic `API_TOKEN` and `CHAT_ID` values). If not, see the [Telegram bots introduction](https://core.telegram.org/bots) to grasp how to get these.

```
./watcher.sh -I --url http://www.example.com --expect '200 OK' --plugin custom/tg_nf --tg-token API_TOKEN --tg-chat-id CHAT_ID --tg-msg '200 OK status not found on www.example.com page'
```

This you may register as a user cron job with `crontab -e` to be run every minute:

```
*/1 * * * * ~/watcher/watcher.sh -s --url https://www.example.com -A 'Watcher/1.0' --expect "200 OK" --plugin custom/tg_nf --tg-token API_TOKEN --tg-chat-id CHAT_ID --tg-msg '200 OK status not found on www.example.com page' --period 3600 >> /tmp/watcher.example.log
```

All the options that `watcher` does not recognise by itself or by its plugins are considered as options to `curl` call, so in our example curl command will be executed with the following options:

```
curl -s --url https://www.example.com -A 'Watcher/1.0'
```

Here we added the `-s` option to run the curl "silently" without displaying the progress meter. The output is appended to `/tmp/watcher.example.log` file which will collect the history of `watcher` runs.

## Recent notifications

You may decide that sending you notifications on a specific event every minute is too annoying. If some text starts to appear on a page you only want to be notified once per hour and not every minute. In this case you may define a period during which the notification will be paused. The calls will still be made, the text looked up on the page, but instead of the corresponding event handler will be run the `recent` one.

## Plugin definition

When creating your own plugins you will be able to define the preliminary hooks and event handlers. All of them optional, but at least one event handler is recommended. All defined functions will have the same prefix as your plugin filename. For example, when your plugin filename is `tg_nf.sh`, your functions will all start with `tg_nf_`, like `tg_nf_usage` or `tg_nf_on_not_found`.

Preliminary hooks

- **usage**

  `PLUGIN_usage` is called when usage message is displayed by the `watcher` script. Displays the list of plugin options and their default values.

  Returns void.

- **option**

  `PLUGIN_option` is called during the command line options parsing phase when `watcher` does not recognise current option starting with `-` (dash) and before attributing this option to `curl`. Function receives current list of options where previously parsed options are already shifted-out, so current option is stored in `$1` argument. This function may be called many times (if several options provided on command line).

  Returns the number of `shift`s to execute by the caller script or `0` if the option is not recognised. In the latter case the option will be attributed to `curl`.

- **validation**

  `PLUGIN_validation` is called after all the options are processed to validate that plugin is setup correctly.

  Returns void or numeric error code. In case of error may `echo` to STDOUT the error message that will be output within usage message by `watcher`. The main execution process will be stopped.

Event handlers

- **on_found**

  Expected text is found on the page. Receives response as `$1` argument.

- **on_not_found**

  Expected text is not found on the page. Receives response as `$1` argument.

- **on_recent**

  Notification for a specific event has been sent recently and pops again during the specified period. Receives response as `$1` argument, event name (`found` or `not_found`) as $2 argument.

- **on_error**

  `curl` response returned empty string. Receives `curl` error code (`$?`) as `$1` argument.
