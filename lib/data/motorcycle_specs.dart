import 'image_slug.dart';

/// A maintenance item whose size or type differs by motorcycle.
enum SpecItem {
  frontTire('Front tire'),
  rearTire('Rear tire'),
  battery('Battery'),
  sparkPlug('Spark plug'),
  engineOil('Engine oil');

  const SpecItem(this.label);

  final String label;
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
  });

  final String name;
  final String imageAsset;
  final String? frontTire;
  final String? rearTire;
  final String? battery;
  final String? sparkPlug;
  final String? engineOil;

  String? valueOf(SpecItem item) => switch (item) {
    SpecItem.frontTire => frontTire,
    SpecItem.rearTire => rearTire,
    SpecItem.battery => battery,
    SpecItem.sparkPlug => sparkPlug,
    SpecItem.engineOil => engineOil,
  };
}

/// Folder holding one photo per distinct spec value, named by
/// [specImageAsset].
const specImageFolder = 'assets/specs/';

/// Bundled photo for [item]'s [value], e.g. a 80/90-14 tire or an NGK
/// CPR8EA-9 plug. Front and rear tires of the same size share a photo, and
/// engine oil values are capacities, so they share one oil photo.
String specImageAsset(SpecItem item, String value) {
  if (item == SpecItem.engineOil) return '${specImageFolder}engine_oil.jpg';
  final kind = switch (item) {
    SpecItem.frontTire || SpecItem.rearTire => 'tire',
    SpecItem.battery => 'battery',
    SpecItem.sparkPlug => 'spark_plug',
    SpecItem.engineOil => 'engine_oil',
  };
  return '$specImageFolder$kind-${imageSlug(value)}.jpg';
}

const _bikes = 'assets/motorcycles/';

const motorcycleSpecs = [
  MotorcycleSpec(
    name: 'Honda Click 125i',
    imageAsset: '${_bikes}honda_click125_standard.png',
    frontTire: '80/90-14',
    rearTire: '90/90-14',
    battery: '12V 5Ah',
    sparkPlug: 'NGK CPR7EA-9',
  ),
  MotorcycleSpec(
    name: 'Honda Click 160',
    imageAsset: '${_bikes}honda_click160_standard.png',
    frontTire: '100/80-14',
    rearTire: '120/70-14',
    battery: '12V 5Ah',
    engineOil: '0.9 L',
  ),
  MotorcycleSpec(
    name: 'Honda BeAT',
    imageAsset: '${_bikes}honda_beat_playful.png',
    frontTire: '80/90-14',
    rearTire: '90/90-14',
  ),
  MotorcycleSpec(
    name: 'Honda PCX160',
    imageAsset: '${_bikes}honda_pcx160_standard.png',
    frontTire: '110/70-14',
    rearTire: '130/70-13',
    battery: '12V 5Ah',
    engineOil: '1.0 L',
  ),
  MotorcycleSpec(
    name: 'Honda ADV160',
    imageAsset: '${_bikes}honda_adv160_abs.png',
    frontTire: '110/80-14',
    rearTire: '130/70-13',
  ),
  MotorcycleSpec(
    name: 'Honda TMX125 Alpha',
    imageAsset: '${_bikes}honda_tmx125_alpha.png',
    frontTire: '2.50-18',
    rearTire: '2.75-18',
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
  ),
  MotorcycleSpec(
    name: 'Yamaha Aerox 155',
    imageAsset: '${_bikes}yamaha_aerox_standard.png',
    frontTire: '110/80-14',
    rearTire: '140/70-14',
    battery: 'YTZ7V',
    sparkPlug: 'NGK CPR8EA-9',
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio i 125',
    imageAsset: '${_bikes}yamaha_mio_i125_standard.png',
    frontTire: '70/90-14',
    rearTire: '80/90-14',
    engineOil: '0.84 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha Sniper 155',
    imageAsset: '${_bikes}yamaha_sniper155_standard.png',
    frontTire: '90/80-17',
    rearTire: '120/70-17',
    battery: 'GTZ5S',
    engineOil: '1.10 L',
  ),
  MotorcycleSpec(
    name: 'Suzuki Raider R150 Fi',
    imageAsset: '${_bikes}suzuki_raider_r150_standard.png',
    frontTire: '70/90-17',
    rearTire: '80/90-17',
    battery: 'YTX7L-BS',
    sparkPlug: 'NGK MR8E-9',
  ),
  MotorcycleSpec(
    name: 'Suzuki Smash 115',
    imageAsset: '${_bikes}suzuki_smash_fi_standard.png',
    frontTire: '70/90-17',
    rearTire: '80/90-17',
    engineOil: '0.8 L',
  ),
  MotorcycleSpec(
    name: 'Honda XR150L',
    imageAsset: '${_bikes}honda_xr150l_standard.png',
    frontTire: '90/90-19',
    rearTire: '110/90-17',
    battery: '12V 5Ah',
    engineOil: '1.2 L',
  ),
  MotorcycleSpec(
    name: 'Honda CRF150L',
    imageAsset: '${_bikes}honda_crf150l_standard.png',
    frontTire: '70/100-21',
    rearTire: '90/100-18',
    battery: '12V 3.5Ah',
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
  ),
  MotorcycleSpec(
    name: 'Yamaha Mio Gravis',
    imageAsset: '${_bikes}yamaha_mio_gravis_standard.png',
    frontTire: '100/90-12',
    rearTire: '110/90-12',
  ),
  MotorcycleSpec(
    name: 'Yamaha XMAX 300',
    imageAsset: '${_bikes}yamaha_xmax_standard.png',
    frontTire: '120/70-15',
    rearTire: '140/70-14',
    battery: 'GTZ8V',
    sparkPlug: 'NGK LMAR8A-9',
    engineOil: '1.3 L',
  ),
  MotorcycleSpec(
    name: 'Yamaha YZF-R15 (v3)',
    imageAsset: '${specImageFolder}bike-yamaha_yzf_r15_v3.jpg',
    frontTire: '80/90-17',
    rearTire: '100/80-17',
    sparkPlug: 'NGK CR8E',
  ),
  MotorcycleSpec(
    name: 'Suzuki Burgman Street 125',
    imageAsset: '${_bikes}suzuki_burgman_street_standard.png',
    frontTire: '90/90-12',
    rearTire: '90/100-10',
  ),
  MotorcycleSpec(
    name: 'Suzuki Burgman Street 125 EX',
    imageAsset: '${_bikes}suzuki_burgman_street_125_ex_standard.png',
    frontTire: '90/90-12',
    rearTire: '100/80-12',
  ),
  MotorcycleSpec(
    name: 'Kawasaki Barako II 175',
    imageAsset: '${_bikes}kawasaki_barako_ii_standard.png',
    frontTire: '3.00-17',
    rearTire: '3.00-17',
  ),
];
