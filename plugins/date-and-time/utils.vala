namespace DateAndTime {
    int clamp_value (int value, int min, int max) {
        var delta = max - min;

        while (value < min) {
            value += delta;
        }
        while (value >= max) {
            value -= delta;
        }

        return value;
    }

    string get_utc_offset_string (int32 offset) {
        var hours = offset / 60.0d / 60.0d;
        var digit_hours = (int) (hours);

        if (digit_hours - hours > 0.5 || digit_hours - hours > -0.5) {
            digit_hours++;
        }

        var positive = digit_hours >= 0;
        var abs = digit_hours * (positive ? 1 : -1);

        if (abs == 0) {
            return "UTC";
        }

        return "UTC%c%02d:00".printf (positive ? '+' : '-', abs);
    }
}
