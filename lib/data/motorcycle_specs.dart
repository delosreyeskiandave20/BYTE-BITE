import 'image_slug.dart';

/// A maintenance item whose size or type differs by motorcycle.
enum SpecItem {
  frontTire('Front tire'),
  rearTire('Rear tire'),
  battery('Battery'),
  sparkPlug('Spark plug'),
  engineOil('Engine oil'),
  chainSprockets('Chain & sprockets'),
  fuelTank('Fuel tank'),
  tirePressure('Tire pressure');

  const SpecItem(this.label);

  final String label;

  /// Fuel tank and tire pressure are figures, not parts, so they have no
  /// product photo.
  bool get hasPhoto => this != fuelTank && this != tirePressure;
}

/// Replacement specs for one motorcycle. A null value means the source table
/// did not list it.
class MotorcycleSpec {
  const MotorcycleSpec({
    required this.name,
    required this.imageAsset,
    this.frontTire,
    this.rearTire,
    this.battery,
    this.sparkPlug,
    this.engineOil,
    this.chainSprockets,
    this.fuelTank,
    this.tirePressure,
  });

  final String name;
  final String imageAsset;
  final String? frontTire;
  final String? rearTire;
  final String? battery;
  final String? sparkPlug;
  final String? engineOil;
  final String? chainSprockets;
  final String? fuelTank;

  /// In psi, e.g. "29 front / 33 rear".
  final String? tirePressure;

  String? valueOf(SpecItem item) => switch (item) {
    SpecItem.frontTire => frontTire,
    SpecItem.rearTire => rearTire,
    SpecItem.battery => battery,
    SpecItem.sparkPlug => sparkPlug,
    SpecItem.engineOil => engineOil,
    SpecItem.chainSprockets => chainSprockets,
    SpecItem.fuelTank => fuelTank,
    SpecItem.tirePressure => tirePressure,
  };
}

/// Folder holding one photo per distinct spec value, named by
/// [specImageAsset].
const specImageFolder = 'assets/specs/';

/// Bundled photo for [item]'s [value], e.g. a 80/90-14 tire or an NGK
/// CPR8EA-9 plug, or null for items without a photo. Front and rear tires of
/// the same size share a photo. Engine oil values are capacities, so they
/// share one oil photo; chain values share a CVT-belt or chain-kit photo.
String? specImageAsset(SpecItem item, String value) {
  if (!item.hasPhoto) return null;
  if (item == SpecItem.engineOil) return '${specImageFolder}engine_oil.jpg';
  if (item == SpecItem.chainSprockets) {
    return value.toLowerCase().startsWith('belt')
        ? '${specImageFolder}chain-cvt_belt.jpg'
        : '${specImageFolder}chain-chain_sprocket_kit.jpg';
  }
  final kind = switch (item) {
    SpecItem.battery => 'battery',
    SpecItem.sparkPlug => 'spark_plug',
    _ => 'tire',
  };
  // "100/70-14 (some sources: 110/70-14)" uses the first size's photo.
  final main = value.split(' (').first;
  return '$specImageFolder$kind-${imageSlug(main)}.jpg';
}

const _bikes = 'assets/motorcycles/';
const _cvt = 'Belt (CVT), no chain';

const motorcycleSpecs = [
  MotorcycleSpec(
    name: 'Honda Click 125i',
    imageAsset: '${_bikes}honda_click125_standard.png',
    frontTire: '80/90-14',
    rearTire: '90/90-14',
    battery: '12V 5Ah',
    sparkPlug: 'NGK CPR7EA-9',
    chainSprockets: _cvt,
    fuelTank: '5.5 L',
    tirePressure: '29 front / 33 rear',
  ),
  MotorcycleSpec(
    name: 'Honda Click 160',
    imageAsset: '${_bikes}honda_click160_standard.png',
    frontTire: '100/80-14',
    rearTire: '120/70-14',
    battery: '12V 5Ah',
    engineOil: '0.9 L',
    chainSprockets: _cvt,
    fuelTank: '5.5 L',
  ),
  MotorcycleSpec(
    name: 'Honda BeAT',
    imageAsset: '${_bikes}honda_beat_playful.png',
    frontTire: '80/90-14',
    rearTire: '90/90-14',
    chainSprockets: _cvt,
  ),
  MotorcycleSpec(
    name: 'Honda PCX160',
    imageAsset: '${_bikes}honda_pcx160_standard.png',
    frontTire: '110/70-14',
    rearTire: '130/70-13',
    battery: '12V 5Ah',
    engineOil: '1.0 L',
    chainSprockets: _cvt,
    fuelTank: '8.0 L',
  ),
  MotorcycleSpec(
    name: 'Honda ADV160',
    imageAsset: '${_bikes}honda_adv160_abs.png',
    frontTire: '110/80-14',
    rearTire: '130/70-13',
    chainSprockets: _cvt,
  ),
  MotorcycleSpec(
    name: 'Honda TMX125 Alpha',
    imageAsset: '${_bikes}honda_tmx125_alpha.png',
    frontTire: '2.50-18',
    rearTire: '2.75-18',
    chainSprockets: 'Rear sprocket 38T',
  ),
  MotorcycleSpec(
    name: 'Honda XRM125 Motard',
    imageAsset: '${_bikes}honda_xrm125_motard.png',
    frontTire: '70/90-17',
    rearTire: '80/90-17',
    engineOil: '0.9 L',
  ),
  MotorcycleSpec(
    name: 'Honda XRM125 DS / DSX',
    imageAsset: '${_bikes}honda_xrm125_dsx.png',
    frontTire: '2.50-17',
    rearTire: '2.50-17',
    battery: '12V 3Ah',
  ),
  MotorcycleSpec(
    name: 'Yamaha NMAX 155',
    imageAsset: '${_bikes}yamaha_nmax_standard.png',
    frontTire: '110/70-13',
    rearTire: '130/70-13',
    battery: 'YTZ6V / YTZ7V',
    sparkPlug: 'NGK CPR8EA-9',
    engineOil: '1.0 L',
    chainSprockets: _cvt,
    fuelTank: '7.1 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha Aerox 155',
    imageAsset: '${_bikes}yamaha_aerox_standard.png',
    frontTire: '110/80-14',
    rearTire: '140/70-14',
    battery: 'YTZ7V',
    sparkPlug: 'NGK CPR8EA-9',
    chainSprockets: _cvt,
    fuelTank: '5.5 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio i 125',
    imageAsset: '${_bikes}yamaha_mio_i125_standard.png',
    frontTire: '70/90-14',
    rearTire: '80/90-14',
    engineOil: '0.84 L',
    chainSprockets: _cvt,
  ),
  MotorcycleSpec(
    name: 'Yamaha Sniper 155',
    imageAsset: '${_bikes}yamaha_sniper155_standard.png',
    frontTire: '90/80-17',
    rearTire: '120/70-17',
    battery: 'GTZ5S',
    engineOil: '1.10 L',
    fuelTank: '5.4 L',
  ),
  MotorcycleSpec(
    name: 'Suzuki Raider R150 Fi',
    imageAsset: '${_bikes}suzuki_raider_r150_standard.png',
    frontTire: '70/90-17',
    rearTire: '80/90-17',
    battery: 'YTX7L-BS',
    sparkPlug: 'NGK MR8E-9',
    fuelTank: '4.0–4.9 L (sources differ)',
  ),
  MotorcycleSpec(
    name: 'Suzuki Smash 115',
    imageAsset: '${_bikes}suzuki_smash_fi_standard.png',
    frontTire: '70/90-17',
    rearTire: '80/90-17',
    engineOil: '0.8 L',
    fuelTank: '4.5 L',
  ),
  MotorcycleSpec(
    name: 'Honda XR150L',
    imageAsset: '${_bikes}honda_xr150l_standard.png',
    frontTire: '90/90-19',
    rearTire: '110/90-17',
    battery: '12V 5Ah',
    engineOil: '1.2 L',
    chainSprockets: '428 chain, 130 links, 17T front / 49T rear',
    fuelTank: '12.0 L',
  ),
  MotorcycleSpec(
    name: 'Honda CRF150L',
    imageAsset: '${_bikes}honda_crf150l_standard.png',
    frontTire: '70/100-21',
    rearTire: '90/100-18',
    battery: '12V 3.5Ah',
    fuelTank: '7.2 L',
  ),
  MotorcycleSpec(
    name: 'Honda TMX Supremo',
    imageAsset: '${_bikes}honda_tmx125_supremo.png',
    frontTire: '80/100-18',
    rearTire: '90/90-18',
    battery: '12V 6Ah',
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio Soul i 125',
    imageAsset: '${specImageFolder}bike-yamaha_mio_soul_i_125.jpg',
    frontTire: '80/80-14',
    rearTire: '100/70-14',
    engineOil: '0.84 L',
    chainSprockets: _cvt,
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio Gravis',
    imageAsset: '${_bikes}yamaha_mio_gravis_standard.png',
    frontTire: '100/90-12',
    rearTire: '110/90-12',
    chainSprockets: _cvt,
  ),
  MotorcycleSpec(
    name: 'Yamaha XMAX 300',
    imageAsset: '${_bikes}yamaha_xmax_standard.png',
    frontTire: '120/70-15',
    rearTire: '140/70-14',
    battery: 'GTZ8V',
    sparkPlug: 'NGK LMAR8A-9',
    engineOil: '1.3 L',
    chainSprockets: _cvt,
    fuelTank: '13 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha YZF-R15 (v3)',
    imageAsset: '${specImageFolder}bike-yamaha_yzf_r15_v3.jpg',
    frontTire: '80/90-17',
    rearTire: '100/80-17',
    sparkPlug: 'NGK CR8E',
    chainSprockets: '428 chain, 128 links, 14T front / 48T rear',
  ),
  MotorcycleSpec(
    name: 'Suzuki Burgman Street 125',
    imageAsset: '${_bikes}suzuki_burgman_street_standard.png',
    frontTire: '90/90-12',
    rearTire: '90/100-10',
    chainSprockets: _cvt,
    fuelTank: '5.6 L',
  ),
  MotorcycleSpec(
    name: 'Suzuki Burgman Street 125 EX',
    imageAsset: '${_bikes}suzuki_burgman_street_125_ex_standard.png',
    frontTire: '90/90-12',
    rearTire: '100/80-12',
    chainSprockets: _cvt,
    fuelTank: '5.5 L',
  ),
  MotorcycleSpec(
    name: 'Kawasaki Barako II 175',
    imageAsset: '${_bikes}kawasaki_barako_ii_standard.png',
    frontTire: '3.00-17',
    rearTire: '3.00-17',
    fuelTank: '12 L',
  ),
  MotorcycleSpec(
    name: 'Honda AirBlade 160',
    imageAsset: '${specImageFolder}bike-honda_airblade_160.jpg',
    frontTire: '90/80-14',
    rearTire: '100/80-14',
    battery: '12V 5Ah',
    engineOil: '0.9 L',
    chainSprockets: _cvt,
    fuelTank: '4.4 L (some list 5.5 L)',
  ),
  MotorcycleSpec(
    name: 'Honda Giorno+',
    imageAsset: '${_bikes}honda_giorno_plus_standard.png',
    frontTire: '100/90-12',
    rearTire: '100/90-12',
    battery: '12V 5Ah',
    chainSprockets: _cvt,
    fuelTank: '5.4 L',
  ),
  MotorcycleSpec(
    name: 'Honda Winner X',
    imageAsset: '${_bikes}honda_winner_x_standard.png',
    frontTire: '90/80-17',
    rearTire: '120/70-17',
    battery: '12V 5Ah',
    engineOil: '1.3 L',
    fuelTank: '4.5 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio Gear',
    imageAsset: '${_bikes}yamaha_mio_gear_standard.png',
    frontTire: '80/80-14',
    rearTire: '100/70-14 (some sources: 110/70-14)',
    engineOil: '0.8 L',
    chainSprockets: _cvt,
    fuelTank: '4.2 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio Fazzio',
    imageAsset: '${_bikes}yamaha_mio_fazzio_standard.png',
    frontTire: '110/70-12',
    rearTire: '110/70-12',
    battery: 'YTZ6V',
    engineOil: '0.84 L',
    chainSprockets: _cvt,
  ),
  MotorcycleSpec(
    name: 'Yamaha XTZ 125',
    imageAsset: '${specImageFolder}bike-yamaha_xtz_125.jpg',
    frontTire: '80/90-21',
    rearTire: '110/80-18',
    battery: 'MTX7L-BS',
    engineOil: '1.20 L',
    fuelTank: '11 L',
  ),
  MotorcycleSpec(
    name: 'Suzuki Raider J Crossover',
    imageAsset: '${specImageFolder}bike-suzuki_raider_j_crossover.jpg',
    frontTire: '70/90-17',
    rearTire: '80/90-17',
    fuelTank: '4.0 L',
  ),
  MotorcycleSpec(
    name: 'Kawasaki Dominar 400',
    imageAsset: '${specImageFolder}bike-kawasaki_dominar_400.jpg',
    frontTire: '110/70-17',
    rearTire: '150/60-17',
  ),
  MotorcycleSpec(
    name: 'Kymco Like 150i',
    imageAsset: '${specImageFolder}bike-kymco_like_150i.jpg',
    frontTire: '110/70-12',
    rearTire: '130/70-12',
    chainSprockets: _cvt,
    fuelTank: '7.0 L',
  ),
  MotorcycleSpec(
    name: 'Rusi Sigma 250',
    imageAsset: '${specImageFolder}bike-rusi_sigma_250.jpg',
    frontTire: '110/70-17',
    rearTire: '140/70-17',
  ),
  MotorcycleSpec(
    name: 'Rusi Titan 250 FI',
    imageAsset: '${specImageFolder}bike-rusi_titan_250_fi.jpg',
    frontTire: '100/80-17',
    rearTire: '130/70-17',
  ),
  MotorcycleSpec(
    name: 'Motorstar Xplorer Z150',
    imageAsset: '${specImageFolder}bike-motorstar_xplorer_z150.jpg',
    frontTire: '90/90-17',
    rearTire: '110/80-17',
    fuelTank: '14 L',
  ),
  MotorcycleSpec(
    name: 'TVS Dazz 110',
    imageAsset: '${specImageFolder}bike-tvs_dazz_110.jpg',
    frontTire: '80/90-14',
    rearTire: '90/80-14',
    chainSprockets: _cvt,
    fuelTank: '5.1 L',
  ),
];

String _norm(String value) =>
    value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

/// The Sizes row for a catalog motorcycle, matched by brand and model name
/// (e.g. Honda / Click125 → "Honda Click 125i"). Prefers a row that also
/// names the variant, such as "Honda XRM125 Motard".
MotorcycleSpec? specFor({
  required String brand,
  required String model,
  required String variant,
}) {
  final b = _norm(brand);
  final m = _norm(model);
  final v = _norm(variant);
  // One-letter variants such as "S" or "R" would match almost any name.
  final useVariant = v.length >= 3 && v != 'standard';
  final matches = motorcycleSpecs.where((spec) {
    final name = _norm(spec.name);
    if (!name.startsWith(b)) return false;
    return name.contains(m) || (useVariant && name.contains(v));
  }).toList();
  if (matches.isEmpty) return null;
  return matches.firstWhere(
    (spec) => useVariant && _norm(spec.name).contains(v),
    orElse: () => matches.first,
  );
}
