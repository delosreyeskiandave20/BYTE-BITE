import 'item_specs.dart';

/// Parts a seller can pick in Add Item step 2, per category.
const partsByCategory = <String, List<String>>{
  'Engine': [
    'Spark plug',
    'Air filter',
    'Piston kit',
    'Cylinder block',
    'Cylinder head',
    'Gasket set',
    'Valves',
    'Camshaft',
    'Carburetor',
    'Throttle body',
    'Fuel injector',
    'Fuel pump',
    'Fuel tank',
    'Clutch',
    'Drive belt (CVT)',
    'Pulley set',
    'Rollers',
    'Chain & sprockets',
    'Exhaust / Muffler',
    'Radiator',
  ],
  'Electrical': [
    'Battery',
    'Headlight bulb',
    'LED headlight',
    'Signal lights',
    'Tail light',
    'Horn',
    'Ignition coil',
    'CDI / ECU',
    'Stator / Magneto',
    'Regulator / Rectifier',
    'Starter motor',
    'Wiring harness',
    'Handle switches',
    'Fuses',
    'Speedometer / Gauge',
  ],
  'Suspension': [
    'Front fork / Front shock',
    'Rear shock',
    'Fork oil',
    'Fork seals',
    'Swing arm',
    'Bushings',
    'Steering bearings',
  ],
  'Wheels and Tires': [
    'Front tire',
    'Rear tire',
    'Inner tube',
    'Mags / Rims',
    'Spokes',
    'Wheel bearings',
    'Brake pads',
    'Brake shoe',
    'Brake disc',
    'Brake caliper',
    'Brake master cylinder',
    'Tire valve',
  ],
  'Body Parts': [
    'Fairings / Panels',
    'Front fender',
    'Rear fender',
    'Side mirrors',
    'Seat',
    'Footrest',
    'Handlebar',
    'Windshield / Visor',
    'Grab bar',
    'Center / Side stand',
    'Floorboard',
    'Head cover',
  ],
  'Accessories': [
    'Helmet',
    'Phone holder',
    'Top box',
    'Side box',
    'Crash guard',
    'Hand grips',
    'Seat cover',
    'Motorcycle cover',
    'USB charger',
    'Alarm / Anti-theft',
    'Riding gloves',
    'Raincoat',
  ],
  'Maintenance': [
    'Engine oil',
    'Gear oil',
    'Coolant',
    'Brake fluid',
    'Chain lube',
    'Oil filter',
    'Degreaser / Cleaner',
    'Tire sealant',
    'Tool kit',
    'Grease',
  ],
  'Designs': [
    'Decals / Stickers',
    'Full wrap',
    'Custom paint',
    'Seat design',
    'Plate holder',
    'Rim tape / Mag stickers',
    'Emblem / Logo',
  ],
};

/// The spec-table column auto-filled for a listed part, or null when the
/// part has no data (custom parts never get one).
ItemSpecField? specFieldForPart(String part) => switch (part) {
  'Front tire' => ItemSpecField.frontTire,
  'Rear tire' => ItemSpecField.rearTire,
  'Battery' => ItemSpecField.battery,
  'Spark plug' => ItemSpecField.sparkPlug,
  'Engine oil' => ItemSpecField.engineOil,
  'Chain & sprockets' || 'Drive belt (CVT)' => ItemSpecField.chainSprockets,
  'Fuel tank' => ItemSpecField.fuelTank,
  _ => null,
};

/// Brands in the order the motorcycle checklist groups them.
const motorcycleBrandOrder = [
  'Honda',
  'Yamaha',
  'Suzuki',
  'Kawasaki',
  'Kymco',
  'Rusi',
  'Motorstar',
  'TVS',
];

/// "Yamaha NMAX 155" → "Yamaha".
String motorcycleBrand(String motorcycle) => motorcycle.split(' ').first;

/// "Yamaha NMAX 155" → "NMAX 155", for compact lists such as item cards.
String motorcycleModel(String motorcycle) {
  final space = motorcycle.indexOf(' ');
  return space < 0 ? motorcycle : motorcycle.substring(space + 1);
}

/// Table motorcycles grouped by brand in [motorcycleBrandOrder]; brands not
/// in that list follow in table order.
Map<String, List<String>> motorcyclesByBrand(List<ItemSpecRow> rows) {
  final groups = <String, List<String>>{
    for (final brand in motorcycleBrandOrder) brand: [],
  };
  for (final row in rows) {
    groups
        .putIfAbsent(motorcycleBrand(row.motorcycle), () => [])
        .add(row.motorcycle);
  }
  groups.removeWhere((_, models) => models.isEmpty);
  return groups;
}

String _normalize(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

int _editDistance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = [i, ...List<int>.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      current[j] = [
        previous[j] + 1,
        current[j - 1] + 1,
        previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

/// A listed part that a typed name is probably meant to be, for "Did you
/// mean ___?". Looks in [category] first, then every category. Returns null
/// for an exact match or when nothing is close.
({String part, String category})? closestPart(String typed, String category) {
  final needle = _normalize(typed);
  if (needle.length < 2) return null;
  final ordered = [
    category,
    ...partsByCategory.keys.where((c) => c != category),
  ];
  ({String part, String category})? best;
  var bestScore = 0.0;
  for (final group in ordered) {
    for (final part in partsByCategory[group] ?? const <String>[]) {
      final name = _normalize(part);
      if (name == needle) return null;
      // "Sparkplug" vs "Spark plug", "battery 12v" vs "Battery", typos.
      final squashedEqual =
          name.replaceAll(' ', '') == needle.replaceAll(' ', '');
      final distance = _editDistance(name, needle);
      final longest = name.length > needle.length ? name.length : needle.length;
      var score = 1 - distance / longest;
      if (squashedEqual) score = 1;
      if (name.split(' ').any((word) => word.length > 3 && needle == word)) {
        score = score < 0.8 ? 0.8 : score;
      }
      if (score > bestScore) {
        bestScore = score;
        best = (part: part, category: group);
      }
    }
  }
  return bestScore >= 0.75 ? best : null;
}
