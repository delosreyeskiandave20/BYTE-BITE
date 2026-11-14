/// Turns a catalog name into the file name its photo must use.
///
/// Lower case, with every run of other characters turned into `_`:
/// "LED Daytime Running Light (DRL)" -> `led_daytime_running_light_drl`.
String imageSlug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

/// File name (without extension) a design item's photo must use in
/// `assets/design/`.
String designImageSlug(String item) => imageSlug(item);

/// File name (without extension) a maintenance choice's photo must use in
/// `assets/maintenance/`.
///
/// The group comes first because some choices appear in more than one group
/// as different products: a "Paper Filter" under "Oil Filter or Oil Strainer"
/// is `oil_filter_or_oil_strainer-paper_filter`, while the air filter one is
/// `air_filter-paper_filter`.
String maintenanceImageSlug(String group, String choice) =>
    '${imageSlug(group)}-${imageSlug(choice)}';

/// File name (without extension) an accessory choice's photo must use in
/// `assets/accessories/`, e.g. `helmet-full_face_helmet`.
String accessoryImageSlug(String group, String choice) =>
    '${imageSlug(group)}-${imageSlug(choice)}';
