class CatalogGroup {
  const CatalogGroup({
    required this.title,
    required this.items,
    this.itemChoices = const {},
  });

  final String title;
  final List<String> items;
  final Map<String, List<String>> itemChoices;

  CatalogGroup.withChoices({required this.title, required List<String> choices})
    : items = const [],
      itemChoices = {title: choices};
}

class CatalogChoiceDetails {
  const CatalogChoiceDetails({
    this.description,
    this.imageAsset,
    this.imageUrl,
  });

  final String? description;
  final String? imageAsset;
  final String? imageUrl;
}

const accessoryDatabaseFields = [
  'Accessory Category',
  'Accessory Group',
  'Accessory Name',
  'Accessory Brand',
  'Part Number',
  'Description',
  'Product Images',
  'Price',
  'Seller or Shop Name',
  'Seller Platform',
  'Seller Link',
  'Availability Status',
  'Installation Notes',
];

final accessoryGroups = [
  CatalogGroup.withChoices(
    title: 'Helmet',
    choices: [
      'Full-face helmet',
      'Modular helmet',
      'Open-face helmet',
      'Half helmet',
      'Motocross helmet',
      'Adventure helmet',
      'Dual-sport helmet',
      'Bluetooth-ready helmet',
      'DOT-certified helmet',
      'ECE-certified helmet',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Helmet Accessories',
    choices: [
      'Clear visor',
      'Smoke visor',
      'Iridium visor',
      'Anti-fog visor',
      'Pinlock insert',
      'Helmet intercom',
      'Bluetooth speaker',
      'Helmet microphone',
      'Helmet sun visor',
      'Helmet liner',
      'Helmet cheek pads',
      'Helmet bag',
      'Helmet lock',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Riding Jacket',
    choices: [
      'Mesh jacket',
      'Textile jacket',
      'Leather jacket',
      'Waterproof jacket',
      'Summer jacket',
      'Winter jacket',
      'Adventure jacket',
      'Racing jacket',
      'Reflective jacket',
      'Armored jacket',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Riding Pants',
    choices: [
      'Motorcycle jeans',
      'Textile riding pants',
      'Leather riding pants',
      'Waterproof riding pants',
      'Adventure pants',
      'Racing pants',
      'Armored pants',
      'Thermal riding pants',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Riding Gloves',
    choices: [
      'Short-cuff gloves',
      'Long-cuff gloves',
      'Mesh gloves',
      'Leather gloves',
      'Waterproof gloves',
      'Winter gloves',
      'Racing gloves',
      'Adventure gloves',
      'Touchscreen gloves',
      'Armored gloves',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Motorcycle Boots',
    choices: [
      'Short riding boots',
      'Touring boots',
      'Racing boots',
      'Adventure boots',
      'Motocross boots',
      'Waterproof boots',
      'Leather boots',
      'Steel-toe riding boots',
      'Casual motorcycle shoes',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Rain Gear',
    choices: [
      'Rain jacket',
      'Rain pants',
      'One-piece rain suit',
      'Boot covers',
      'Glove covers',
      'Helmet rain cover',
      'Waterproof backpack cover',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Motorcycle Cover',
    choices: [
      'Indoor cover',
      'Outdoor cover',
      'Waterproof cover',
      'UV-resistant cover',
      'Dustproof cover',
      'Heat-resistant cover',
      'Half cover',
      'Full cover',
      'Lockable cover',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Top Box',
    choices: [
      'Plastic top box',
      'Aluminum top box',
      'Small top box',
      'Medium top box',
      'Large top box',
      'Hard top box',
      'Detachable top box',
      'Top box with backrest',
      'Top box with brake light',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Side Case and Saddlebag',
    choices: [
      'Hard side case',
      'Aluminum pannier',
      'Soft saddlebag',
      'Waterproof saddlebag',
      'Leather saddlebag',
      'Side box',
      'Detachable side case',
      'Expandable saddlebag',
      'Universal saddlebag',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Tank and Tail Bag',
    choices: [
      'Magnetic tank bag',
      'Strap-on tank bag',
      'Waterproof tank bag',
      'Expandable tank bag',
      'Tail bag',
      'Seat bag',
      'Tail-mounted hard case',
      'Tail-mounted soft bag',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Motorcycle Backpack',
    choices: [
      'Standard backpack',
      'Waterproof backpack',
      'Riding backpack',
      'Hard-shell backpack',
      'Hydration backpack',
      'Laptop backpack',
      'Reflective backpack',
      'Expandable backpack',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Phone Holder',
    choices: [
      'Handlebar phone holder',
      'Mirror-mounted phone holder',
      'Stem-mounted phone holder',
      'Clamp-type holder',
      'Silicone phone holder',
      'Locking phone holder',
      'Waterproof phone holder',
      'Wireless-charging phone holder',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Navigation and Communication',
    choices: [
      'Motorcycle GPS',
      'Smartphone navigation mount',
      'Bluetooth intercom',
      'Rider-to-rider intercom',
      'Rider-to-passenger intercom',
      'Helmet Bluetooth system',
      'Communication headset',
      'GPS tracker',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'USB and Charging Accessories',
    choices: [
      'USB-A charger',
      'USB-C charger',
      'Fast charger',
      'Wireless charger',
      'Handlebar charging port',
      'Waterproof charging port',
      'Dual USB charger',
      'Battery-direct charger',
      'Accessory power socket',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Security Accessories',
    choices: [
      'Disc-lock alarm',
      'Disc lock',
      'Chain lock',
      'Cable lock',
      'U-lock',
      'Handlebar lock',
      'Brake-lever lock',
      'Alarm system',
      'Security cover',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Crash Protection',
    choices: [
      'Crash bar',
      'Engine guard',
      'Frame slider',
      'Axle slider',
      'Swingarm slider',
      'Fork protector',
      'Bar-end slider',
      'Skid plate',
      'Radiator guard',
      'Hand guard',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Wind Protection',
    choices: [
      'Standard windshield',
      'Touring windshield',
      'Tall windshield',
      'Short windshield',
      'Adjustable windshield',
      'Smoked windshield',
      'Clear windshield',
      'Wind deflector',
      'Hand-wind deflector',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Handlebar Accessories',
    choices: [
      'Handlebar riser',
      'Handlebar clamp',
      'Handlebar pad',
      'Bar-end weights',
      'Bar-end mirrors',
      'Heated grips',
      'Hand guards',
      'Throttle assist',
      'Cruise-control throttle lock',
      'Handlebar extender',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Lighting Accessories',
    choices: [
      'LED headlight',
      'Auxiliary driving lights',
      'Fog lights',
      'LED light bar',
      'LED turn signals',
      'Sequential turn signals',
      'Hazard-light kit',
      'Brake-light flasher',
      'Reflective tape',
      'Additional tail light',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Horn and Visibility Accessories',
    choices: [
      'Standard horn',
      'Dual-tone horn',
      'Air horn',
      'Compact electric horn',
      'Reflective vest',
      'Reflective stickers',
      'Reflective wheel tape',
      'Safety flag',
      'Rear reflector',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Comfort Accessories',
    choices: [
      'Seat cushion',
      'Gel seat pad',
      'Memory-foam seat pad',
      'Seat cover',
      'Heated seat',
      'Passenger backrest',
      'Rider backrest',
      'Footrest',
      'Highway pegs',
      'Foot-peg extender',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Passenger Accessories',
    choices: [
      'Passenger grab bar',
      'Passenger footrest',
      'Passenger foot-peg rubber',
      'Passenger seat cushion',
      'Passenger hand grip',
      'Passenger top-box pad',
      'Passenger rain cover',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Storage Accessories',
    choices: [
      'Cargo net',
      'Bungee cord',
      'Tie-down strap',
      'Ratchet strap',
      'Luggage strap',
      'Cargo hook',
      'Utility pouch',
      'Tool pouch',
      'Saddlebag organizer',
      'Top-box organizer',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Maintenance and Emergency Accessories',
    choices: [
      'Motorcycle tool kit',
      'Tire-repair kit',
      'Tire inflator',
      'Portable air compressor',
      'Jumper cable',
      'Portable jump starter',
      'First-aid kit',
      'Emergency flashlight',
      'Reflective warning triangle',
      'Emergency rain poncho',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Tire Accessories',
    choices: [
      'Tire-pressure gauge',
      'Tire-pressure monitoring system',
      'Tubeless tire-repair kit',
      'Tire plug kit',
      'Tire sealant',
      'Valve-cap set',
      'Angled valve stem',
      'Tire warmers',
      'Wheel balancing weights',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Stand and Parking Accessories',
    choices: [
      'Side-stand pad',
      'Center stand',
      'Paddock stand',
      'Front stand',
      'Rear stand',
      'Motorcycle ramp',
      'Wheel chock',
      'Parking mat',
      'Stand extender',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Cleaning Accessories',
    choices: [
      'Motorcycle shampoo',
      'Chain-cleaning brush',
      'Wheel brush',
      'Detailing brush',
      'Microfiber cloth',
      'Drying towel',
      'Wash mitt',
      'Spray bottle',
      'Motorcycle cleaning kit',
      'Portable pressure washer',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Protection and Appearance Accessories',
    choices: [
      'Tank pad',
      'Tank protector',
      'Frame protection film',
      'Paint protection film',
      'Carbon-fiber cover',
      'Decal kit',
      'Vinyl wrap',
      'Rim stickers',
      'Chrome accessories',
      'Number plate frame',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Performance Accessories',
    choices: [
      'Performance air filter',
      'Slip-on exhaust',
      'Full-system exhaust',
      'Exhaust heat shield',
      'Performance spark plug',
      'Quick shifter',
      'Fuel controller',
      'ECU tuner',
      'Steering damper',
      'Performance suspension',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Scooter Accessories',
    choices: [
      'Scooter windshield',
      'Scooter top box',
      'Front basket',
      'Rear basket',
      'Floor mat',
      'Leg cover',
      'Scooter hand guard',
      'Scooter phone holder',
      'Scooter rear carrier',
      'Scooter wind deflector',
    ],
  ),
  CatalogGroup.withChoices(
    title: 'Electric Motorcycle Accessories',
    choices: [
      'Battery charger',
      'Portable charger',
      'Charging cable',
      'Charging-port cover',
      'Battery storage case',
      'Battery lock',
      'Charging adapter',
      'Range tracker',
      'Electric-motor diagnostic tool',
    ],
  ),
];

final accessoryItemCount = accessoryGroups.length;

final accessoryChoiceCount = accessoryGroups.fold<int>(
  0,
  (total, group) => total + group.itemChoices[group.title]!.length,
);

const accessoryChoiceDetailsByGroup =
    <String, Map<String, CatalogChoiceDetails>>{};

const accessoryNotice =
    'Choices are accessory examples. Verify product dimensions, safety certifications, and seller details before purchase.';

const maintenanceGroups = [
  CatalogGroup(
    title: 'Engine Oil',
    items: [],
    itemChoices: {
      'Engine Oil': [
        'Mineral oil',
        'Semi-synthetic oil',
        'Fully synthetic oil',
        '10W-30',
        '10W-40',
        '10W-50',
        '15W-40',
        '15W-50',
        '20W-40',
        '20W-50',
        'JASO MA',
        'JASO MA2',
        'JASO MB',
      ],
    },
  ),
  CatalogGroup(
    title: 'Oil Filter or Oil Strainer',
    items: [],
    itemChoices: {
      'Oil Filter or Oil Strainer': [
        'Paper filter',
        'Spin-on filter',
        'Reusable metal filter',
        'Screen-type strainer',
        'Centrifugal filter',
        'OEM filter',
        'Aftermarket filter',
      ],
    },
  ),
  CatalogGroup(
    title: 'Gear Oil or Final-Drive Oil',
    items: [],
    itemChoices: {
      'Gear Oil or Final-Drive Oil': [
        '75W-90',
        '80W-90',
        '85W-140',
        'Mineral gear oil',
        'Synthetic gear oil',
        'Hypoid gear oil',
      ],
    },
  ),
  CatalogGroup(
    title: 'Air Filter',
    items: [],
    itemChoices: {
      'Air Filter': [
        'Paper filter',
        'Foam filter',
        'Cotton-gauze filter',
        'Washable filter',
        'OEM filter',
        'Aftermarket filter',
        'Performance filter',
        'CVT air filter',
      ],
    },
  ),
  CatalogGroup(
    title: 'Spark Plug',
    items: [],
    itemChoices: {
      'Spark Plug': [
        'Nickel spark plug',
        'Copper-core spark plug',
        'Platinum spark plug',
        'Iridium spark plug',
        'Standard spark plug',
        'Resistor spark plug',
        'Long-reach spark plug',
        'Short-reach spark plug',
      ],
    },
  ),
  CatalogGroup(
    title: 'Coolant',
    items: [],
    itemChoices: {
      'Coolant': [
        'Premixed coolant',
        'Concentrated coolant',
        'Ethylene-glycol coolant',
        'Long-life coolant',
        'Aluminum-safe coolant',
        'Silicate-free coolant',
        'Racing coolant',
      ],
    },
  ),
  CatalogGroup(
    title: 'Brake Fluid',
    items: [],
    itemChoices: {
      'Brake Fluid': ['DOT 3', 'DOT 4', 'DOT 5.1', 'Mineral hydraulic fluid'],
    },
  ),
  CatalogGroup(
    title: 'Brake Pads and Brake Shoes',
    items: [],
    itemChoices: {
      'Brake Pads and Brake Shoes': [
        'Organic brake pads',
        'Semi-metallic brake pads',
        'Sintered brake pads',
        'Ceramic brake pads',
        'OEM brake pads',
        'Aftermarket brake pads',
        'Front brake pads',
        'Rear brake pads',
        'Front brake shoes',
        'Rear brake shoes',
      ],
    },
  ),
  CatalogGroup(
    title: 'Drive Chain',
    items: [],
    itemChoices: {
      'Drive Chain': [
        'Standard roller chain',
        'O-ring chain',
        'X-ring chain',
        'Z-ring chain',
        'Sealed chain',
        'Heavy-duty chain',
        'Racing chain',
        'OEM chain',
        'Aftermarket chain',
        '420 chain',
        '428 chain',
        '520 chain',
        '525 chain',
        '530 chain',
      ],
    },
  ),
  CatalogGroup(
    title: 'Sprockets',
    items: [],
    itemChoices: {
      'Sprockets': [
        'Front sprocket',
        'Rear sprocket',
        'Steel sprocket',
        'Aluminum sprocket',
        'Standard gearing',
        'Acceleration gearing',
        'High-speed gearing',
      ],
    },
  ),
  CatalogGroup(
    title: 'Chain Lubricant',
    items: [],
    itemChoices: {
      'Chain Lubricant': [
        'Wet chain lubricant',
        'Dry chain lubricant',
        'Chain wax',
        'Road-use chain lubricant',
        'Off-road chain lubricant',
        'Racing chain lubricant',
        'O-ring-safe chain lubricant',
      ],
    },
  ),
  CatalogGroup(
    title: 'Scooter CVT Parts',
    items: [],
    itemChoices: {
      'Scooter CVT Parts': [
        'Standard CVT belt',
        'Reinforced CVT belt',
        'Performance CVT belt',
        'Standard rollers',
        'Lightweight rollers',
        'Heavyweight rollers',
        'Sliding rollers',
        'Variator sliders',
        'Clutch shoes',
        'Standard clutch bell',
        'Performance clutch bell',
        'Standard clutch springs',
        'Performance clutch springs',
        'Standard contra spring',
        'Performance contra spring',
        'CVT air filter',
      ],
    },
  ),
  CatalogGroup(
    title: 'Tires',
    items: [],
    itemChoices: {
      'Tires': [
        'Tube-type tire',
        'Tubeless tire',
        'Bias-ply tire',
        'Radial tire',
        'Commuter tire',
        'Touring tire',
        'Sport tire',
        'Sport-touring tire',
        'Rain tire',
        'Dual-purpose tire',
        'Adventure tire',
        'Off-road tire',
        'Motocross tire',
        'Scooter tire',
      ],
    },
  ),
  CatalogGroup(
    title: 'Battery',
    items: [],
    itemChoices: {
      'Battery': [
        'Conventional wet-cell battery',
        'Maintenance-free battery',
        'AGM battery',
        'Gel battery',
        'Lithium-ion battery',
        'Lithium-iron-phosphate battery',
        'OEM battery',
        'Aftermarket battery',
      ],
    },
  ),
  CatalogGroup(
    title: 'Fork and Suspension Items',
    items: [],
    itemChoices: {
      'Fork and Suspension Items': [
        'Fork oil',
        'Fork seals',
        'Fork dust seals',
        'Fork bushings',
        'Fork springs',
        'Standard rear shock',
        'Adjustable rear shock',
        'Shock bushings',
        'Swingarm bearings',
        'Steering-head bearings',
        'Tapered roller bearings',
        'Ball bearings',
      ],
    },
  ),
  CatalogGroup(
    title: 'Fuel-System Cleaners',
    items: [],
    itemChoices: {
      'Fuel-System Cleaners': [
        'Fuel-injector cleaner',
        'Carburetor cleaner',
        'Throttle-body cleaner',
        'Fuel-system cleaner',
        'Fuel stabilizer',
        'Octane booster',
      ],
    },
  ),
  CatalogGroup(
    title: 'Electrical Maintenance Items',
    items: [],
    itemChoices: {
      'Electrical Maintenance Items': [
        'Main fuse',
        'Spare blade fuses',
        'Starter relay',
        'Regulator/rectifier',
        'Headlight bulb',
        'LED headlight',
        'Tail-light bulb',
        'LED tail light',
        'Turn-signal bulb',
        'LED turn signal',
        'Brake-light switch',
        'Horn',
        'Wiring connector',
        'Electrical tape',
        'Heat-shrink tubing',
        'Cable ties',
        'Contact cleaner',
      ],
    },
  ),
  CatalogGroup(
    title: 'Grease and Protective Chemicals',
    items: [],
    itemChoices: {
      'Grease and Protective Chemicals': [
        'Multipurpose grease',
        'Waterproof grease',
        'Lithium grease',
        'High-temperature grease',
        'Silicone grease',
        'Anti-seize compound',
        'Thread-locking compound',
        'Penetrating oil',
        'Contact cleaner',
        'Brake cleaner',
        'Silicone spray',
        'Rust inhibitor',
      ],
    },
  ),
  CatalogGroup(
    title: 'Cleaning Products',
    items: [],
    itemChoices: {
      'Cleaning Products': [
        'Motorcycle shampoo',
        'Degreaser',
        'Chain cleaner',
        'Brake cleaner',
        'Engine cleaner',
        'Carburetor cleaner',
        'Throttle-body cleaner',
        'Metal polish',
        'Chrome polish',
        'Plastic polish',
        'Rubber protectant',
        'Rust remover',
        'Wax',
        'Ceramic spray',
        'Microfiber cloth',
        'Chain brush',
      ],
    },
  ),
  CatalogGroup(
    title: 'Electric Motorcycle Maintenance Items',
    items: [],
    itemChoices: {
      'Electric Motorcycle Maintenance Items': [
        'Traction battery',
        'Removable battery',
        'Fixed battery',
        '12-volt battery',
        'Battery charger',
        'Charging cable',
        'Charging-port cover',
        'Charging-port seal',
        'Charging-port fuse',
        'Motor coolant',
        'Battery coolant',
        'Brake pads',
        'Tires',
        'Wheel bearings',
        'Suspension parts',
        'Fuses',
        'Relays',
      ],
    },
  ),
];

final maintenanceItemCount = maintenanceGroups.length;

final maintenanceChoiceCount = maintenanceGroups.fold<int>(
  0,
  (total, group) =>
      total +
      group.itemChoices.values.fold<int>(
        0,
        (count, choices) => count + choices.length,
      ),
);

const maintenanceChoiceDetailsByGroup =
    <String, Map<String, CatalogChoiceDetails>>{};

const maintenanceOwnedPartNamesByCategory = <String, Set<String>>{
  'engine': {
    'engineoil',
    'oilfilteroroilstrainer',
    'finaldrivegearoil',
    'airfilterelement',
    'sparkplug',
    'coolanthoseandcoolantliquidcooledmodels',
    'drivebelt',
    'variatorrollerset',
    'variatorface',
    'clutchshoeset',
    'clutchbell',
    'clutchspringset',
    'drivechain',
    'frontandrearsprocketset',
  },
  'electrical': {
    'battery',
    'starterrelaysolenoid',
    'rectifierregulator',
    'fusesetandfusebox',
    'headlightbulbledassembly',
    'taillightassembly',
    'turnsignallamps',
    'brakelightswitches',
    'horn',
  },
  'suspension': {
    'steeringheadbearingset',
    'frontforkassembly',
    'forksealanddustsealset',
    'forkbushingset',
    'forkoil',
    'rearshockabsorber',
    'rearshockbushing',
    'swingarmbearingbushingset',
    'linkagebearingsetmodelswithlinkage',
    'wheelbearingset',
  },
  'wheels': {
    'fronttire',
    'reartire',
    'frontbrakepadsetorshoeset',
    'rearbrakepadsetorshoeset',
    'frontbrakeshoeset',
    'rearbrakeshoeset',
    'frontbrakepadset',
    'rearbrakepadset',
    'wheelbearingset',
  },
};

const maintenanceOwnedCatalogProductNames = <String>{
  'airfilterelement',
  'performanceairfilter',
  'frontbrakeshoeset',
  'tubelesstire909017',
  'rearshockabsorber',
};

String normalizeMaintenancePartName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool isMaintenanceOwnedCatalogProduct(String name) =>
    maintenanceOwnedCatalogProductNames.contains(
      normalizeMaintenancePartName(name),
    );

const maintenanceRecordFields = [
  'Service date and odometer reading',
  'Motorcycle brand, model, year, and version',
  'Work performed and parts replaced',
  'Part numbers and service provider',
  'Next service due date or odometer reading',
  'Notes, receipts, and inspection results',
];

const maintenanceNotice =
    'Choices are maintenance-supply examples. Check the owner’s manual and supplier specifications before purchase.';
