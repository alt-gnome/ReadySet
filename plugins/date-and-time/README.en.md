# Date & Time plugin

Configures the timezone and date/time through `org.freedesktop.timedate1`. By
default, automatic timezone detection is enabled. The toggle for automatic date
and time via NTP is shown only when `CanNTP` is available on
`org.freedesktop.timedate1`; if NTP is unavailable, the date and time are set
manually. Manual values are applied only when their corresponding automatic
setting is disabled.

## Settings

| Variable                           | Description                                 | Default value |
| ---------------------------------- | ------------------------------------------- | ------------- |
| `date-and-time.automatic-timezone` | Automatically detect the timezone           | `true`        |
| `date-and-time.automatic-datetime` | Automatically set the date and time via NTP | `true`        |

## Stored context variables

| Variable                 | Description                                           |
| ------------------------ | ----------------------------------------------------- |
| `date-and-time.timezone` | Selected timezone                                     |
| `date-and-time.datetime` | Selected date and time as a Unix timestamp in seconds |
