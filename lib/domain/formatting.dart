String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';

String fmtDateTime(DateTime d) => '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';
