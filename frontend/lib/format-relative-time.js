const UNITS = [
  { limit: 60, divisor: 1, unit: "second" },
  { limit: 3600, divisor: 60, unit: "minute" },
  { limit: 86400, divisor: 3600, unit: "hour" },
  { limit: 604800, divisor: 86400, unit: "day" },
  { limit: Infinity, divisor: 604800, unit: "week" },
];

export function formatRelativeTime(isoString) {
  if (!isoString) return "—";

  const date = new Date(isoString);
  if (Number.isNaN(date.getTime())) return "—";

  const seconds = Math.round((date.getTime() - Date.now()) / 1000);
  const absSeconds = Math.abs(seconds);

  const match = UNITS.find(({ limit }) => absSeconds < limit);
  const value = Math.max(1, Math.round(absSeconds / match.divisor));

  const formatter = new Intl.RelativeTimeFormat("en", { numeric: "auto" });
  return formatter.format(seconds < 0 ? -value : value, match.unit);
}
