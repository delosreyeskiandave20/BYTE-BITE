/// Key specifications and Philippine pricing for each gallery motorcycle.
///
/// Specs are manufacturer figures. A null field means it has not been
/// confirmed yet and the gallery shows it as not available, rather than a
/// guess. Prices are suggested retail prices (SRP) as of [srpAsOf], from
/// published Philippine price lists; dealer prices can differ.
class MotorcycleInfo {
  const MotorcycleInfo({
    this.engine,
    this.powerTorque,
    this.transmission,
    this.fuel,
    this.dimensions,
    this.brakesWheels,
    this.convenience,
    this.srp = const {},
    this.srpRange,
  });

  final String? engine;
  final String? powerTorque;
  final String? transmission;
  final String? fuel;
  final String? dimensions;
  final String? brakesWheels;
  final String? convenience;

  /// Peso SRP per variant name, where the variant's own price is known.
  final Map<String, int> srp;

  /// Model-wide price range, shown when a variant has no price of its own.
  final String? srpRange;

  List<(String, String?)> get specRows => [
    ('Engine', engine),
    ('Power & Torque', powerTorque),
    ('Transmission', transmission),
    ('Fuel Economy & Tank', fuel),
    ('Dimensions & Weight', dimensions),
    ('Brakes & Wheels', brakesWheels),
    ('Convenience', convenience),
  ];
}

const srpAsOf = 'June 2026';

MotorcycleInfo? motorcycleInfo(String brand, String model) =>
    _info['$brand|$model'];

const _info = <String, MotorcycleInfo>{
  // ---------------------------------------------------------------- Honda
  'Honda|BeAT': MotorcycleInfo(
    engine: '110cc, air-cooled, SOHC, PGM-FI (eSP)',
    powerTorque: '6.6 kW (9.0 PS) @ 7,500 rpm · 9.3 Nm @ 5,500 rpm',
    transmission: 'Automatic (V-Matic CVT)',
    fuel: '4.2 L tank',
    dimensions: '1,877 × 669 × 1,092 mm · approx. 89 kg',
    brakesWheels: 'Front disc, rear drum with CBS · 14-inch cast wheels',
    convenience: 'Idling stop, answer-back system, digital panel',
    srp: {'Playful': 72400, 'Premium': 74400},
  ),
  'Honda|Click125': MotorcycleInfo(
    engine: '125cc, liquid-cooled, SOHC, PGM-FI (eSP)',
    powerTorque: '8.2 kW (11.1 PS) @ 8,500 rpm · 10.8 Nm @ 5,000 rpm',
    transmission: 'Automatic (V-Matic CVT)',
    fuel: '5.5 L tank',
    dimensions: '1,918 × 679 × 1,066 mm · approx. 112 kg',
    brakesWheels: 'Front disc, rear drum with CBS · 14-inch tubeless',
    convenience: 'LED lights, digital panel, idling stop, answer-back',
    srp: {'Standard': 81900},
  ),
  'Honda|Giorno+': MotorcycleInfo(
    engine: '125cc, liquid-cooled, 4-valve, PGM-FI (eSP+)',
    transmission: 'Automatic (V-Matic CVT)',
    brakesWheels: 'Front disc, rear drum · 12-inch wheels',
    convenience: 'Smart Key, LED lights, USB charger, retro styling',
    srp: {'Standard': 101900},
  ),
  'Honda|Click160': MotorcycleInfo(
    engine: '157cc, liquid-cooled, 4-valve, PGM-FI (eSP+)',
    powerTorque: '11.3 kW (15.4 PS) @ 8,500 rpm · 13.8 Nm @ 7,000 rpm',
    transmission: 'Automatic (V-Matic CVT)',
    fuel: '5.5 L tank',
    dimensions: '1,929 × 679 × 1,088 mm · approx. 115 kg',
    brakesWheels: 'Front disc, rear drum with CBS · 14-inch tubeless',
    convenience: 'Smart Key, USB charger, LED lights, idling stop',
    srp: {'Standard': 116900},
  ),
  'Honda|PCX160': MotorcycleInfo(
    engine: '157cc, liquid-cooled, 4-valve, PGM-FI (eSP+)',
    powerTorque: '11.8 kW (16.0 PS) @ 8,500 rpm · 14.7 Nm @ 6,500 rpm',
    transmission: 'Automatic (V-Matic CVT)',
    fuel: '8.1 L tank',
    dimensions: '1,936 × 742 × 1,108 mm · approx. 132 kg',
    brakesWheels: 'Front disc (ABS on RoadSync) · 14-inch front, 13-inch rear',
    convenience:
        'Smart Key, 30 L under-seat storage, USB-C, Honda Selectable '
        'Torque Control; RoadSync smartphone link on RoadSync',
    srp: {'Standard': 133400, 'RoadSync': 154900},
  ),
  'Honda|ADV160': MotorcycleInfo(
    engine: '157cc, liquid-cooled, 4-valve, PGM-FI (eSP+)',
    powerTorque: '11.8 kW (16.0 PS) @ 8,500 rpm · 14.7 Nm @ 6,500 rpm',
    transmission: 'Automatic (V-Matic CVT)',
    fuel: '8.1 L tank',
    dimensions: '1,950 × 763 × 1,196 mm · approx. 133 kg',
    brakesWheels: 'Front disc with ABS · 14-inch front, 13-inch rear',
    convenience:
        'Smart Key, 2-step adjustable windscreen, Honda Selectable Torque '
        'Control, USB-C; RoadSync on RoadSync',
    srpRange: 'From ₱166,900',
  ),
  'Honda|ADV350': MotorcycleInfo(
    engine: '330cc, liquid-cooled, SOHC, 4-valve, PGM-FI',
    powerTorque: '21.5 kW (29.2 PS) @ 7,500 rpm · 31.8 Nm @ 5,250 rpm',
    transmission: 'Automatic (V-Matic CVT)',
    fuel: '11.7 L tank',
    dimensions: 'approx. 186 kg',
    brakesWheels: 'Front and rear disc, dual-channel ABS · 15/14-inch',
    convenience:
        'Smart Key, Honda Selectable Torque Control, RoadSync, adjustable '
        'windscreen, USB-C',
    srp: {'Standard': 306000},
  ),
  'Honda|Wave RSX': MotorcycleInfo(
    engine: '110cc, air-cooled, SOHC, PGM-FI',
    transmission: '4-speed rotary',
    brakesWheels: 'Front drum or disc by variant · 17-inch wheels',
    srp: {'Drum': 62900, 'Disc': 64900},
  ),
  'Honda|XRM125': MotorcycleInfo(
    engine: '125cc, air-cooled, SOHC, PGM-FI',
    transmission: '4-speed manual',
    brakesWheels: 'Front disc, rear drum · 17-inch wheels',
    convenience: 'Dual-sport styling; Motard has street tires',
    srp: {'DS': 71900, 'DSX': 75400, 'Motard': 76900},
  ),
  'Honda|Winner X': MotorcycleInfo(
    engine: '150cc, liquid-cooled, DOHC, 4-valve, PGM-FI',
    powerTorque: '11.5 kW (15.6 PS) @ 9,000 rpm · 13.5 Nm @ 6,500 rpm',
    transmission: '6-speed manual',
    fuel: '4.5 L tank',
    dimensions: '2,019 × 727 × 1,104 mm · approx. 123 kg',
    brakesWheels: 'Front and rear disc, ABS on ABS variants · 17-inch',
    convenience: 'Digital panel, LED lights; Smart Key on ABS variants',
    srp: {'Standard': 123900},
    srpRange: '₱123,900 – 131,900 by variant',
  ),
  'Honda|TMX125': MotorcycleInfo(
    engine: '125cc (Alpha) / 150cc (Supremo), air-cooled, OHV',
    transmission: 'Manual',
    brakesWheels: '18-inch wheels; Supremo has a front disc',
    convenience: 'Built for daily hauling and tricycle use',
    srp: {'Alpha': 56900, 'Supremo': 78900},
  ),
  'Honda|CBR150R': MotorcycleInfo(
    engine: '150cc, liquid-cooled, DOHC, 4-valve, PGM-FI',
    powerTorque: '12.6 kW (17.1 PS) @ 9,000 rpm · 14.4 Nm @ 7,000 rpm',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '12 L tank',
    dimensions: 'approx. 139 kg',
    brakesWheels: 'Front and rear disc, ABS · USD fork · 17-inch',
    convenience: 'Full-digital panel, LED lights',
    srp: {'Standard': 183900},
  ),
  'Honda|XR150L': MotorcycleInfo(
    engine: '150cc, air-cooled, SOHC',
    transmission: '5-speed manual',
    fuel: '12 L tank',
    dimensions: 'approx. 129 kg',
    brakesWheels: 'Front disc, rear drum · 19-inch front, 17-inch rear',
    convenience: 'Long-travel suspension for rough roads',
    srp: {'Standard': 97900},
  ),
  'Honda|CRF150L': MotorcycleInfo(
    engine: '150cc, air-cooled, SOHC, PGM-FI',
    transmission: '5-speed manual',
    fuel: '7.2 L tank',
    dimensions: 'approx. 122 kg',
    brakesWheels: 'Front and rear disc · 21-inch front, 18-inch rear',
    convenience: 'Off-road suspension, high ground clearance',
    srp: {'Standard': 147900},
  ),
  'Honda|Rebel': MotorcycleInfo(
    engine: '471cc twin (Rebel 500) / 1,084cc twin (Rebel 1100)',
    transmission: '6-speed manual',
    brakesWheels: 'Disc brakes with ABS · 16-inch wheels',
    convenience: 'Low seat, LED lights; Rebel 1100 adds riding modes',
    srp: {'Rebel 500': 399000, 'Rebel 1100': 665000},
  ),
  'Honda|CB500 Hornet': MotorcycleInfo(
    engine: '471cc, liquid-cooled, parallel-twin, DOHC',
    powerTorque: '35 kW (47.6 PS) @ 8,600 rpm · 43 Nm @ 6,500 rpm',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '17.1 L tank',
    dimensions: 'approx. 192 kg',
    brakesWheels: 'Dual front discs, ABS · 17-inch',
    convenience: '5-inch TFT display, Honda Selectable Torque Control',
    srp: {'Standard': 379000},
  ),
  'Honda|CB650R': MotorcycleInfo(
    engine: '649cc, liquid-cooled, inline-four, DOHC',
    powerTorque: '70 kW (95 PS) @ 12,000 rpm · 63 Nm @ 9,500 rpm',
    transmission: '6-speed (E-Clutch version available)',
    fuel: '15.4 L tank',
    dimensions: 'approx. 203 kg',
    brakesWheels: 'Dual front discs, ABS · Showa USD fork · 17-inch',
    convenience: '5-inch TFT display, Honda Selectable Torque Control',
    srp: {'Standard': 524000},
  ),
  // --------------------------------------------------------------- Yamaha
  'Yamaha|Mio Gear': MotorcycleInfo(
    engine: '125cc, air-cooled, SOHC, Blue Core fuel injection',
    transmission: 'Automatic (CVT)',
    fuel: '4.2 L tank',
    brakesWheels: 'Front disc, rear drum · 14-inch',
    convenience: 'Front storage, hook; Stop & Start System on S',
    srp: {'Standard': 79400, 'S': 82400},
  ),
  'Yamaha|Mio Gravis': MotorcycleInfo(
    engine: '125cc, air-cooled, SOHC, Blue Core fuel injection',
    transmission: 'Automatic (CVT)',
    brakesWheels: 'Front disc, rear drum · 12-inch',
    convenience: 'Stop & Start System, power socket',
    srp: {'Standard': 84900},
  ),
  'Yamaha|Mio Fazzio': MotorcycleInfo(
    engine: '125cc, air-cooled, Blue Core Hybrid fuel injection',
    transmission: 'Automatic (CVT)',
    fuel: '5.1 L tank',
    brakesWheels: 'Front disc, rear drum · 12-inch',
    convenience: 'Smart Key, Y-Connect, USB charger, retro styling',
    srp: {'Standard': 93900},
  ),
  'Yamaha|Mio i125': MotorcycleInfo(
    engine: '125cc, air-cooled, SOHC, Blue Core fuel injection',
    transmission: 'Automatic (CVT)',
    fuel: '4.2 L tank',
    brakesWheels: 'Front disc, rear drum · 14-inch',
    convenience: 'Stop & Start System on S',
    srp: {'Standard': 77900, 'S': 82900},
  ),
  'Yamaha|Lexi 155': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    transmission: 'Automatic (CVT)',
    convenience: 'Smart Key; Y-Connect on Connected',
    srp: {'Standard': 99900},
  ),
  'Yamaha|NMAX': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    powerTorque: '11.3 kW (15.4 PS) @ 8,000 rpm · 13.9 Nm @ 6,500 rpm',
    transmission: 'Automatic (CVT)',
    fuel: '7.1 L tank',
    dimensions: 'approx. 131 kg',
    brakesWheels: 'Front and rear disc, ABS · 13-inch',
    convenience: 'Smart Key, Y-Connect, traction control, USB charger',
    srp: {'Standard': 155900, 'Tech MAX': 175900},
  ),
  'Yamaha|Aerox': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    powerTorque: '11.3 kW (15.4 PS) @ 8,000 rpm · 13.9 Nm @ 6,500 rpm',
    transmission: 'Automatic (CVT)',
    fuel: '5.5 L tank',
    brakesWheels: 'Front disc (ABS on SP) · 14-inch',
    convenience: 'Smart Key, Y-Connect, full-digital panel',
    srp: {'Standard': 125900, 'SP': 163900},
  ),
  'Yamaha|Sniper155': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '4.6 L tank',
    brakesWheels: 'Front and rear disc (ABS on R) · 17-inch',
    convenience: 'Full-digital panel; Smart Key and Y-Connect on R',
    srp: {'Standard': 125900, 'R': 145900},
  ),
  'Yamaha|YZF-R15M': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    powerTorque: '13.5 kW (18.4 PS) @ 10,000 rpm',
    transmission: '6-speed, assist & slipper clutch, quickshifter',
    fuel: '11 L tank',
    dimensions: 'approx. 141 kg',
    brakesWheels: 'Front and rear disc, dual-channel ABS · USD fork',
    convenience: 'TFT display, traction control, Y-Connect',
    srp: {'R15M': 204000},
  ),
  'Yamaha|MT-15': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    powerTorque: '13.5 kW (18.4 PS) @ 10,000 rpm',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '10 L tank',
    brakesWheels: 'Front and rear disc, ABS · USD fork · 17-inch',
    convenience: 'LED lights, digital panel',
    srp: {'Standard': 180000},
  ),
  'Yamaha|XSR155': MotorcycleInfo(
    engine: '155cc, liquid-cooled, SOHC, VVA',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '10 L tank',
    brakesWheels: 'Front and rear disc · USD fork · 17-inch',
    convenience: 'Round LED headlight, retro styling',
    srp: {'Standard': 182000},
  ),
  'Yamaha|XMAX': MotorcycleInfo(
    engine: '292cc, liquid-cooled, SOHC, 4-valve',
    powerTorque: '20.6 kW (28 PS) @ 7,250 rpm · 29 Nm @ 5,750 rpm',
    transmission: 'Automatic (CVT)',
    fuel: '13 L tank',
    dimensions: 'approx. 183 kg',
    brakesWheels: 'Front and rear disc, ABS · 15-inch front, 14-inch rear',
    convenience:
        'Smart Key, traction control, adjustable windscreen, storage for '
        'two full-face helmets',
    srp: {'Standard': 311000},
  ),
  // --------------------------------------------------------------- Suzuki
  'Suzuki|Burgman 15': MotorcycleInfo(),
  'Suzuki|Access': MotorcycleInfo(
    engine: '124cc, air-cooled, SOHC, fuel injection',
    transmission: 'Automatic (CVT)',
    brakesWheels: 'Front disc, rear drum',
    convenience: 'Bluetooth digital console on Ride Connect Edition',
    srp: {'Standard': 85900, 'Ride Connect Edition': 94900},
  ),
  'Suzuki|Avenis': MotorcycleInfo(
    engine: '124cc, air-cooled, SOHC, fuel injection',
    transmission: 'Automatic (CVT)',
    brakesWheels: 'Front disc, rear drum',
    convenience: 'Sporty styling, digital panel',
    srp: {'Standard': 81400},
  ),
  'Suzuki|Burgman Street 125 EX': MotorcycleInfo(
    engine: '124cc, air-cooled, SOHC, fuel injection',
    transmission: 'Automatic (CVT)',
    brakesWheels: 'Front disc, rear drum · 12-inch wheels',
    convenience: 'Engine auto stop-start, digital panel, USB charger',
    srp: {'Standard': 93400},
  ),
  'Suzuki|Burgman Street': MotorcycleInfo(
    engine: '124cc, air-cooled, SOHC, fuel injection',
    transmission: 'Automatic (CVT)',
    brakesWheels: 'Front disc, rear drum',
    convenience: 'Maxi-scooter styling, large floorboard',
    srp: {'Standard': 84400},
  ),
  'Suzuki|Raider R150': MotorcycleInfo(
    engine: '147cc, liquid-cooled, DOHC, 4-valve, fuel injection',
    transmission: '6-speed manual',
    fuel: '4 L tank',
    dimensions: 'approx. 109 kg',
    brakesWheels: 'Front and rear disc · 17-inch',
    convenience: 'Digital panel, LED lights',
    srp: {'Standard': 121900},
  ),
  'Suzuki|Raider PRO': MotorcycleInfo(srp: {'Standard': 146400}),
  'Suzuki|Smash Fi': MotorcycleInfo(
    engine: '113cc, air-cooled, SOHC, fuel injection',
    transmission: '4-speed rotary',
    brakesWheels: 'Front disc, rear drum · 17-inch',
    srpRange: 'From ₱68,400',
  ),
  'Suzuki|V-STROM 160': MotorcycleInfo(
    transmission: 'Manual',
    convenience: 'Adventure styling, windscreen',
    srp: {'Standard': 146000},
  ),
  'Suzuki|GIXXER 155': MotorcycleInfo(
    engine: '155cc, air-cooled, SOHC, fuel injection',
    transmission: '5-speed manual',
    fuel: '12 L tank',
    brakesWheels: 'Front and rear disc, ABS · 17-inch',
    convenience: 'LED headlight, digital panel',
    srp: {'Standard': 106400},
  ),
  // ------------------------------------------------------------- Kawasaki
  'Kawasaki|Barako II': MotorcycleInfo(
    engine: '175cc, air-cooled, single-cylinder',
    transmission: 'Manual',
    convenience: 'Heavy-duty build for tricycle and cargo use',
    srp: {'Standard': 91500},
  ),
  'Kawasaki|Brusky 125': MotorcycleInfo(
    engine: '125cc, single-cylinder, fuel injection',
    transmission: 'Automatic (CVT)',
    srp: {'Standard': 75000},
  ),
  'Kawasaki|Ninja 500': MotorcycleInfo(
    engine: '451cc, liquid-cooled, parallel-twin, DOHC',
    powerTorque: '33.4 kW (45 PS) @ 9,000 rpm · 42.6 Nm @ 6,000 rpm',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '14 L tank',
    dimensions: 'approx. 171 kg',
    brakesWheels: 'Front and rear disc, ABS · 17-inch',
    convenience:
        'LED lights; SE adds TFT display with smartphone link and '
        'Smart Key',
    srp: {'Standard': 353800, 'SE': 379600},
  ),
  'Kawasaki|Ninja 650': MotorcycleInfo(
    engine: '649cc, liquid-cooled, parallel-twin, DOHC',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '15 L tank',
    dimensions: 'approx. 196 kg',
    brakesWheels: 'Dual front discs, ABS · 17-inch',
    convenience: 'TFT display with Rideology app, traction control',
    srp: {'Standard': 456500},
  ),
  'Kawasaki|Z650': MotorcycleInfo(
    engine: '649cc, liquid-cooled, parallel-twin, DOHC',
    transmission: '6-speed with assist & slipper clutch',
    fuel: '15 L tank',
    dimensions: 'approx. 188 kg',
    brakesWheels: 'Dual front discs, ABS · 17-inch',
    convenience: 'TFT display with Rideology app, traction control',
  ),
  'Kawasaki|Versys 650': MotorcycleInfo(
    engine: '649cc, liquid-cooled, parallel-twin, DOHC',
    transmission: '6-speed manual',
    fuel: '21 L tank',
    dimensions: 'approx. 219 kg',
    brakesWheels: 'Dual front discs, ABS · 17-inch',
    convenience:
        'Adjustable windscreen, TFT display, traction control; LT adds '
        'side cases',
    srp: {'Standard': 514000},
  ),
};
