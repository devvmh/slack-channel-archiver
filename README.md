Script to download your slack backups

To set it up:

`cp token-sample.sh token.sh`

Then fill in your Slack API token.

To run it:

`./get-day-history.sh`

I run it via crontab every 24 hours

Known issues:

1. I keep getting random directories created in the same directory as this script because of parse errors
2. If there are multiple pages of messages for a 24 hour period, then it won't be outputting valid JSON
3. I haven't actually hooked up the slack2html.php file, or properly attributed where I got it from
