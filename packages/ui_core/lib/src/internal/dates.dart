/// Calendar days, as the calendar and the date field read them.
library;

/// [d] as a calendar day: local midnight.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
