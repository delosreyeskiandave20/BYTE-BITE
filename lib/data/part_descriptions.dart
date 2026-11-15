/// What each motorcycle part is and does, keyed by lower-case part name as it
/// appears in assets/motorcycle_parts_catalog.json. Spelling variants of the
/// same part share one entry through [_aliases].
String? partDescription(String part) {
  final key = part.toLowerCase().trim();
  return _descriptions[_aliases[key] ?? key];
}

const _aliases = <String, String>{
  'abs tone ring/sensor where fitted': 'abs tone ring/sensor',
  'abs/wheel-speed sensor where fitted': 'abs/wheel-speed sensor',
  'abs/engine sensor as fitted': 'abs/wheel-speed sensor',
  'brake shoe set': 'brake pad/shoe set',
  'brake shoe/pad set': 'brake pad/shoe set',
  'ecu/cdi unit': 'cdi/ecu unit',
  'ecu/fi control unit': 'ecu/pgm-fi unit',
  'engine guard/cover': 'engine cover/guard',
  'front fairing': 'front cowl/fairing',
  'front fairing/cowl': 'front cowl/fairing',
  'headlight mask/cowl': 'front cowl/headlight cover',
  'headlight/front cowl': 'front cowl/headlight cover',
  'front-fork oil': 'fork oil',
  'front fork spring': 'fork spring',
  'front-fork spring': 'fork spring',
  'fuel-tank cover/pad': 'fuel-tank cover/decals',
  'grab bar': 'grab rail',
  'rear carrier/grab rail': 'rear rack/grab rail',
  'ignition-coil set': 'ignition coil',
  'inner tubes': 'inner tube',
  'oil filter/strainer': 'oil screen/filter',
  'oil strainer/filter': 'oil screen/filter',
  'oxygen sensor where fitted': 'oxygen sensor',
  'rear mudguard': 'rear fender/mudguard',
  'rear fender': 'rear fender/mudguard',
  'rim tape/spokes where applicable': 'rim tape/spokes',
  'seat cover': 'seat assembly/seat cover',
  'seat/seat cover': 'seat assembly/seat cover',
  'side covers': 'side cover',
  'side fairing/panel': 'side fairing panels',
  'side mirrors': 'side mirror',
  'side-stand spring/switch': 'side-stand spring',
  'spark-plug cap set': 'spark-plug cap',
  'spark-plug set': 'spark plug',
  'swingarm bearing/bushing': 'swingarm bearing',
  'swingarm bushing': 'swingarm/pivot bushing',
  'tubeless valve stems': 'tubeless valve stem',
  'wheel seals': 'wheel oil seal',
  'side-stand/neutral switch': 'side-stand switch',
  'headlight/tail-light assembly': 'headlight assembly',
};

const _descriptions = <String, String>{
  // Engine
  'engine oil':
      'Four-stroke motorcycle oil that lubricates the engine, gearbox and '
      'clutch and carries away heat. Use the viscosity and JASO MA/MB rating '
      'in the owner\'s manual.',
  'oil screen/filter':
      'Mesh screen or paper filter that catches metal particles and sludge '
      'before oil reaches the engine. Clean or replace it at every oil change.',
  'oil filter':
      'Spin-on or cartridge filter that removes wear particles from the '
      'engine oil. Replace it together with the oil.',
  'drain-plug washer':
      'Crush washer (aluminium or copper) that seals the oil drain bolt. '
      'Fit a new one each oil change to stop leaks.',
  'air filter':
      'Paper or foam element in the airbox that stops dust and sand from '
      'entering the engine. A clogged filter cuts power and fuel economy.',
  'spark plug':
      'Fires the air-fuel mixture in the cylinder. Must match the thread '
      'reach and heat range listed for the engine.',
  'cvt drive belt':
      'Rubber V-belt that carries power from the front pulley to the clutch '
      'in a scooter CVT. Replace it before it cracks or glazes.',
  'variator roller set':
      'Weighted rollers inside the front pulley that shift the CVT ratio as '
      'engine speed rises. Roller weight changes acceleration feel.',
  'cvt slider set':
      'Plastic guide pieces on the variator ramp plate. Worn sliders cause '
      'rattles and jerky take-off.',
  'clutch shoe set':
      'Centrifugal clutch shoes on the rear pulley of a scooter. They grip '
      'the clutch bell as revs rise to move the scooter.',
  'clutch-plate set':
      'Friction and steel plates of a manual wet clutch. Slipping or '
      'grabbing means the plates are worn.',
  'clutch-spring set':
      'Springs that press the clutch plates together. Weak springs let the '
      'clutch slip under load.',
  'cam-chain tensioner':
      'Keeps the camshaft timing chain tight. A worn tensioner makes a '
      'rattling noise from the top of the engine.',
  'coolant':
      'Pre-mixed radiator coolant for liquid-cooled engines. Prevents '
      'overheating and corrosion inside the cooling system.',
  'final-drive gear oil':
      'Gear oil for the scooter rear final-drive case. It is separate from '
      'engine oil and changed less often.',
  'drive chain':
      'Roller chain that drives the rear wheel. Keep it cleaned, lubed and '
      'adjusted to the correct slack.',
  'front/rear sprocket set':
      'Front and rear sprockets that drive the chain. Replace them together '
      'with the chain when teeth are hooked or worn.',
  // Electrical
  '12-v battery':
      '12-volt sealed (maintenance-free) battery that powers starting, '
      'lights and the fuel-injection system.',
  'main fuse':
      'Blade fuse that protects the main wiring harness. A blown fuse cuts '
      'all power to the motorcycle.',
  'starter relay':
      'Solenoid that switches the high current to the starter motor when '
      'you press the start button.',
  'regulator/rectifier':
      'Converts the stator\'s AC output to DC and caps the charging voltage '
      'so the battery is not overcharged.',
  'stator/charging coil':
      'Coil assembly inside the engine cover that generates electricity '
      'to charge the battery.',
  'ignition coil':
      'Steps the battery voltage up to the high voltage needed to fire the '
      'spark plug.',
  'spark-plug cap':
      'Rubber cap that connects the ignition lead to the spark plug and '
      'seals out water.',
  'cdi/ecu unit':
      'Ignition control box that times the spark. A faulty unit causes '
      'misfires or a no-start.',
  'ecu/pgm-fi unit':
      'Engine control unit that runs fuel injection and ignition timing '
      'from sensor readings.',
  'oxygen sensor':
      'Sensor in the exhaust that measures leftover oxygen so the ECU can '
      'adjust the fuel mixture.',
  'brake-light switch':
      'Switch on the brake lever or pedal that turns on the brake light '
      'when you brake.',
  'neutral switch':
      'Switch on the gearbox that lights the neutral indicator and allows '
      'starting in neutral.',
  'abs/wheel-speed sensor':
      'Wheel-speed sensor read by the ABS unit to detect a locking wheel '
      'and release brake pressure.',
  // Suspension
  'fork oil':
      'Hydraulic oil inside the front forks that controls damping. Use the '
      'grade and fill level for the fork.',
  'fork oil seal':
      'Seal at the top of each fork leg that keeps fork oil in. A leaking '
      'seal leaves oil on the fork tube.',
  'fork dust seal':
      'Outer wiper seal that keeps dirt and water away from the fork oil '
      'seal.',
  'fork bushing':
      'Low-friction sleeves that let the fork tubes slide smoothly. Worn '
      'bushings cause front-end clunks.',
  'fork spring':
      'Coil spring inside the fork that holds the front up and absorbs '
      'bumps. A sagging spring makes the front dive under braking.',
  'rear shock absorber':
      'Rear suspension unit with spring and damper. Replace when the rear '
      'bounces or leaks oil.',
  'rear-shock bushing':
      'Rubber or metal bushes at the shock mounting points. Worn bushes '
      'cause knocking over bumps.',
  'steering-head bearing':
      'Bearings in the frame head that let the handlebar turn. A notchy or '
      'loose feel means they need replacing.',
  'swingarm bearing':
      'Bearings at the swingarm pivot that let the rear wheel move up and '
      'down smoothly.',
  'swingarm/pivot bushing':
      'Bushings at the swingarm or engine pivot. Wear causes a vague, '
      'loose rear end.',
  'side-stand spring':
      'Spring that snaps the side stand up when it is kicked back.',
  'side-stand switch':
      'Safety switch that stops the engine if you put the bike in gear '
      'with the side stand down.',
  // Wheels, tires & brakes
  'front tire':
      'Front tire. Use the size and load/speed rating listed for the '
      'motorcycle.',
  'rear tire':
      'Rear tire. Use the size and load/speed rating listed for the '
      'motorcycle.',
  'inner tube':
      'Inner tube for spoke wheels or tube-type tires. Match the tube to '
      'the tire size.',
  'inner tube or tubeless valve':
      'Inner tube for tube-type wheels, or the valve for tubeless wheels, '
      'depending on the variant.',
  'tubeless valve stem':
      'Rubber valve stem for tubeless rims. Replace it when fitting new '
      'tires.',
  'tire-pressure valve/core':
      'Valve core that holds air in the tire. A faulty core causes slow '
      'leaks.',
  'front wheel bearing':
      'Sealed ball bearings in the front hub that let the wheel spin '
      'freely.',
  'rear wheel bearing':
      'Sealed ball bearings in the rear hub. Worn bearings cause wobble or '
      'a grinding noise.',
  'wheel oil seal':
      'Seal beside the wheel bearing that keeps water and dirt out of the '
      'hub.',
  'front axle/collar':
      'Front axle and spacer collars that locate the front wheel in the '
      'fork.',
  'rear axle/collar':
      'Rear axle and spacer collars that locate the rear wheel.',
  'front/rear axle spacers':
      'Spacers on the axles that keep the wheels centred and the brake '
      'discs aligned.',
  'brake disc or drum':
      'Brake disc rotor or drum that the pads or shoes press against. '
      'Replace when worn below minimum thickness.',
  'front brake disc':
      'Front disc rotor. Replace when scored, warped or below minimum '
      'thickness.',
  'rear brake disc':
      'Rear disc rotor. Replace when scored, warped or below minimum '
      'thickness.',
  'brake pad/shoe set':
      'Brake pads (disc) or brake shoes (drum). Replace when the friction '
      'material is worn thin.',
  'abs tone ring/sensor':
      'Toothed ring and sensor on the wheel that tell the ABS unit how fast '
      'the wheel is turning.',
  'rim tape':
      'Tape inside the rim that protects the inner tube from spoke ends.',
  'rim tape/spokes':
      'Rim tape and spokes for spoke wheels. Loose or broken spokes weaken '
      'the wheel.',
  'spoke/nipple set where fitted':
      'Spokes and nipples that hold a spoke wheel together and true.',
  // Body
  'front cowl/fairing':
      'Front body panel around the headlight and handlebar that shapes the '
      'look and deflects wind.',
  'front cowl/headlight cover':
      'Front cover that frames and protects the headlight.',
  'leg shield/floor panel':
      'Scooter inner leg shield and floorboard that protect the rider\'s '
      'legs and give a place for the feet.',
  'front fender':
      'Front mudguard that stops water and mud from spraying off the front '
      'tire.',
  'rear fender/mudguard':
      'Rear mudguard that keeps water and mud off the rider and number '
      'plate.',
  'side cover': 'Side body panel that covers the frame, battery or air box.',
  'center/side cover panels': 'Center and side body panels below the seat.',
  'side panels': 'Side body panels under the seat and tank.',
  'side fairing panels':
      'Side fairing pieces that cover the engine and frame on sport bikes.',
  'rear cowl': 'Tail section body panel behind the seat.',
  'seat assembly/seat cover':
      'Complete seat or replacement seat cover. Match the seat base to the '
      'model.',
  'grab rail':
      'Rear handle the passenger holds onto, also used to lift the '
      'motorcycle onto its stand.',
  'rear rack/grab rail':
      'Rear carrier with grab handles for luggage or a top box.',
  'side mirror':
      'Rear-view mirror with mounting stem. Match the thread (usually 10 mm) '
      'and side.',
  'headlight assembly':
      'Complete headlight unit with lens, housing and bulb or LED.',
  'tail-light assembly': 'Complete tail and brake light unit.',
  'tail-light/turn-signal assembly':
      'Rear light unit combining the tail light, brake light and turn '
      'signals.',
  'turn-signal assembly': 'Turn-signal lamp with lens and bulb or LED.',
  'chain guard':
      'Cover over the top of the drive chain that keeps clothes and hands '
      'away from it.',
  'engine cover/guard':
      'Cover or guard that protects the engine cases from knocks and '
      'scratches.',
  'engine guard/skid plate':
      'Underside plate that protects the engine from rocks on rough roads.',
  'fuel-tank cover/decals':
      'Tank cover, pad or decals that protect the paint on the fuel tank.',
  'fuel-tank rubber mounts':
      'Rubber mounts that hold the fuel tank and absorb vibration.',
  'hand guards':
      'Guards on the handlebar ends that protect the hands and levers.',
  'windscreen':
      'Front screen that deflects wind from the rider\'s chest and helmet.',

  // Engine (added)
  'throttle cable':
      'Cable that links the throttle grip to the throttle body or '
      'carburettor. Replace it if the throttle feels stiff, the cable is '
      'frayed, or the grip does not snap back closed.',
  'piston ring set':
      'Compression and oil rings that seal the piston against the cylinder '
      'wall. Worn rings cause blue smoke, oil burning and low power.',
  'cylinder-head cover gasket':
      'Rubber gasket that seals the valve cover on top of the engine. '
      'Replace it when oil seeps out around the head cover.',
  'exhaust gasket':
      'Heat-resistant ring that seals the exhaust pipe to the cylinder head. '
      'A leaking gasket makes a ticking sound and can upset the fuel mixture.',
  'intake manifold/insulator':
      'Rubber joint between the throttle body or carburettor and the '
      'cylinder head. Cracks let in extra air and cause rough idling.',

  // Electrical (added)
  'horn':
      '12-V horn that warns other road users. Match the bracket and '
      'connector, and check it works before every ride.',
  'turn-signal relay':
      'Flasher relay that makes the turn signals blink. LED signals usually '
      'need an LED-compatible relay to flash at the correct speed.',
  'starter motor':
      'Electric motor that cranks the engine when you press the starter '
      'button. Slow cranking with a good battery points to worn brushes or '
      'a failing motor.',
  'handlebar switch set':
      'Switch housings on the handlebar for lights, horn, turn signals and '
      'starter. Replace when buttons stick or only work some of the time.',
  'ignition switch/key set':
      'Key switch (or smart-key unit on keyless models) that turns on the '
      'electrical system. Often sold with matching seat and fuel-cap locks.',

  // Suspension (added)
  'front fork inner tube':
      'Chrome tube that slides inside the fork leg. Rust, pitting or a bent '
      'tube quickly ruins the fork seals and must be replaced.',
  'side stand':
      'Kickstand that holds the motorcycle upright when parked. Replace it '
      'if it is bent or no longer stays firmly in the up position.',
  'rear-shock mounting bolts':
      'Bolts and nuts that hold the rear shock to the frame and swingarm or '
      'engine. Use the correct grade and tighten to the specified torque.',
  'center stand':
      'Two-legged stand that lifts the rear wheel off the ground for stable '
      'parking, chain or tire work, and cleaning.',
  'center-stand spring':
      'Return spring that pulls the center stand up and keeps it from '
      'dragging. Replace it if the stand rattles or drops while riding.',
  'swingarm':
      'Rear arm that holds the rear wheel and pivots on the frame with the '
      'shock absorber. Check it for cracks or bends after a fall.',
  'chain slider':
      'Plastic or rubber guide on the swingarm that stops the drive chain '
      'from cutting into it. Replace it when it is worn through.',

  // Wheels & tires (added)
  'front wheel rim':
      'Front wheel (alloy or spoked rim) that holds the tire. Replace it if '
      'it is bent, cracked or will not hold air.',
  'rear wheel rim':
      'Rear wheel (alloy or spoked rim) that holds the tire and carries the '
      'drive. Replace it if it is bent, cracked or will not hold air.',
  'brake lever set':
      'Hand levers that work the brakes: both brakes on scooters, the front '
      'brake on bikes with a foot pedal. Replace bent or broken levers.',
  'front brake hose/cable':
      'Hydraulic hose (disc brake) or steel cable (drum brake) that carries '
      'lever force to the front brake. Replace hoses that bulge or crack and '
      'cables that fray.',
  'speed sensor/speedometer gear':
      'Wheel-driven gear or electronic sensor that sends road speed to the '
      'speedometer. A faulty one makes the reading stop or jump.',

  // Body (added)
  'footrest set':
      'Rider and passenger footpegs or footrest rubbers. Replace worn rubbers '
      'and bent pegs for secure footing.',
  'handlebar grip set':
      'Rubber grips for the left bar and the throttle. Worn or slippery '
      'grips reduce control, especially in the rain.',
  'fuel cap':
      'Locking cap that seals the fuel tank and keeps water and dirt out. '
      'Match the key type and the filler-neck shape.',
  'license-plate bracket':
      'Bracket that holds the rear license plate and often the plate light. '
      'Make sure it fits the local plate size.',
  'body clips and fasteners':
      'Plastic clips, rivets and screws that hold panels and fairings in '
      'place. Keep spares, as they often break when panels are removed.',
};
