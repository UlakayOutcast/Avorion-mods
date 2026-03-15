Quick guide to ESCC functions:

Adds the following extra pirate ship classes:

    - Jammer - A tiny pirate ship that carries hyperspace blocker equipment.
    - Bomber - A pirate ship with the siege gun script. Uses artillery weapons like rockets and cannons.
    - Stinger - A tiny, fast pirate ship that carries a set of anti-shield equipment.
    - Scorcher - A mid-sized, dangerous ship that focuses on destroying enemy shields.
    - Sinner - An odd pirate ship that uses Xsotan technology.
    - Prowler - A heavy, workhorse combat ship.
    - Pillager - A large combat ship armed with Disruptor, Persecutor, or Torpedo Boat equipment. Comes with an extra set of standard military equipment.
    - Devastator - An ultra heavy combat ship armed with Artillery or Flagship equipment. Comes with two extra sets of standard military equipment.
    - Executioner - A scaling heavy combat ship. No upper limit on durability and firepower. Comes with a surprise.
    - Flagship - The same as a pirate mothership, except this has no probability of using point defense weapons.

Adds the following extra faction ship classes:

    - Heavy Defender - A heavy ship that is roughly twice as large as a defender and has 50% more firepower.
    - Heavy Carrier - A heavy ship that is almost twice as large as a carrier and has more fighters.
    - AWACS - A ship that is twice as large as a standard headhunter blocker ship and comes with an extra set of military equipment.
    - Scout - A small, lightly-armed ship.
    - Civil Transport - A transportation ship. Similar to a freighter, but has its cargo bay replaced by crew quarters / engines.

Adds the following extra Xsotan:

    - Infestor - A variety of the Xsotan summoner that has higher damage than usual and drops better loot.
    - Sunmaker - A Xsotan with a siege cannon
    - Longinus - A Xsotan with a laser
    - Ballistyx - A Xsotan that continually fires torpedoes
    - Oppressor - A Xsotan that continually gains damage over time, with no upper limit on its DPS. It will occasionally grab and eat another Xsotan.
    - Warlock - A Xsotan that will reanimate ship corpses to attack the player.
    - Pulverizer - A Xsotan with low damage cannons that impart an extremely high degree of force.
    - Revenant - A ship reanimated by the Xsotan Warlock - has long range weapons to compensate for being partially destroyed.
    - Hierophant - A summoner and a warlock in one.
    - Parthenope - A deadly cross between a carrier and a summoner that grows in strength with each of its allies killed.
    - Dreadnought - An incredibly powerful Xsotan warship based on Hammelpilaw's Xsotan Dreadnought event.
    - Caduceus - A Xsotan that is focused on healing and buffing other Xsotan.

Adds the following entity scripts:

    - absolutepointdefense - A script that will automatically damage / destroy torpedoes and fighters near the ship it is added to.
    - adaptivedefense - A script that will cause the enemy ship to dynamically gain resistances based on what type of damage has been dealt to it.
    - afterburn - The enemy will flip between a normal state / a state with increased acceleration & maximum speed
    - allybooster - Every minute, this enemy will add a randomly chosen script to one of its allies.
    - avenger - Killing an ally in the same sector will cause this enemy to gain a permanent, exponetially increasing damage buff.
    - eternal - This enemy will heal itself over time.
    - frenzy - This enemy will continually gain damage at low health. The damage gained is additive.
    - hyperaggro - This enemy will constantly declare war on all players / factions in the area.
    - ironcurtain - This enemy will become invulnerable for a period of time when its health drops too low.
    - lasersniper - Gives this enemy a weapon similar to project IDHTX, except better because it doesn't inhibit the enemy from moving.
    - meathook - WIP - pulls its target towards the enemy.
    - meathook2 - WIP - see above.
    - megablocker - Blocks hyperspace in a large range. A VERY large range. Large enough that you might think the entire sector is jammed ;)
    - oppressor - This enemy will continually gain damage. There is no upper limit on how much damage it can gain. This script will also eat other Xsotan for a damage buff occasionally.
    - overdrive - This enemy will flip between a normal state and a state where they deal increased damage.
    - phasemode - This enemy will flip between a normal state and an invulnerable state.
    - reanimator - This enemy will reanimate wreckages in the sector as Xsotan Revenants.
    - secondaryweapons - When this enemy drops below a certain amount of firepower, it will spawn a secondary set of chainguns or bolters. Can be customized.
    - stationsiegegun - Adds a special weapon to the ship that casues it to fire globs of energy that can deal absurd amounts of damage. Despite its name, it can be mounted on a ship.
    - tankemspecial - Effectively combines the iron curtain and siege gun script.
    - terminalblocker - Unlike megablocker, this script does actually jam hyperspace in the entire sector.
    - torpedoslammer - This enemy will spew a constant stream of powerful torpedoes.
    - linker - This script will cause the enemy to share HP with its allies.

Most of the above scripts can be customized in some way. Make sure to look at the individual script for what values can be messed with.

Via ESCC, you can also spawn in the following bosses:

    - The Baleful Katana - a powerful warship with the adaptive defense script, overdrive script, and secondary weapon script. It comes with burst fire railguns and heavy plasma mortars.
    - The Dervish Goliath - a powerful warship with the torpedo slammer and phasemode script. Comes with extremely powerful seeker missiles that have a slow projectile speed.
    - The Relentless Hellcat - a powerful warship with the eternal and phasemode script. Comes with extremely powerful short range lasers.
    - The Scouring Phoenix - a powerful warship with the overdrive and torpedo slammer script. Comes with burst fire cannons.
    - The Vigilant Shield - a powerful warship with the adaptive defense script, absolutepointdefense, and ally booster script. Also summons stronger enemies compared to the other five bosses. Comes with powerful standard cannons.
    - The Steadfast Hunter - a powerful warship with the laser sniper and absolutpointdefense script. Comes with long-range railguns and lightning guns.

Adds the following quality-of-life functions to PirateGenerator:

    - createScaledPirateByName(name, position)
    - createPirateByName(name, position) - Both of these functions will create a pirate ship using the name passed in.
    - getStandardPositions(positionCT, distance) - Gets a table of standard positions based on the normal ship positions in pirateattack.lua. positionCT is the number of positions you want, and distance will specify the distance between the positions.

This also adds similar functions to ShipGenerator.