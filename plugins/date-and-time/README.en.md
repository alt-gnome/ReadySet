# Date & Time plugin

Configures the timezone and date/time through `org.freedesktop.timedate1`. By
default, automatic timezone detection and NTP are enabled. Manual values are
applied only when their corresponding automatic setting is disabled.

## Settings

| Variable | Description | Default value |
| -------- | ----------- | ------------- |
| `date-and-time.automatic-timezone` | Automatically detect the timezone | `true` |
| `date-and-time.automatic-datetime` | Automatically set the date and time via NTP | `true` |

## Stored context variables

| Variable | Description |
| -------- | ----------- |
| `date-and-time.timezone` | Selected timezone |
| `date-and-time.datetime` | Selected date and time as a Unix timestamp in seconds |
