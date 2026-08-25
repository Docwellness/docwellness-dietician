// Mirrors the backend's utils/dayGroups.js DAY_GROUPS rotation exactly:
// Monday's meals repeat on Friday, Tuesday's on Saturday, Wednesday's on
// Sunday, Thursday is unique (see that file's own comment, sourced from
// the DocWellness Diet Plan 4page-4.pdf 7-day template) - the underlying
// value sent to/from the backend is always the canonical 'Monday'/
// 'Tuesday'/'Wednesday'/'Thursday' string; this only affects display.
//
// Single source of truth for every day-group header across the diet plan
// wizard and the days-array system's own screens - previously duplicated
// (and, in the new plan-item wizard's Refine Portions/Timeline/Finalize
// steps, simply missing) across several files.
String dayGroupLabel(String dayGroup) {
  switch (dayGroup) {
    case 'Monday':
      return 'Mon & Fri';
    case 'Tuesday':
      return 'Tue & Sat';
    case 'Wednesday':
      return 'Wed & Sun';
    case 'Thursday':
      return 'Thu';
    default:
      return dayGroup;
  }
}
