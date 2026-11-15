/// What each Maintenance and Accessories choice is, keyed by group title then
/// choice name. Keyed by group because some names mean different products in
/// different groups (an oil "Paper filter" is not an air "Paper filter").
String? choiceDescription(String group, String choice) =>
    _descriptions[group]?[choice];

const _descriptions = <String, Map<String, String>>{
  // ============================================================ MAINTENANCE
  'Engine Oil': {
    'Mineral oil':
        'Conventional refined oil for everyday commuting. The most '
        'affordable choice; change it more often than synthetic.',
    'Semi-synthetic oil':
        'Blend of mineral and synthetic base oils. Better heat protection '
        'than mineral oil at a moderate price.',
    'Fully synthetic oil':
        'Synthetic oil that resists heat and breakdown best. Suited to hard '
        'riding and longer change intervals.',
    '10W-30':
        'Thin multigrade oil that flows fast at start-up. Common for small '
        'scooters; use only if the manual lists 10W-30.',
    '10W-40':
        'The most common grade for Philippine motorcycles and scooters. '
        'Balances easy starting with protection in the heat.',
    '10W-50':
        'Thicker hot viscosity for high-revving or hard-working engines in '
        'hot weather.',
    '15W-40':
        'Slightly thicker at start-up than 10W-40. Used in older or '
        'air-cooled engines in warm climates.',
    '15W-50': 'Heavy multigrade for big, hot-running or high-mileage engines.',
    '20W-40':
        'Thick oil often specified for air-cooled underbones and older '
        'carbureted engines.',
    '20W-50':
        'Very thick grade for old or worn engines and big air-cooled bikes '
        'in hot weather.',
    'JASO MA':
        'Wet-clutch rating for manual motorcycles. Contains no friction '
        'modifiers, so the clutch does not slip.',
    'JASO MA2':
        'Stricter wet-clutch rating than MA. The best match for modern '
        'manual motorcycles with wet clutches.',
    'JASO MB':
        'Rating for scooters with a dry CVT clutch. Has friction modifiers, '
        'so do not use it in a manual bike with a wet clutch.',
  },
  'Oil Filter or Oil Strainer': {
    'Paper filter':
        'Pleated paper oil-filter cartridge that catches fine particles. '
        'Replace it at the interval in the manual.',
    'Spin-on filter':
        'Canister oil filter that screws onto the engine, used on bigger '
        'bikes. Replace it with every oil change.',
    'Reusable metal filter':
        'Stainless-mesh oil filter you can wash and refit instead of '
        'throwing away.',
    'Screen-type strainer':
        'Wire-mesh strainer in the drain plug or crankcase of small '
        'engines. Clean it at each oil change.',
    'Centrifugal filter':
        'Spinning rotor filter on some small Honda engines that throws '
        'sludge out of the oil. Clean it at service time.',
    'OEM filter':
        'Original oil filter from the motorcycle maker, an exact fit for '
        'the engine.',
    'Aftermarket filter':
        'Oil filter from another brand made to fit your model, usually '
        'cheaper than the original.',
  },
  'Gear Oil or Final-Drive Oil': {
    '75W-90':
        'Lighter gear oil for scooter final-drive cases where the maker '
        'specifies it.',
    '80W-90': 'The most common scooter final-drive and gear oil grade.',
    '85W-140':
        'Heavy gear oil for high-load final drives and older shaft-drive '
        'bikes.',
    'Mineral gear oil': 'Conventional gear oil for standard scooter gearboxes.',
    'Synthetic gear oil':
        'Synthetic gear oil that resists heat and keeps gears quieter for '
        'longer.',
    'Hypoid gear oil':
        'Extreme-pressure (GL-5) gear oil for hypoid gears in shaft drives.',
  },
  'Air Filter': {
    'Paper filter':
        'Pleated paper air filter used as standard on most bikes. Replace it '
        'when dirty; do not wash it.',
    'Foam filter':
        'Oiled foam air filter common on off-road bikes. Wash, re-oil and '
        'reuse it.',
    'Cotton-gauze filter':
        'Oiled cotton-gauze filter that flows more air and can be cleaned '
        'and re-oiled.',
    'Washable filter':
        'Air filter you can rinse and reuse instead of replacing.',
    'OEM filter':
        'Original air filter from the motorcycle maker, an exact fit for '
        'the airbox.',
    'Aftermarket filter':
        'Air filter from another brand made to fit your model.',
    'Performance filter':
        'High-flow filter for better throttle response; often paired with '
        'an exhaust upgrade.',
    'CVT air filter':
        'Small filter that keeps dust out of the scooter CVT case so the '
        'belt and rollers last longer.',
  },
  'Spark Plug': {
    'Nickel spark plug':
        'Standard nickel-alloy plug. Cheap and reliable; replace it more '
        'often than iridium.',
    'Copper-core spark plug':
        'Plug with a copper core for good heat transfer. Common original '
        'fit on small engines.',
    'Platinum spark plug':
        'Platinum-tipped plug that lasts longer than nickel.',
    'Iridium spark plug':
        'Fine-tip iridium plug for a stronger spark and the longest life.',
    'Standard spark plug':
        'Plug that matches the original specification for your engine.',
    'Resistor spark plug':
        'Plug with a built-in resistor that stops interference with the '
        'ECU and electronics.',
    'Long-reach spark plug':
        'Plug with a longer thread for cylinder heads that need it. Check '
        'the reach before buying.',
    'Short-reach spark plug':
        'Plug with a shorter thread for heads that need it. Check the reach '
        'before buying.',
  },
  'Coolant': {
    'Premixed coolant':
        'Ready-to-pour coolant already mixed with water. Top up or refill '
        'without mixing.',
    'Concentrated coolant':
        'Undiluted coolant that you mix with distilled water before use.',
    'Ethylene-glycol coolant':
        'Common coolant type that raises the boiling point and stops '
        'corrosion.',
    'Long-life coolant': 'Coolant made to last longer between changes.',
    'Aluminum-safe coolant':
        'Coolant that protects aluminum engines and radiators from '
        'corrosion.',
    'Silicate-free coolant':
        'Coolant without silicates, as most motorcycle makers recommend, to '
        'protect water-pump seals.',
    'Racing coolant':
        'Glycol-free coolant allowed on race tracks because it is not '
        'slippery if spilled.',
  },
  'Brake Fluid': {
    'DOT 3':
        'Glycol brake fluid for older or basic hydraulic brakes. Use only '
        'if the reservoir cap says DOT 3.',
    'DOT 4':
        'The most common motorcycle brake fluid, with a higher boiling '
        'point than DOT 3.',
    'DOT 5.1':
        'High-boiling glycol fluid compatible with DOT 4 systems, often '
        'used with ABS.',
    'Mineral hydraulic fluid':
        'Mineral-based hydraulic fluid for systems that specify it. Never '
        'mix it with DOT fluid.',
  },
  'Brake Pads and Brake Shoes': {
    'Organic brake pads':
        'Soft, quiet pads that are gentle on discs. Good for light '
        'scooters and commuting.',
    'Semi-metallic brake pads':
        'Pads with metal fibres for stronger, more fade-resistant braking.',
    'Sintered brake pads':
        'Hard-wearing metal pads with strong braking, even in the wet.',
    'Ceramic brake pads': 'Quiet, low-dust pads with consistent braking.',
    'OEM brake pads':
        'Original pads from the motorcycle maker, an exact fit for the '
        'caliper.',
    'Aftermarket brake pads':
        'Pads from another brand made to fit your caliper.',
    'Front brake pads':
        'Pads for the front disc brake. The front does most of the '
        'stopping.',
    'Rear brake pads': 'Pads for the rear disc brake.',
    'Front brake shoes': 'Shoes for a front drum brake.',
    'Rear brake shoes':
        'Shoes for a rear drum brake, used on most scooters and underbones.',
  },
  'Drive Chain': {
    'Standard roller chain':
        'Basic chain without seals for small commuter bikes. Needs '
        'frequent cleaning and lube.',
    'O-ring chain':
        'Chain with rubber O-rings that seal grease inside the rollers for '
        'longer life.',
    'X-ring chain':
        'Sealed chain with X-shaped rings for less friction and longer life '
        'than O-ring.',
    'Z-ring chain':
        'Sealed chain with Z-shaped rings for low friction and long life.',
    'Sealed chain': 'Any chain with seals that keep grease in and dirt out.',
    'Heavy-duty chain':
        'Thicker plates for heavy loads, tricycles and hard use.',
    'Racing chain':
        'Light, high-strength chain for track and performance bikes.',
    'OEM chain': 'Original chain specified by the motorcycle maker.',
    'Aftermarket chain':
        'Chain from another brand made to your size and length.',
    '420 chain':
        'Narrow pitch chain used on small underbones and 100–110cc bikes.',
    '428 chain': 'Common size for 125–150cc underbones and sport bikes.',
    '520 chain': 'Size used on many 250–650cc and off-road bikes.',
    '525 chain': 'Wider chain for mid and large motorcycles.',
    '530 chain': 'Heavy-duty size for big, powerful motorcycles.',
  },
  'Sprockets': {
    'Front sprocket':
        'Small sprocket on the engine output shaft. Fewer teeth means '
        'quicker acceleration.',
    'Rear sprocket':
        'Large sprocket on the rear wheel. More teeth means quicker '
        'acceleration and lower top speed.',
    'Steel sprocket': 'Durable steel sprocket that lasts longest.',
    'Aluminum sprocket':
        'Light aluminum sprocket for performance; wears faster than steel.',
    'Standard gearing':
        'Original tooth count for the balance the maker intended.',
    'Acceleration gearing':
        'Shorter gearing for faster pick-up, at higher revs on the highway.',
    'High-speed gearing':
        'Taller gearing for lower revs at speed and higher top speed.',
  },
  'Chain Lubricant': {
    'Wet chain lubricant':
        'Oily lube that stays on in the rain. Attracts more dirt.',
    'Dry chain lubricant':
        'Lube that dries to a film so less dust sticks. Reapply more often.',
    'Chain wax': 'Wax-based lube that stays clean and does not fling off.',
    'Road-use chain lubricant': 'Everyday lube for street riding.',
    'Off-road chain lubricant': 'Lube that resists mud, sand and water.',
    'Racing chain lubricant':
        'High-speed lube that stays on the chain at track speeds.',
    'O-ring-safe chain lubricant':
        'Lube that will not harm the rubber seals on sealed chains.',
  },
  'Scooter CVT Parts': {
    'Standard CVT belt': 'Original-spec drive belt for normal riding.',
    'Reinforced CVT belt':
        'Stronger belt that resists stretching under heavy loads.',
    'Performance CVT belt': 'Belt made for modified or hard-ridden scooters.',
    'Standard rollers': 'Original-weight variator rollers for the stock feel.',
    'Lightweight rollers':
        'Lighter rollers for faster take-off at higher revs.',
    'Heavyweight rollers':
        'Heavier rollers for calmer cruising and better top speed.',
    'Sliding rollers':
        'Flat-sided rollers that slide instead of roll for smoother shifts '
        'and longer life.',
    'Variator sliders':
        'Plastic guides on the variator ramp plate that stop rattles.',
    'Clutch shoes':
        'Rear centrifugal clutch shoes. Worn shoes cause judder at '
        'take-off.',
    'Standard clutch bell':
        'Original clutch housing that the clutch shoes grip.',
    'Performance clutch bell':
        'Lighter or ventilated clutch housing for modified scooters.',
    'Standard clutch springs':
        'Original springs that set when the clutch engages.',
    'Performance clutch springs':
        'Stiffer springs so the clutch engages at higher revs for faster '
        'take-off.',
    'Standard contra spring': 'Original torque spring on the rear pulley.',
    'Performance contra spring':
        'Stiffer torque spring for quicker response and pulling power.',
    'CVT air filter':
        'Filter on the CVT cover vent that keeps dust off the belt.',
  },
  'Tires': {
    'Tube-type tire': 'Tire that needs an inner tube; used on spoke wheels.',
    'Tubeless tire':
        'Tire that seals on the rim without a tube; easier to plug when '
        'punctured.',
    'Bias-ply tire':
        'Traditional construction common on small bikes and scooters.',
    'Radial tire':
        'Construction used on bigger bikes for grip and stability at speed.',
    'Commuter tire': 'Long-wearing tire for daily city riding.',
    'Touring tire': 'Tire for long rides, built to last many kilometres.',
    'Sport tire': 'Softer, grippier tire for sport riding; wears faster.',
    'Sport-touring tire': 'Balances sport grip with long life.',
    'Rain tire': 'Deep-grooved tire that clears water for better wet grip.',
    'Dual-purpose tire': 'For both road and light dirt riding.',
    'Adventure tire': 'Tread for long trips on mixed roads and gravel.',
    'Off-road tire': 'Knobby tread for dirt and trails; not for highway use.',
    'Motocross tire': 'Aggressive knobby tire for motocross tracks only.',
    'Scooter tire': 'Small-diameter tire sized for scooter wheels.',
  },
  'Battery': {
    'Conventional wet-cell battery':
        'Lead-acid battery with liquid acid. Cheapest, but needs topping '
        'up with distilled water.',
    'Maintenance-free battery':
        'Sealed lead-acid battery that never needs topping up.',
    'AGM battery': 'Sealed absorbed-glass-mat battery that resists vibration.',
    'Gel battery':
        'Sealed battery with gel electrolyte, good in heat and vibration.',
    'Lithium-ion battery':
        'Very light battery with strong starting power; needs a '
        'lithium-safe charger.',
    'Lithium-iron-phosphate battery':
        'Light, long-life LiFePO4 battery and the safest lithium type.',
    'OEM battery': 'Original battery size and type for the model.',
    'Aftermarket battery':
        'Battery from another brand that matches the original size and '
        'terminals.',
  },
  'Fork and Suspension Items': {
    'Fork oil':
        'Damping oil for the front forks. Match the grade (e.g. 10W) and '
        'fill level.',
    'Fork seals': 'Oil seals that stop fork oil leaking down the tubes.',
    'Fork dust seals':
        'Outer wiper seals that keep grit off the fork oil seals.',
    'Fork bushings':
        'Slide bushings inside the forks; replace when the front clunks.',
    'Fork springs': 'Coil springs inside the forks that hold the front up.',
    'Standard rear shock': 'Original-spec rear shock absorber.',
    'Adjustable rear shock':
        'Rear shock with preload or damping adjustment for load and riding '
        'style.',
    'Shock bushings': 'Bushings at the shock mounts that stop knocking.',
    'Swingarm bearings': 'Pivot bearings that let the swingarm move smoothly.',
    'Steering-head bearings':
        'Bearings in the steering head; replace when steering feels notchy.',
    'Tapered roller bearings':
        'Upgraded steering bearings that last longer than ball bearings.',
    'Ball bearings':
        'Standard steering or wheel bearings used on most small bikes.',
  },
  'Fuel-System Cleaners': {
    'Fuel-injector cleaner':
        'Fuel additive that cleans deposits from injectors for smoother '
        'idle.',
    'Carburetor cleaner':
        'Spray that dissolves varnish in carburetor jets and passages.',
    'Throttle-body cleaner':
        'Spray for carbon build-up in the throttle body of fuel-injected '
        'bikes.',
    'Fuel-system cleaner':
        'Additive that cleans the whole fuel system as you ride.',
    'Fuel stabilizer': 'Keeps fuel fresh when the bike is stored for weeks.',
    'Octane booster': 'Additive that raises fuel octane to reduce knocking.',
  },
  'Electrical Maintenance Items': {
    'Main fuse': 'Main blade fuse that protects the whole wiring harness.',
    'Spare blade fuses': 'Assorted blade fuses to carry for roadside repairs.',
    'Starter relay': 'Solenoid that sends power to the starter motor.',
    'Regulator/rectifier':
        'Controls charging voltage so the battery is not over- or '
        'under-charged.',
    'Headlight bulb':
        'Replacement halogen headlight bulb. Match the base type (e.g. H4, '
        'HS1).',
    'LED headlight':
        'LED headlight bulb or unit that is brighter and uses less power.',
    'Tail-light bulb': 'Replacement tail and brake light bulb.',
    'LED tail light':
        'LED tail and brake light that lights up faster and lasts longer.',
    'Turn-signal bulb': 'Replacement turn-signal bulb.',
    'LED turn signal':
        'LED turn signal; may need a load resistor or LED flasher relay.',
    'Brake-light switch':
        'Switch that turns on the brake light when you brake.',
    'Horn': 'Replacement 12 V horn.',
    'Wiring connector': 'Connectors for repairing or adding to the wiring.',
    'Electrical tape': 'Insulating tape for wire repairs.',
    'Heat-shrink tubing':
        'Sleeve that shrinks with heat to seal and protect wire joints.',
    'Cable ties': 'Plastic ties for routing and securing wires.',
    'Contact cleaner':
        'Quick-drying spray that cleans dirt and corrosion from electrical '
        'connectors.',
  },
  'Grease and Protective Chemicals': {
    'Multipurpose grease': 'General grease for pivots, cables and bearings.',
    'Waterproof grease':
        'Grease that stays put when washed or ridden in the rain.',
    'Lithium grease': 'Common lithium-based grease for bearings and pivots.',
    'High-temperature grease':
        'Grease for hot parts such as wheel bearings near brakes.',
    'Silicone grease':
        'Grease safe on rubber and plastic, used on seals and connectors.',
    'Anti-seize compound':
        'Paste that stops bolts and spark plugs from seizing.',
    'Thread-locking compound':
        'Liquid that stops bolts from loosening from vibration.',
    'Penetrating oil': 'Thin oil that frees rusted or stuck bolts.',
    'Contact cleaner':
        'Spray that cleans electrical contacts and leaves no residue.',
    'Brake cleaner':
        'Spray that removes oil and brake dust from discs and calipers.',
    'Silicone spray':
        'Dry lubricant and protectant for rubber and plastic parts.',
    'Rust inhibitor': 'Spray coating that protects bare metal from rust.',
  },
  'Cleaning Products': {
    'Motorcycle shampoo':
        'pH-balanced wash that is safe on paint, plastics and decals.',
    'Degreaser':
        'Cleaner that cuts grease and grime from the engine and wheels.',
    'Chain cleaner': 'Spray that removes old lube and dirt from the chain.',
    'Brake cleaner': 'Fast-evaporating cleaner for brake discs and calipers.',
    'Engine cleaner': 'Cleaner for oily dirt on engine cases.',
    'Carburetor cleaner': 'Solvent spray for carburetor jets and passages.',
    'Throttle-body cleaner': 'Spray for carbon build-up in throttle bodies.',
    'Metal polish': 'Polish that brings back shine on aluminum and steel.',
    'Chrome polish': 'Polish that removes spots and haze from chrome.',
    'Plastic polish':
        'Restores clarity to scratched plastic and headlight lenses.',
    'Rubber protectant':
        'Keeps rubber trim and seals from drying and cracking.',
    'Rust remover': 'Removes surface rust from metal parts.',
    'Wax': 'Protective wax for paint gloss and water beading.',
    'Ceramic spray':
        'Spray-on ceramic coating for long-lasting shine and protection.',
    'Microfiber cloth':
        'Soft cloth for drying and polishing without scratches.',
    'Chain brush':
        'Three-sided brush that scrubs all sides of the chain at once.',
  },
  'Electric Motorcycle Maintenance Items': {
    'Traction battery': 'Main high-voltage battery pack that powers the motor.',
    'Removable battery': 'Battery pack you can take out to charge indoors.',
    'Fixed battery':
        'Built-in battery charged through the bike\'s charging port.',
    '12-volt battery': 'Small auxiliary battery for lights and electronics.',
    'Battery charger': 'Charger matched to the battery voltage and connector.',
    'Charging cable': 'Replacement charging cable for the charging port.',
    'Charging-port cover':
        'Cover that keeps water and dust out of the charging port.',
    'Charging-port seal': 'Rubber seal that waterproofs the charging port.',
    'Charging-port fuse': 'Fuse that protects the charging circuit.',
    'Motor coolant': 'Coolant for liquid-cooled electric motors.',
    'Battery coolant': 'Coolant for liquid-cooled battery packs.',
    'Brake pads': 'Brake pads for the electric motorcycle\'s disc brakes.',
    'Tires': 'Replacement tires matched to the electric motorcycle\'s wheels.',
    'Wheel bearings': 'Hub bearings, including on hub-motor wheels.',
    'Suspension parts': 'Fork and shock parts for the electric motorcycle.',
    'Fuses': 'Spare fuses for the electrical system.',
    'Relays': 'Relays that switch the motor controller and accessories.',
  },
  // ============================================================ ACCESSORIES
  'Helmet': {
    'Full-face helmet':
        'Covers the whole head and chin for the most protection.',
    'Modular helmet':
        'Full-face helmet whose chin bar flips up, handy at stops.',
    'Open-face helmet':
        'Covers the top, back and sides; leaves the face open for '
        'ventilation.',
    'Half helmet': 'Covers only the top of the head. Least protection.',
    'Motocross helmet':
        'Off-road helmet with a peak and chin guard, worn with goggles.',
    'Adventure helmet':
        'Full-face helmet with a peak and visor for road and trail.',
    'Dual-sport helmet': 'Helmet for both street and off-road riding.',
    'Bluetooth-ready helmet':
        'Helmet with speaker pockets to fit a Bluetooth intercom.',
    'DOT-certified helmet': 'Meets the US DOT FMVSS 218 safety standard.',
    'ECE-certified helmet': 'Meets the European ECE 22.06 safety standard.',
  },
  'Helmet Accessories': {
    'Clear visor': 'Clear shield for day and night riding.',
    'Smoke visor': 'Tinted shield that cuts sun glare. Not for night riding.',
    'Iridium visor': 'Mirrored shield that reduces bright sun glare.',
    'Anti-fog visor':
        'Shield with an anti-fog coating for rainy or humid rides.',
    'Pinlock insert': 'Clip-in inner lens that stops the visor from fogging.',
    'Helmet intercom':
        'Bluetooth unit for calls, music and rider-to-rider talk.',
    'Bluetooth speaker': 'Thin speakers that fit inside the helmet.',
    'Helmet microphone': 'Boom or wired mic for calls and intercom.',
    'Helmet sun visor': 'Drop-down inner sun visor.',
    'Helmet liner': 'Replacement washable comfort liner.',
    'Helmet cheek pads': 'Replacement pads that adjust fit and comfort.',
    'Helmet bag': 'Padded bag that protects the helmet when stored.',
    'Helmet lock': 'Lock that secures your helmet to the motorcycle.',
  },
  'Riding Jacket': {
    'Mesh jacket': 'Airy mesh jacket for hot weather, with room for armor.',
    'Textile jacket': 'Abrasion-resistant fabric jacket for all-round riding.',
    'Leather jacket': 'Leather jacket with the best abrasion resistance.',
    'Waterproof jacket': 'Jacket with a waterproof membrane or liner for rain.',
    'Summer jacket': 'Light, vented jacket for hot days.',
    'Winter jacket': 'Insulated jacket for cold mornings and highland rides.',
    'Adventure jacket':
        'Long, vented jacket with pockets and armor for touring.',
    'Racing jacket': 'Fitted leather jacket for track use, often with a hump.',
    'Reflective jacket': 'Jacket with reflective panels for night visibility.',
    'Armored jacket': 'Jacket with CE-rated shoulder and elbow armor.',
  },
  'Riding Pants': {
    'Motorcycle jeans':
        'Jeans lined with abrasion-resistant fibre and knee armor pockets.',
    'Textile riding pants': 'Fabric pants with armor for everyday riding.',
    'Leather riding pants': 'Leather pants for the best abrasion protection.',
    'Waterproof riding pants': 'Pants with a waterproof membrane.',
    'Adventure pants': 'Vented pants for long trips and trails.',
    'Racing pants': 'Leather pants for track riding.',
    'Armored pants': 'Pants with hip and knee armor.',
    'Thermal riding pants': 'Insulated pants for cold rides.',
  },
  'Riding Gloves': {
    'Short-cuff gloves': 'Short gloves for city riding.',
    'Long-cuff gloves':
        'Gloves that cover the wrist and overlap the jacket sleeve.',
    'Mesh gloves': 'Breathable gloves for hot weather.',
    'Leather gloves': 'Durable gloves with good grip and abrasion resistance.',
    'Waterproof gloves': 'Gloves with a waterproof liner.',
    'Winter gloves': 'Insulated gloves for cold weather.',
    'Racing gloves':
        'Gauntlet gloves with knuckle and palm sliders for track use.',
    'Adventure gloves': 'Tough gloves for touring and off-road.',
    'Touchscreen gloves': 'Fingertips that work on phone screens.',
    'Armored gloves': 'Gloves with hard knuckle protection.',
  },
  'Motorcycle Boots': {
    'Short riding boots': 'Ankle-height riding boots for daily use.',
    'Touring boots': 'Comfortable, often waterproof boots for long rides.',
    'Racing boots': 'Tall boots with sliders and ankle bracing for track use.',
    'Adventure boots': 'Tough boots for touring and trails.',
    'Motocross boots': 'Rigid off-road boots with maximum protection.',
    'Waterproof boots': 'Boots with a waterproof lining.',
    'Leather boots': 'Leather boots for durability and support.',
    'Steel-toe riding boots': 'Boots with steel toe caps.',
    'Casual motorcycle shoes':
        'Sneaker-style riding shoes with ankle protection.',
  },
  'Rain Gear': {
    'Rain jacket': 'Waterproof jacket that goes over your riding gear.',
    'Rain pants': 'Waterproof over-pants.',
    'One-piece rain suit': 'Full rain suit that keeps water out at the waist.',
    'Boot covers': 'Waterproof covers that slip over shoes or boots.',
    'Glove covers': 'Waterproof covers that go over gloves.',
    'Helmet rain cover': 'Cover that keeps rain off a stored helmet.',
    'Waterproof backpack cover': 'Rain cover for your backpack.',
  },
  'Motorcycle Cover': {
    'Indoor cover': 'Soft cover that keeps dust off in a garage.',
    'Outdoor cover': 'Weatherproof cover for parking outside.',
    'Waterproof cover': 'Cover that keeps rain off the motorcycle.',
    'UV-resistant cover': 'Cover that protects paint and seat from sun damage.',
    'Dustproof cover': 'Cover that keeps dust and dirt off.',
    'Heat-resistant cover':
        'Cover you can put on right after riding without melting on the '
        'exhaust.',
    'Half cover': 'Covers the seat and tank only.',
    'Full cover': 'Covers the whole motorcycle.',
    'Lockable cover': 'Cover with lock holes to secure it to the bike.',
  },
  'Top Box': {
    'Plastic top box': 'Light, affordable rear box.',
    'Aluminum top box': 'Tough aluminum box for touring.',
    'Small top box': 'Fits a half-face helmet or daily items.',
    'Medium top box': 'Fits one full-face helmet.',
    'Large top box': 'Fits two helmets or groceries.',
    'Hard top box': 'Rigid, lockable box that protects contents.',
    'Detachable top box': 'Quick-release box you can carry off the bike.',
    'Top box with backrest': 'Box with a pad for passenger comfort.',
    'Top box with brake light':
        'Box with a built-in brake light for visibility.',
  },
  'Side Case and Saddlebag': {
    'Hard side case': 'Rigid, lockable side box.',
    'Aluminum pannier': 'Tough aluminum side case for touring.',
    'Soft saddlebag': 'Fabric bag that hangs over the seat or rack.',
    'Waterproof saddlebag': 'Saddlebag that keeps contents dry.',
    'Leather saddlebag': 'Classic leather bag for cruisers.',
    'Side box': 'Small side box for tools or documents.',
    'Detachable side case': 'Quick-release side case.',
    'Expandable saddlebag': 'Saddlebag that zips open for more space.',
    'Universal saddlebag': 'Saddlebag that fits most motorcycles.',
  },
  'Tank and Tail Bag': {
    'Magnetic tank bag': 'Bag that holds to a steel tank with magnets.',
    'Strap-on tank bag':
        'Bag that straps around the tank; fits plastic tanks too.',
    'Waterproof tank bag': 'Tank bag that keeps contents dry.',
    'Expandable tank bag': 'Tank bag that zips open for more space.',
    'Tail bag': 'Bag that straps to the passenger seat or rack.',
    'Seat bag': 'Small bag that straps to the seat.',
    'Tail-mounted hard case': 'Rigid case mounted on the tail.',
    'Tail-mounted soft bag': 'Soft bag mounted on the tail.',
  },
  'Motorcycle Backpack': {
    'Standard backpack': 'Everyday backpack for riding.',
    'Waterproof backpack':
        'Roll-top or sealed backpack that keeps contents dry.',
    'Riding backpack':
        'Backpack with chest and waist straps so it stays put while riding.',
    'Hard-shell backpack':
        'Backpack with a rigid shell that protects contents.',
    'Hydration backpack': 'Backpack with a water bladder and drinking tube.',
    'Laptop backpack': 'Backpack with a padded laptop sleeve.',
    'Reflective backpack': 'Backpack with reflective panels for visibility.',
    'Expandable backpack': 'Backpack that zips open for more space.',
  },
  'Phone Holder': {
    'Handlebar phone holder':
        'Clamps to the handlebar to hold your phone for navigation.',
    'Mirror-mounted phone holder': 'Mounts on the mirror stem.',
    'Stem-mounted phone holder':
        'Mounts in the steering stem hole for a centred position.',
    'Clamp-type holder': 'Spring clamp that grips the phone sides.',
    'Silicone phone holder': 'Stretchy silicone holder for quick mounting.',
    'Locking phone holder': 'Holder that locks the phone in place.',
    'Waterproof phone holder': 'Holder with a waterproof case.',
    'Wireless-charging phone holder':
        'Holder that charges your phone wirelessly while riding.',
  },
  'Navigation and Communication': {
    'Motorcycle GPS': 'Dedicated, weatherproof GPS navigator.',
    'Smartphone navigation mount': 'Mount for using your phone as a navigator.',
    'Bluetooth intercom': 'Helmet unit for calls, music and group talk.',
    'Rider-to-rider intercom': 'Talk with other riders over Bluetooth or mesh.',
    'Rider-to-passenger intercom': 'Talk with your passenger while riding.',
    'Helmet Bluetooth system':
        'Bluetooth kit with speakers and mic for the helmet.',
    'Communication headset': 'Headset with speakers and mic for calls.',
    'GPS tracker':
        'Hidden tracker that shows your motorcycle\'s location if stolen.',
  },
  'USB and Charging Accessories': {
    'USB-A charger': 'Charging port with a standard USB-A socket.',
    'USB-C charger': 'Charging port with a USB-C socket for newer phones.',
    'Fast charger': 'Charger with quick-charge support.',
    'Wireless charger': 'Charges your phone without a cable.',
    'Handlebar charging port': 'USB port that clamps to the handlebar.',
    'Waterproof charging port': 'USB port with a rain cap.',
    'Dual USB charger': 'Charges two devices at once.',
    'Battery-direct charger':
        'Charger wired straight to the battery with an in-line fuse.',
    'Accessory power socket': '12 V socket for powering accessories.',
  },
  'Security Accessories': {
    'Disc-lock alarm': 'Brake disc lock with a loud alarm if moved.',
    'Disc lock':
        'Lock that pins through the brake disc to stop the wheel turning.',
    'Chain lock': 'Heavy chain lock to secure the bike to a fixed object.',
    'Cable lock': 'Flexible cable lock for helmets or light security.',
    'U-lock': 'Rigid U-shaped lock for the wheel or frame.',
    'Handlebar lock': 'Lock that holds the handlebar and brake lever.',
    'Brake-lever lock':
        'Lock that holds the brake lever on so the bike cannot roll.',
    'Alarm system': 'Alarm with remote, often with an engine immobilizer.',
    'Security cover': 'Lockable cover that hides and protects the bike.',
  },
  'Crash Protection': {
    'Crash bar': 'Steel bars that protect the engine and bodywork in a fall.',
    'Engine guard': 'Guard that protects the engine cases.',
    'Frame slider': 'Sliders that protect the frame and fairing in a fall.',
    'Axle slider': 'Sliders on the axles that protect the forks and swingarm.',
    'Swingarm slider': 'Sliders on the swingarm, also used as stand spools.',
    'Fork protector': 'Guards on the fork legs.',
    'Bar-end slider': 'Sliders on the handlebar ends.',
    'Skid plate': 'Plate under the engine for off-road protection.',
    'Radiator guard': 'Mesh that stops stones from puncturing the radiator.',
    'Hand guard': 'Guards that protect your hands and levers.',
  },
  'Wind Protection': {
    'Standard windshield': 'Original-height screen.',
    'Touring windshield': 'Taller screen for less wind on long rides.',
    'Tall windshield': 'Extra-tall screen for maximum wind protection.',
    'Short windshield': 'Low, sporty screen.',
    'Adjustable windshield': 'Screen with adjustable height or angle.',
    'Smoked windshield': 'Tinted screen for style and glare.',
    'Clear windshield': 'Clear screen for full visibility.',
    'Wind deflector': 'Clip-on deflector that redirects wind.',
    'Hand-wind deflector': 'Deflectors that keep wind off your hands.',
  },
  'Handlebar Accessories': {
    'Handlebar riser': 'Raises the handlebar for a more upright position.',
    'Handlebar clamp': 'Clamp for mounting accessories on the bar.',
    'Handlebar pad': 'Foam pad on the crossbar for off-road safety.',
    'Bar-end weights': 'Weights that reduce handlebar vibration.',
    'Bar-end mirrors': 'Mirrors that mount on the handlebar ends.',
    'Heated grips': 'Grips that warm your hands in cold weather.',
    'Hand guards': 'Guards that protect hands and levers.',
    'Throttle assist': 'Rest that lets you hold the throttle with your palm.',
    'Cruise-control throttle lock':
        'Holds the throttle open on long straight roads.',
    'Handlebar extender': 'Adds mounting space for phone holders and lights.',
  },
  'Lighting Accessories': {
    'LED headlight': 'Brighter, more efficient LED headlight.',
    'Auxiliary driving lights': 'Extra lights for better night visibility.',
    'Fog lights': 'Low-mounted lights for fog and rain.',
    'LED light bar': 'Bright bar light for off-road use.',
    'LED turn signals': 'Compact, bright LED indicators.',
    'Sequential turn signals': 'Indicators that light in a running sequence.',
    'Hazard-light kit': 'Adds a hazard switch to flash all signals.',
    'Brake-light flasher': 'Makes the brake light flash for attention.',
    'Reflective tape': 'Tape that reflects headlights at night.',
    'Additional tail light': 'Extra tail light for more visibility.',
  },
  'Horn and Visibility Accessories': {
    'Standard horn': 'Replacement 12 V horn.',
    'Dual-tone horn': 'Louder two-tone horn.',
    'Air horn': 'Very loud compressor horn.',
    'Compact electric horn': 'Small, loud horn that fits tight spaces.',
    'Reflective vest': 'High-visibility vest for night and traffic.',
    'Reflective stickers': 'Stickers that reflect light at night.',
    'Reflective wheel tape':
        'Tape on the rims that reflects light from the side.',
    'Safety flag': 'Tall flag for visibility on trails.',
    'Rear reflector': 'Red reflector for the rear.',
  },
  'Comfort Accessories': {
    'Seat cushion': 'Cushion that reduces pressure on long rides.',
    'Gel seat pad': 'Gel pad that absorbs vibration.',
    'Memory-foam seat pad': 'Foam pad that shapes to you.',
    'Seat cover': 'Replacement or protective seat cover.',
    'Heated seat': 'Seat with heating for cold weather.',
    'Passenger backrest': 'Backrest for passenger comfort and security.',
    'Rider backrest': 'Lumbar backrest for the rider.',
    'Footrest': 'Replacement or extra footrest.',
    'Highway pegs': 'Forward pegs to stretch your legs on long rides.',
    'Foot-peg extender': 'Moves the foot pegs for a better fit.',
  },
  'Passenger Accessories': {
    'Passenger grab bar': 'Handle the passenger holds onto.',
    'Passenger footrest': 'Foot pegs for the passenger.',
    'Passenger foot-peg rubber': 'Rubber covers for passenger pegs.',
    'Passenger seat cushion': 'Extra padding for the pillion seat.',
    'Passenger hand grip': 'Grip or belt the passenger can hold.',
    'Passenger top-box pad': 'Backrest pad on the top box.',
    'Passenger rain cover': 'Rain cover for the passenger.',
  },
  'Storage Accessories': {
    'Cargo net': 'Elastic net that holds loose items on the seat or rack.',
    'Bungee cord': 'Elastic hooked cord for strapping loads.',
    'Tie-down strap': 'Strap for securing the bike when transporting it.',
    'Ratchet strap': 'Strap that tightens with a ratchet for heavy loads.',
    'Luggage strap': 'Strap for securing bags.',
    'Cargo hook': 'Hook for hanging bags.',
    'Utility pouch': 'Small pouch for odds and ends.',
    'Tool pouch': 'Pouch for carrying tools.',
    'Saddlebag organizer': 'Divider that keeps saddlebag contents tidy.',
    'Top-box organizer': 'Liner or divider for the top box.',
  },
  'Maintenance and Emergency Accessories': {
    'Motorcycle tool kit':
        'Compact set of the common tools for roadside fixes.',
    'Tire-repair kit': 'Kit for fixing punctures on the road.',
    'Tire inflator': 'Pump or CO2 inflator for flat tires.',
    'Portable air compressor': '12 V compressor for topping up tires.',
    'Jumper cable': 'Cables to jump-start from another battery.',
    'Portable jump starter': 'Power bank that jump-starts a dead battery.',
    'First-aid kit': 'Compact first-aid supplies.',
    'Emergency flashlight': 'Flashlight for night repairs.',
    'Reflective warning triangle':
        'Triangle to warn traffic when stopped on the road.',
    'Emergency rain poncho': 'Compact poncho for sudden rain.',
  },
  'Tire Accessories': {
    'Tire-pressure gauge': 'Gauge for checking tire pressure.',
    'Tire-pressure monitoring system':
        'Sensors that show tire pressure on a display.',
    'Tubeless tire-repair kit': 'Plug kit for tubeless tire punctures.',
    'Tire plug kit': 'Plugs and tools to seal punctures.',
    'Tire sealant': 'Liquid inside the tire that seals small punctures.',
    'Valve-cap set': 'Replacement valve caps.',
    'Angled valve stem': 'Bent valve stem that makes checking pressure easier.',
    'Tire warmers': 'Electric blankets that warm tires before track riding.',
    'Wheel balancing weights':
        'Weights that balance the wheel to stop vibration.',
  },
  'Stand and Parking Accessories': {
    'Side-stand pad': 'Wider foot for the side stand on soft ground.',
    'Center stand': 'Stand that lifts the rear wheel for maintenance.',
    'Paddock stand': 'Stand that lifts a wheel for chain care.',
    'Front stand': 'Paddock stand that lifts the front wheel.',
    'Rear stand': 'Paddock stand that lifts the rear wheel.',
    'Motorcycle ramp': 'Ramp for loading the bike into a vehicle.',
    'Wheel chock': 'Holds the front wheel upright for parking or transport.',
    'Parking mat': 'Mat that catches drips in the garage.',
    'Stand extender': 'Extends the side stand to balance a lowered bike.',
  },
  'Cleaning Accessories': {
    'Motorcycle shampoo': 'Gentle wash that is safe on paint and decals.',
    'Chain-cleaning brush': 'Brush that scrubs all sides of the chain.',
    'Wheel brush': 'Long brush that reaches between spokes.',
    'Detailing brush': 'Small brush for tight spots.',
    'Microfiber cloth': 'Soft cloth for drying and polishing.',
    'Drying towel': 'Absorbent towel for streak-free drying.',
    'Wash mitt': 'Soft mitt that lifts dirt without scratching.',
    'Spray bottle': 'Bottle for cleaner or quick detailer.',
    'Motorcycle cleaning kit': 'Set of cleaners, brushes and cloths.',
    'Portable pressure washer': 'Compact washer for rinsing the bike.',
  },
  'Protection and Appearance Accessories': {
    'Tank pad': 'Pad that protects the tank paint from scratches.',
    'Tank protector': 'Cover that protects the tank.',
    'Frame protection film': 'Clear film that protects the frame paint.',
    'Paint protection film': 'Clear film that guards paint from chips.',
    'Carbon-fiber cover': 'Carbon-look cover for style.',
    'Decal kit': 'Graphics kit for a new look.',
    'Vinyl wrap': 'Removable film that changes the color.',
    'Rim stickers': 'Stickers or stripes for the wheel rims.',
    'Chrome accessories': 'Chrome trim pieces for shine.',
    'Number plate frame': 'Frame or holder for the license plate.',
  },
  'Performance Accessories': {
    'Performance air filter': 'High-flow air filter for better response.',
    'Slip-on exhaust': 'Replaces the muffler for sound and less weight.',
    'Full-system exhaust':
        'Replaces the whole exhaust for maximum gains; may need tuning.',
    'Exhaust heat shield': 'Shield that stops burns from the pipe.',
    'Performance spark plug': 'Plug for a stronger, more reliable spark.',
    'Quick shifter': 'Lets you upshift without using the clutch.',
    'Fuel controller': 'Adjusts fuel delivery after modifications.',
    'ECU tuner': 'Device or remap that changes engine settings.',
    'Steering damper': 'Damper that controls handlebar shake at speed.',
    'Performance suspension': 'Upgraded shocks or fork internals.',
  },
  'Scooter Accessories': {
    'Scooter windshield': 'Screen sized for scooter fronts.',
    'Scooter top box': 'Top box with a scooter mounting plate.',
    'Front basket': 'Basket on the front for groceries.',
    'Rear basket': 'Basket on the rear rack.',
    'Floor mat': 'Rubber mat that protects the floorboard.',
    'Leg cover': 'Apron that keeps rain and wind off your legs.',
    'Scooter hand guard': 'Guards that keep wind and rain off your hands.',
    'Scooter phone holder': 'Phone holder that fits scooter bars and mirrors.',
    'Scooter rear carrier': 'Rack for top boxes or cargo.',
    'Scooter wind deflector': 'Small deflector for less wind.',
  },
  'Electric Motorcycle Accessories': {
    'Battery charger': 'Charger matched to the battery voltage and connector.',
    'Portable charger': 'Compact charger to take with you.',
    'Charging cable': 'Cable for the charging port.',
    'Charging-port cover': 'Cover that keeps water and dust out of the port.',
    'Battery storage case':
        'Fire-resistant case for storing removable batteries.',
    'Battery lock': 'Lock that secures a removable battery.',
    'Charging adapter': 'Adapter for different outlets or connectors.',
    'Range tracker': 'Shows remaining range and battery level.',
    'Electric-motor diagnostic tool':
        'Tool for reading motor and controller fault codes.',
  },
};
