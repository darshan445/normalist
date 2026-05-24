export const SYNC_INTERVAL_OPTIONS = [
  { value: "every_6_hours", label: "Every 6 hours" },
  { value: "every_12_hours", label: "Every 12 hours" },
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
];

export const DEFAULT_SYNC_INTERVAL = "daily";

export function syncIntervalLabel(interval) {
  const match = SYNC_INTERVAL_OPTIONS.find((option) => option.value === interval);
  return match?.label ?? "Daily";
}

export const FEED_TYPE_CHOICES = [
  {
    label: "File Upload",
    value: "file_upload",
    helpText: "Upload CSV or Excel stock files manually.",
  },
  {
    label: "Google Sheets",
    value: "google_sheets",
    helpText: "Connect a published Google Sheets URL.",
  },
];

export function feedTypeLabel(feedType) {
  const match = FEED_TYPE_CHOICES.find((choice) => choice.value === feedType);
  return match?.label ?? feedType;
}

export function feedIcon(feedType) {
  if (feedType === "google_sheets") return "🔗";
  return "📁";
}

export function defaultFeedName(feedType) {
  if (feedType === "google_sheets") return "Google Sheets";
  return "File Upload";
}

export function buildFeedTypeChoices(usedFeedTypes = []) {
  const used = new Set(usedFeedTypes);

  return FEED_TYPE_CHOICES.map((choice) => {
    const alreadyAdded = used.has(choice.value);
    return {
      ...choice,
      disabled: alreadyAdded,
      helpText: alreadyAdded
        ? "Already added for this supplier"
        : choice.helpText,
    };
  });
}

export function availableFeedTypes(usedFeedTypes = []) {
  const used = new Set(usedFeedTypes);
  return FEED_TYPE_CHOICES.map((c) => c.value).filter((type) => !used.has(type));
}

export function canAddMoreFeeds(usedFeedTypes = []) {
  return availableFeedTypes(usedFeedTypes).length > 0;
}
