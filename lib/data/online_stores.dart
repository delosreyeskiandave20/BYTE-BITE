import 'marketplace.dart';

/// An item listed in an online marketplace store.
class OnlineStoreItem {
  const OnlineStoreItem(this.name, this.price);

  final String name;

  /// Price in pesos when the store page was checked; it may have changed.
  final double price;
}

/// A real Shopee or Lazada store and the motorcycle items it lists.
///
/// Items were copied by hand from each store's own page on the date in
/// [onlineStoresCheckedOn]. Buying always happens on the marketplace.
class OnlineStore {
  const OnlineStore({
    required this.name,
    required this.marketplace,
    required this.slug,
    required this.items,
  });

  final String name;

  /// [Marketplaces.shopee] or [Marketplaces.lazada].
  final String marketplace;

  /// The store's path on the marketplace, e.g. `sh0pnstyle`.
  final String slug;
  final List<OnlineStoreItem> items;

  Uri get storeUri => switch (marketplace) {
    Marketplaces.lazada => Uri.https('www.lazada.com.ph', '/shop/$slug/'),
    _ => Uri.https('shopee.ph', '/$slug'),
  };

  /// Opens this store's own search for [item], which lands on that listing.
  Uri itemUri(OnlineStoreItem item) => switch (marketplace) {
    Marketplaces.lazada => Uri.https('www.lazada.com.ph', '/$slug/', {
      'q': item.name,
      'from': 'wangpu',
      'langFlag': 'en',
    }),
    _ => Uri.https('shopee.ph', '/search', {
      'keyword': item.name,
      'shop': slug,
    }),
  };
}

const onlineStoresCheckedOn = 'Nov 15, 2026';

const onlineStores = [
  OnlineStore(
    name: 'Sh0pNStyle',
    marketplace: Marketplaces.lazada,
    slug: 'sh0pnstyle',
    items: [
      OnlineStoreItem('Honda Click brake shoe / brake pad 125 150 V2 V3', 170),
      OnlineStoreItem('NMAX brake pad front and rear V1 V2 V3', 170),
      OnlineStoreItem('PCX 160 CBS genuine Honda brake pad', 170),
      OnlineStoreItem(
        'ADV 150/160, PCX 160 ABS brake pad set front & rear',
        170,
      ),
      OnlineStoreItem('Honda Click 125i/150i V2 front brake pad', 170),
      OnlineStoreItem('Mio i125 / M3 air filter element (Yamaha genuine)', 245),
      OnlineStoreItem('Ball race kit Honda Click 125/150, BeAT', 245),
      OnlineStoreItem('Nmax V1 V2 ball race / knuckle bearing kit', 245),
      OnlineStoreItem('Front wheel bearing set BeAT/Click/ADV/PCX', 180),
      OnlineStoreItem('Fuel filter / O-ring fuel pump set Click125 V1V2', 200),
      OnlineStoreItem(
        'Genuine fuel filter with O-ring Click V3, ADV160, BeAT',
        245,
      ),
      OnlineStoreItem('Honda genuine drain plug oil screen filter', 125),
      OnlineStoreItem('Honda genuine coolant premix 500ml', 250),
      OnlineStoreItem('Coolant reserve tank cap Click 125/150/160', 120),
      OnlineStoreItem('Stock brake levers Honda Click 125/150/160', 250),
      OnlineStoreItem('Rubber link stopper Click 125i/150i, BeAT FI', 85),
      OnlineStoreItem('TPS sensor Honda BeAT FI / Vario', 280),
      OnlineStoreItem('XMAX 300 slider piece set (genuine)', 120),
      OnlineStoreItem('Yamaha carbon cleaner 75ml', 278),
      OnlineStoreItem('Tank protector deck pad Honda ADV 160', 650),
      OnlineStoreItem('Nemo Ducati V3 side mirror', 850),
    ],
  ),
  OnlineStore(
    name: 'JWLL NTG Market',
    marketplace: Marketplaces.lazada,
    slug: 'miko-smekaniko',
    items: [
      OnlineStoreItem('Honda Click brake shoe / brake pad set (genuine)', 175),
      OnlineStoreItem('ADV/PCX 150/160 front & rear brake pad set', 170),
      OnlineStoreItem('Aerox 155 front brake pad', 145),
      OnlineStoreItem('Yamaha genuine brake shoe Mio / Aerox 155', 145),
      OnlineStoreItem('Mio125i / Aerox rear brake shoe (Yamaha genuine)', 285),
      OnlineStoreItem('Click 125i V-belt + flyball set (Honda genuine)', 740),
      OnlineStoreItem('Click 125i V-belt + slider set', 620),
      OnlineStoreItem('BeAT FI V3 / Genio V-belt (Honda genuine)', 620),
      OnlineStoreItem('Clutch lining shoe set PCX/ADV/Click 160', 760),
      OnlineStoreItem('Pulley drive face Click / PCX / ADV', 350),
      OnlineStoreItem('Front wheel bearing set (Honda genuine)', 165),
      OnlineStoreItem('Ball race steering kit Mio125i / Sniper', 350),
      OnlineStoreItem('Front brake disk plate Click 125i/150i', 580),
      OnlineStoreItem('Brake cable Aerox 155 / NMAX (Yamaha genuine)', 350),
      OnlineStoreItem('Water pump assy Click 125i / PCX / ADV', 1100),
      OnlineStoreItem('Thermostat assy Click / ADV / PCX', 865),
      OnlineStoreItem('Fuel feed hose Click / ADV / PCX / BeAT', 365),
      OnlineStoreItem('Spark plug cap Click / PCX (Honda genuine)', 195),
      OnlineStoreItem('Rectifier Mio125i / Soul GT (Yamaha genuine)', 530),
      OnlineStoreItem('Side stand switch Click / BeAT FI', 344),
      OnlineStoreItem('Honda engine oil 1L with gear oil 100ml', 485),
      OnlineStoreItem('Honda engine oil 800ml with gear oil 120ml', 350),
      OnlineStoreItem('Honda carbon cleaner 30ml', 250),
    ],
  ),
  OnlineStore(
    name: 'Bike World 2020',
    marketplace: Marketplaces.lazada,
    slug: 'bike-world-2020',
    items: [
      OnlineStoreItem('Tubeless tire 80/90-14 / 90/80-14 / 90/90-14', 543),
      OnlineStoreItem('Tubeless tire 80/90-17 / 70/80-17 / 70/80-14', 543),
      OnlineStoreItem('Tubeless tire 70/90-14', 542),
      OnlineStoreItem('Tubeless tire 80/80-14', 613),
      OnlineStoreItem('Tubeless tire 90/90-14', 715),
      OnlineStoreItem('Tubeless tire 90/90-12', 826),
      OnlineStoreItem('Tubeless tire 60/80-17', 569),
      OnlineStoreItem('Brake drum cover 130mm/160mm', 432),
    ],
  ),
];
