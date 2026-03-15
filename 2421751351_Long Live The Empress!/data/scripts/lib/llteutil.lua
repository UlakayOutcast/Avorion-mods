package.path = package.path .. ";data/scripts/lib/?.lua"

ESCCUtil = include("esccutil")

local ShipUtility = include ("shiputility")
local MissionUT = include("missionutility")
local PirateGenerator = include("pirategenerator")

local LLTEUtil = {}
local self = LLTEUtil

LLTEUtil._Debug = 0

--region #NAME GENERATION

function LLTEUtil.getFreighterName()
    local _MethodName = "Get Freighter Name"
    LLTEUtil.Log(_MethodName, "Beginning...")

    local _Prefix = {
        "Ammo",
        "Cannon",
        "Claymore",
        "Firearm",
        "Gun",
        "Knife",
        "Machete",
        "Missile",
        "Rifle",
        "Shotgun",
        "Sword",
        "Arbalest",
        "Assegai",
        "Axe",
        "Ballista",
        "Banderilla",
        "Barong",
        "Baton",
        "Bayonet",
        "Blade",
        "Bludgeon",
        "Catapult",
        "Cleaver",
        "Club",
        "Cutlass",
        "Drill",
        "Dartgun",
        "Dagger",
        "Glaive",
        "Harpoon",
        "Hatchet",
        "Halberd",
        "Trident",
        "Hammer",
        "Kris",
        "Kukri",
        "Shuriken",
        "Katana",
        "Lance",
        "Polearm",
        "Saber",
        "Scythe",
        "Spear",
        "Spike",
        "Zweihander",
        "Zanbato",
        "Switchblade",
        "Anlace",
        "Onager",
        "Hwacha",
        "Kpinga",
        "Hunga Munga",
        "Danisco",
        "Goleyo",
        "Khopesh",
        "Mambele",
        "Nimcha",
        "Kaskara",
        "Swordbreaker",
        "Katar",
        "Chakram",
        "Falcata"
    }

    local _Postfix = {
        "Smuggler",
        "Runner",
        "Protector",
        "Liberator",
        "Conservator",
        "Guardian",
        "Savior",
        "Hero",
        "Deliverer",
        "Distributor",
        "Merchandiser",
        "Broker",
        "Mediator",
        "Bootlegger",
        "Negotiator",
        "Dealer",
        "Hawker",
        "Purveyor",
        "Enterpriser"
    }

    local _Rgen = ESCCUtil.getRand()

    return _Prefix[_Rgen:getInt(1, #_Prefix)] .. " " .. _Postfix[_Rgen:getInt(1, #_Postfix)]
end

function LLTEUtil.getCapitalShipName()
    local _MethodName = "Get Capital Ship Name"
    LLTEUtil.Log(_MethodName, "Beginning...")

    local _Prefix = {
        "Advance and",
        "Oath to",
        "Sworn to",
        "Command to",
        "Vow to",
        "Stand and",
        "Threat to",
        "Conquer and",
        "Divide and",
        "Bound to",
        "Promise to"
    }

    local _Postfix = {
        "Destroy",
        "Defend",
        "Enforce",
        "Overpower",
        "Overrun",
        "Protect",
        "Safeguard",
        "Shelter",
        "Shield",
        "Sanction",
        "Secure",
        "Triumph",
        "Trample",
        "Vanquish"        
    }

    local _Rgen = ESCCUtil.getRand()

    return _Prefix[_Rgen:getInt(1, #_Prefix)] .. " " .. _Postfix[_Rgen:getInt(1, #_Postfix)]
end

function LLTEUtil.getHumanNameTable()
    return {
        { name = "James", gender = "m" },
        { name = "John", gender = "m" },
        { name = "Robert", gender = "m" },
        { name = "Michael", gender = "m" },
        { name = "William", gender = "m" },
        { name = "David", gender = "m" },
        { name = "Richard", gender = "m" },
        { name = "Joseph", gender = "m" },
        { name = "Thomas", gender = "m" },
        { name = "Charles", gender = "m" },
        { name = "Christopher", gender = "m" },
        { name = "Daniel", gender = "m" },
        { name = "Matthew", gender = "m" },
        { name = "Anthony", gender = "m" },
        { name = "Donald", gender = "m" },
        { name = "Mark", gender = "m" },
        { name = "Paul", gender = "m" },
        { name = "Steven", gender = "m" },
        { name = "Andrew", gender = "m" },
        { name = "Kenneth", gender = "m" },
        { name = "Joshua", gender = "m" },
        { name = "Kevin", gender = "m" },
        { name = "Brian", gender = "m" },
        { name = "George", gender = "m" },
        { name = "Edward", gender = "m" },
        { name = "Ronald", gender = "m" },
        { name = "Timothy", gender = "m" },
        { name = "Jason", gender = "m" },
        { name = "Jeffrey", gender = "m" },
        { name = "Ryan", gender = "m" },
        { name = "Jacob", gender = "m" },
        { name = "Gary", gender = "m" },
        { name = "Nicholas", gender = "m" },
        { name = "Eric", gender = "m" },
        { name = "Jonathan", gender = "m" },
        { name = "Stephen", gender = "m" },
        { name = "Larry", gender = "m" },
        { name = "Justin", gender = "m" },
        { name = "Scott", gender = "m" },
        { name = "Brandon", gender = "m" },
        { name = "Benjamin", gender = "m" },
        { name = "Samuel", gender = "m" },
        { name = "Frank", gender = "m" },
        { name = "Gregory", gender = "m" },
        { name = "Raymond", gender = "m" },
        { name = "Alexander", gender = "m" },
        { name = "Patrick", gender = "m" },
        { name = "Jack", gender = "m" },
        { name = "Dennis", gender = "m" },
        { name = "Jerry", gender = "m" },
        { name = "Tyler", gender = "m" },
        { name = "Aaron", gender = "m" },
        { name = "Jose", gender = "m" },
        { name = "Henry", gender = "m" },
        { name = "Adam", gender = "m" },
        { name = "Douglas", gender = "m" },
        { name = "Nathan", gender = "m" },
        { name = "Peter", gender = "m" },
        { name = "Zachary", gender = "m" },
        { name = "Kyle", gender = "m" },
        { name = "Walter", gender = "m" },
        { name = "Harold", gender = "m" },
        { name = "Jeremy", gender = "m" },
        { name = "Ethan", gender = "m" },
        { name = "Carl", gender = "m" },
        { name = "Keith", gender = "m" },
        { name = "Roger", gender = "m" },
        { name = "Gerald", gender = "m" },
        { name = "Christian", gender = "m" },
        { name = "Terry", gender = "m" },
        { name = "Sean", gender = "m" },
        { name = "Arthur", gender = "m" },
        { name = "Austin", gender = "m" },
        { name = "Noah", gender = "m" },
        { name = "Lawrence", gender = "m" },
        { name = "Jesse", gender = "m" },
        { name = "Joe", gender = "m" },
        { name = "Bryan", gender = "m" },
        { name = "Billy", gender = "m" },
        { name = "Jordan", gender = "m" },
        { name = "Albert", gender = "m" },
        { name = "Dylan", gender = "m" },
        { name = "Bruce", gender = "m" },
        { name = "Willie", gender = "m" },
        { name = "Gabriel", gender = "m" },
        { name = "Alan", gender = "m" },
        { name = "Juan", gender = "m" },
        { name = "Logan", gender = "m" },
        { name = "Wayne", gender = "m" },
        { name = "Ralph", gender = "m" },
        { name = "Roy", gender = "m" },
        { name = "Eugene", gender = "m" },
        { name = "Randy", gender = "m" },
        { name = "Vincent", gender = "m" },
        { name = "Russell", gender = "m" },
        { name = "Louis", gender = "m" },
        { name = "Philip", gender = "m" },
        { name = "Bobby", gender = "m" },
        { name = "Johnny", gender = "m" },
        { name = "Bradley", gender = "m" },
        { name = "Mary", gender = "f" },
        { name = "Patricia", gender = "f" },
        { name = "Jennifer", gender = "f" },
        { name = "Linda", gender = "f" },
        { name = "Elizabeth", gender = "f" },
        { name = "Barbara", gender = "f" },
        { name = "Susan", gender = "f" },
        { name = "Jessica", gender = "f" },
        { name = "Sarah", gender = "f" },
        { name = "Karen", gender = "f" },
        { name = "Nancy", gender = "f" },
        { name = "Lisa", gender = "f" },
        { name = "Margaret", gender = "f" },
        { name = "Betty", gender = "f" },
        { name = "Sandra", gender = "f" },
        { name = "Ashley", gender = "f" },
        { name = "Dorothy", gender = "f" },
        { name = "Kimberly", gender = "f" },
        { name = "Emily", gender = "f" },
        { name = "Donna", gender = "f" },
        { name = "Michelle", gender = "f" },
        { name = "Carol", gender = "f" },
        { name = "Amanda", gender = "f" },
        { name = "Melissa", gender = "f" },
        { name = "Deborah", gender = "f" },
        { name = "Stephanie", gender = "f" },
        { name = "Rebecca", gender = "f" },
        { name = "Laura", gender = "f" },
        { name = "Sharon", gender = "f" },
        { name = "Cynthia", gender = "f" },
        { name = "Kathleen", gender = "f" },
        { name = "Amy", gender = "f" },
        { name = "Shirley", gender = "f" },
        { name = "Angela", gender = "f" },
        { name = "Helen", gender = "f" },
        { name = "Anna", gender = "f" },
        { name = "Brenda", gender = "f" },
        { name = "Pamela", gender = "f" },
        { name = "Nicole", gender = "f" },
        { name = "Samantha", gender = "f" },
        { name = "Katherine", gender = "f" },
        { name = "Emma", gender = "f" },
        { name = "Ruth", gender = "f" },
        { name = "Christine", gender = "f" },
        { name = "Catherine", gender = "f" },
        { name = "Debra", gender = "f" },
        { name = "Rachel", gender = "f" },
        { name = "Carolyn", gender = "f" },
        { name = "Janet", gender = "f" },
        { name = "Virginia", gender = "f" },
        { name = "Maria", gender = "f" },
        { name = "Heather", gender = "f" },
        { name = "Diane", gender = "f" },
        { name = "Julie", gender = "f" },
        { name = "Joyce", gender = "f" },
        { name = "Victoria", gender = "f" },
        { name = "Kelly", gender = "f" },
        { name = "Christina", gender = "f" },
        { name = "Lauren", gender = "f" },
        { name = "Joan", gender = "f" },
        { name = "Evelyn", gender = "f" },
        { name = "Olivia", gender = "f" },
        { name = "Judith", gender = "f" },
        { name = "Megan", gender = "f" },
        { name = "Cheryl", gender = "f" },
        { name = "Martha", gender = "f" },
        { name = "Andrea", gender = "f" },
        { name = "Frances", gender = "f" },
        { name = "Hannah", gender = "f" },
        { name = "Jacqueline", gender = "f" },
        { name = "Ann", gender = "f" },
        { name = "Gloria", gender = "f" },
        { name = "Jean", gender = "f" },
        { name = "Kathryn", gender = "f" },
        { name = "Alice", gender = "f" },
        { name = "Teresa", gender = "f" },
        { name = "Lydia", gender = "f" },
        { name = "Sara", gender = "f" },
        { name = "Janice", gender = "f" },
        { name = "Doris", gender = "f" },
        { name = "Madison", gender = "f" },
        { name = "Julia", gender = "f" },
        { name = "Grace", gender = "f" },
        { name = "Judy", gender = "f" },
        { name = "Abigail", gender = "f" },
        { name = "Marie", gender = "f" },
        { name = "Denise", gender = "f" },
        { name = "Beverly", gender = "f" },
        { name = "Amber", gender = "f" },
        { name = "Theresa", gender = "f" },
        { name = "Marilyn", gender = "f" },
        { name = "Danielle", gender = "f" },
        { name = "Diana", gender = "f" },
        { name = "Brittany", gender = "f" },
        { name = "Natalie", gender = "f" },
        { name = "Sophia", gender = "f" },
        { name = "Rose", gender = "f" },
        { name = "Isabella", gender = "f" },
        { name = "Alexis", gender = "f" },
        { name = "Kayla", gender = "f" },
        { name = "Charlotte", gender = "f" }
    }
end

function LLTEUtil.getLastNameTable()
    return {
        "Smith",
        "Johnson",
        "Williams",
        "Brown",
        "Jones",
        "Garcia",
        "Miller",
        "Davis",
        "Rodriguez",
        "Martinez",
        "Hernandez",
        "Lopez",
        "Gonzalez",
        "Wilson",
        "Anderson",
        "Thomas",
        "Taylor",
        "Moore",
        "Jackson",
        "Martin",
        "Lee",
        "Perez",
        "Thompson",
        "White",
        "Harris",
        "Sanchez",
        "Clark",
        "Ramirez",
        "Lewis",
        "Robinson",
        "Walker",
        "Young",
        "Allen",
        "King",
        "Wright",
        "Scott",
        "Torres",
        "Nguyen",
        "Hill",
        "Flores",
        "Green",
        "Adams",
        "Nelson",
        "Baker",
        "Hall",
        "Rivera",
        "Campbell",
        "Mitchell",
        "Carter",
        "Roberts",
        "Gomez",
        "Phillips",
        "Evans",
        "Turner",
        "Diaz",
        "Parker",
        "Cruz",
        "Edwards",
        "Collins",
        "Reyes",
        "Stewart",
        "Morris",
        "Morales",
        "Murphy",
        "Cook",
        "Rogers",
        "Gutierrez",
        "Ortiz",
        "Morgan",
        "Cooper",
        "Peterson",
        "Bailey",
        "Reed",
        "Kelly",
        "Howard",
        "Ramos",
        "Kim",
        "Cox",
        "Ward",
        "Richardson",
        "Watson",
        "Brooks",
        "Chavez",
        "Wood",
        "James",
        "Bennett",
        "Gray",
        "Mendoza",
        "Ruiz",
        "Hughes",
        "Price",
        "Alvarez",
        "Castillo",
        "Sanders",
        "Patel",
        "Myers",
        "Long",
        "Ross",
        "Foster",
        "Jimenez",
        "Powell",
        "Jenkins",
        "Perry",
        "Russell",
        "Sullivan",
        "Bell",
        "Coleman",
        "Butler",
        "Henderson",
        "Barnes",
        "Gonzales",
        "Fisher",
        "Vasquez",
        "Simmons",
        "Romero",
        "Jordan",
        "Patterson",
        "Alexander",
        "Hamilton",
        "Graham",
        "Reynolds",
        "Griffin",
        "Wallace",
        "Moreno",
        "West",
        "Cole",
        "Hayes",
        "Bryant",
        "Herrera",
        "Gibson",
        "Ellis",
        "Tran",
        "Medina",
        "Aguilar",
        "Stevens",
        "Murray",
        "Ford",
        "Castro",
        "Marshall",
        "Owens",
        "Harrison",
        "Fernandez",
        "Mcdonald",
        "Woods",
        "Washington",
        "Kennedy",
        "Wells",
        "Vargas",
        "Henry",
        "Chen",
        "Freeman",
        "Webb",
        "Tucker",
        "Guzman",
        "Burns",
        "Crawford",
        "Olson",
        "Simpson",
        "Porter",
        "Hunter",
        "Gordon",
        "Mendez",
        "Silva",
        "Shaw",
        "Snyder",
        "Mason",
        "Dixon",
        "Muñoz",
        "Hunt",
        "Hicks",
        "Holmes",
        "Palmer",
        "Wagner",
        "Black",
        "Robertson",
        "Boyd",
        "Rose",
        "Stone",
        "Salazar",
        "Fox",
        "Warren",
        "Mills",
        "Meyer",
        "Rice",
        "Schmidt",
        "Garza",
        "Daniels",
        "Ferguson",
        "Nichols",
        "Stephens",
        "Soto",
        "Weaver",
        "Ryan",
        "Gardner",
        "Payne",
        "Grant",
        "Dunn",
        "Kelley",
        "Spencer",
        "Hawkins",
        "Arnold",
        "Pierce",
        "Vazquez",
        "Hansen",
        "Peters",
        "Santos",
        "Hart",
        "Bradley",
        "Knight",
        "Elliott",
        "Cunningham",
        "Duncan",
        "Armstrong",
        "Hudson",
        "Carroll",
        "Lane",
        "Riley",
        "Andrews",
        "Alvarado",
        "Ray",
        "Delgado",
        "Berry",
        "Perkins",
        "Hoffman",
        "Johnston",
        "Matthews",
        "Peña",
        "Richards",
        "Contreras",
        "Willis",
        "Carpenter",
        "Lawrence",
        "Sandoval",
        "Guerrero",
        "George",
        "Chapman",
        "Rios",
        "Estrada",
        "Ortega",
        "Watkins",
        "Greene",
        "Nuñez",
        "Wheeler",
        "Valdez",
        "Harper",
        "Burke",
        "Larson",
        "Santiago",
        "Maldonado",
        "Morrison",
        "Franklin",
        "Carlson",
        "Austin",
        "Dominguez",
        "Carr",
        "Lawson",
        "Jacobs",
        "O’Brien",
        "Lynch",
        "Singh",
        "Vega",
        "Bishop",
        "Montgomery",
        "Oliver",
        "Jensen",
        "Harvey",
        "Williamson",
        "Gilbert",
        "Dean",
        "Sims",
        "Espinoza",
        "Howell",
        "Li",
        "Wong",
        "Reid",
        "Hanson",
        "Le",
        "Mccoy",
        "Garrett",
        "Burton",
        "Fuller",
        "Wang",
        "Weber",
        "Welch",
        "Rojas",
        "Lucas",
        "Marquez",
        "Fields",
        "Park",
        "Yang",
        "Little",
        "Banks",
        "Padilla",
        "Day",
        "Walsh",
        "Bowman",
        "Schultz",
        "Luna",
        "Fowler",
        "Mejia",
        "Davidson",
        "Acosta",
        "Brewer",
        "May",
        "Holland",
        "Juarez",
        "Newman",
        "Pearson",
        "Curtis",
        "Cortéz",
        "Douglas",
        "Schneider",
        "Joseph",
        "Barrett",
        "Navarro",
        "Figueroa",
        "Keller",
        "Ávila",
        "Wade",
        "Molina",
        "Stanley",
        "Hopkins",
        "Campos",
        "Barnett",
        "Bates",
        "Chambers",
        "Caldwell",
        "Beck",
        "Lambert",
        "Miranda",
        "Byrd",
        "Craig",
        "Ayala",
        "Lowe",
        "Frazier",
        "Powers",
        "Neal",
        "Leonard",
        "Gregory",
        "Carrillo",
        "Sutton",
        "Fleming",
        "Rhodes",
        "Shelton",
        "Schwartz",
        "Norris",
        "Jennings",
        "Watts",
        "Duran",
        "Walters",
        "Cohen",
        "Mcdaniel",
        "Moran",
        "Parks",
        "Steele",
        "Vaughn",
        "Becker",
        "Holt",
        "Deleon",
        "Barker",
        "Terry",
        "Hale",
        "Leon",
        "Hail",
        "Benson",
        "Haynes",
        "Horton",
        "Miles",
        "Lyons",
        "Pham",
        "Graves",
        "Bush",
        "Thornton",
        "Wolfe",
        "Warner",
        "Cabrera",
        "Mckinney",
        "Mann",
        "Zimmerman",
        "Dawson",
        "Lara",
        "Fletcher",
        "Page",
        "Mccarthy",
        "Love",
        "Robles",
        "Cervantes",
        "Solis",
        "Erickson",
        "Reeves",
        "Chang",
        "Klein",
        "Salinas",
        "Fuentes",
        "Baldwin",
        "Daniel",
        "Simon",
        "Velasquez",
        "Hardy",
        "Higgins",
        "Aguirre",
        "Lin",
        "Cummings",
        "Chandler",
        "Sharp",
        "Barber",
        "Bowen",
        "Ochoa",
        "Dennis",
        "Robbins",
        "Liu",
        "Ramsey",
        "Francis",
        "Griffith",
        "Paul",
        "Blair",
        "O’Connor",
        "Cardenas",
        "Pacheco",
        "Cross",
        "Calderon",
        "Quinn",
        "Moss",
        "Swanson",
        "Chan",
        "Rivas",
        "Khan",
        "Rodgers",
        "Serrano",
        "Fitzgerald",
        "Rosales",
        "Stevenson",
        "Christensen",
        "Manning",
        "Gill",
        "Curry",
        "Mclaughlin",
        "Harmon",
        "Mcgee",
        "Gross",
        "Doyle",
        "Garner",
        "Newton",
        "Burgess",
        "Reese",
        "Walton",
        "Blake",
        "Trujillo",
        "Adkins",
        "Brady",
        "Goodman",
        "Roman",
        "Webster",
        "Goodwin",
        "Fischer",
        "Huang",
        "Potter",
        "Delacruz",
        "Montoya",
        "Todd",
        "Wu",
        "Hines",
        "Mullins",
        "Castaneda",
        "Malone",
        "Cannon",
        "Tate",
        "Mack",
        "Sherman",
        "Hubbard",
        "Hodges",
        "Zhang",
        "Guerra",
        "Wolf",
        "Valencia",
        "Saunders",
        "Franco",
        "Rowe",
        "Gallagher",
        "Farmer",
        "Hammond",
        "Hampton",
        "Townsend",
        "Ingram",
        "Wise",
        "Gallegos",
        "Clarke",
        "Barton",
        "Schroeder",
        "Maxwell",
        "Waters",
        "Logan",
        "Camacho",
        "Strickland",
        "Norman",
        "Person",
        "Colón",
        "Parsons",
        "Frank",
        "Harrington",
        "Glover",
        "Osborne",
        "Buchanan",
        "Casey",
        "Floyd",
        "Patton",
        "Ibarra",
        "Ball",
        "Tyler",
        "Suarez",
        "Bowers",
        "Orozco",
        "Salas",
        "Cobb",
        "Gibbs",
        "Andrade",
        "Bauer",
        "Conner",
        "Moody",
        "Escobar",
        "Mcguire",
        "Lloyd",
        "Mueller",
        "Hartman",
        "French",
        "Kramer",
        "Mcbride",
        "Pope",
        "Lindsey",
        "Velazquez",
        "Norton",
        "Mccormick",
        "Sparks",
        "Flynn",
        "Yates",
        "Hogan",
        "Marsh",
        "Macias",
        "Villanueva",
        "Zamora",
        "Pratt",
        "Stokes",
        "Owen",
        "Ballard",
        "Lang",
        "Brock",
        "Villarreal",
        "Charles",
        "Drake",
        "Barrera",
        "Cain",
        "Patrick",
        "Piñeda",
        "Burnett",
        "Mercado",
        "Santana",
        "Shepherd",
        "Bautista",
        "Ali",
        "Shaffer",
        "Lamb",
        "Trevino",
        "Mckenzie",
        "Hess",
        "Beil",
        "Olsen",
        "Cochran",
        "Morton",
        "Nash",
        "Wilkins",
        "Petersen",
        "Briggs",
        "Shah",
        "Roth",
        "Nicholson",
        "Holloway",
        "Lozano",
        "Rangel",
        "Flowers",
        "Hoover",
        "Short",
        "Arias",
        "Mora",
        "Valenzuela",
        "Bryan",
        "Meyers",
        "Weiss",
        "Underwood",
        "Bass",
        "Greer",
        "Summers",
        "Houston",
        "Carson",
        "Morrow",
        "Clayton",
        "Whitaker",
        "Decker",
        "Yoder",
        "Collier",
        "Zuniga",
        "Carey",
        "Wilcox",
        "Melendez",
        "Poole",
        "Roberson",
        "Larsen",
        "Conley",
        "Davenport",
        "Copeland",
        "Massey",
        "Lam",
        "Huff",
        "Rocha",
        "Cameron",
        "Jefferson",
        "Hood",
        "Monroe",
        "Anthony",
        "Pittman",
        "Huynh",
        "Randall",
        "Singleton",
        "Kirk",
        "Combs",
        "Mathis",
        "Christian",
        "Skinner",
        "Bradford",
        "Richard",
        "Galvan",
        "Wall",
        "Boone",
        "Kirby",
        "Wilkinson",
        "Bridges",
        "Bruce",
        "Atkinson",
        "Velez",
        "Meza",
        "Roy",
        "Vincent",
        "York",
        "Hodge",
        "Villa",
        "Abbott",
        "Allison",
        "Tapia",
        "Gates",
        "Chase",
        "Sosa",
        "Sweeney",
        "Farrell",
        "Wyatt",
        "Dalton",
        "Horn",
        "Barron",
        "Phelps",
        "Yu",
        "Dickerson",
        "Heath",
        "Foley",
        "Atkins",
        "Mathews",
        "Bonilla",
        "Acevedo",
        "Benitez",
        "Zavala",
        "Hensley",
        "Glenn",
        "Cisneros",
        "Harrell",
        "Shields",
        "Rubio",
        "Huffman",
        "Choi",
        "Boyer",
        "Garrison",
        "Arroyo",
        "Bond",
        "Kane",
        "Hancock",
        "Callahan",
        "Dillon",
        "Cline",
        "Wiggins",
        "Grimes",
        "Arellano",
        "Melton",
        "O’Neill",
        "Savage",
        "Ho",
        "Beltran",
        "Pitts",
        "Parrish",
        "Ponce",
        "Rich",
        "Booth",
        "Koch",
        "Golden",
        "Ware",
        "Brennan",
        "Mcdowell",
        "Marks",
        "Cantu",
        "Humphrey",
        "Baxter",
        "Sawyer",
        "Clay",
        "Tanner",
        "Hutchinson",
        "Kaur",
        "Berg",
        "Wiley",
        "Gilmore",
        "Russo",
        "Villegas",
        "Hobbs",
        "Keith",
        "Wilkerson",
        "Ahmed",
        "Beard",
        "Mcclain",
        "Montes",
        "Mata",
        "Rosario",
        "Vang",
        "Walter",
        "Henson",
        "O’Neal",
        "Mosley",
        "Mcclure",
        "Beasley",
        "Stephenson",
        "Snow",
        "Huerta",
        "Preston",
        "Vance",
        "Barry",
        "Johns",
        "Eaton",
        "Blackwell",
        "Dyer",
        "Prince",
        "Macdonald",
        "Solomon",
        "Guevara",
        "Stafford",
        "English",
        "Hurst",
        "Woodard",
        "Cortes",
        "Shannon",
        "Kemp",
        "Nolan",
        "Mccullough",
        "Merritt",
        "Murillo",
        "Moon",
        "Salgado",
        "Strong",
        "Kline",
        "Cordova",
        "Barajas",
        "Roach",
        "Rosas",
        "Winters",
        "Jacobson",
        "Lester",
        "Knox",
        "Bullock",
        "Kerr",
        "Leach",
        "Meadows",
        "Orr",
        "Davila",
        "Whitehead",
        "Pruitt",
        "Kent",
        "Conway",
        "Mckee",
        "Barr",
        "David",
        "Dejesus",
        "Marin",
        "Berger",
        "Mcintyre",
        "Blankenship",
        "Gaines",
        "Palacios",
        "Cuevas",
        "Bartlett",
        "Durham",
        "Dorsey",
        "Mccall",
        "O’Donnell",
        "Stein",
        "Browning",
        "Stout",
        "Lowery",
        "Sloan",
        "Mclean",
        "Hendricks",
        "Calhoun",
        "Sexton",
        "Chung",
        "Gentry",
        "Hull",
        "Duarte",
        "Ellison",
        "Nielsen",
        "Gillespie",
        "Buck",
        "Middleton",
        "Sellers",
        "Leblanc",
        "Esparza",
        "Hardin",
        "Bradshaw",
        "Mcintosh",
        "Howe",
        "Livingston",
        "Frost",
        "Glass",
        "Morse",
        "Knapp",
        "Herman",
        "Stark",
        "Bravo",
        "Noble",
        "Spears",
        "Weeks",
        "Frederick",
        "Buckley",
        "Mcfarland",
        "Hebert",
        "Enriquez",
        "Hickman",
        "Quintero",
        "Randolph",
        "Schaefer",
        "Walls",
        "Trejo",
        "House",
        "Reilly",
        "Pennington",
        "Michael",
        "Conrad",
        "Giles",
        "Benjamin",
        "Crosby",
        "Fitzpatrick",
        "Donovan",
        "Mays",
        "Mahoney",
        "Valentine",
        "Raymond",
        "Medrano",
        "Hahn",
        "Mcmillan",
        "Small",
        "Bentley",
        "Felix",
        "Peck",
        "Lucero",
        "Boyle",
        "Hanna",
        "Pace",
        "Rush",
        "Hurley",
        "Harding",
        "Mcconnell",
        "Bernal",
        "Nava",
        "Ayers",
        "Everett",
        "Ventura",
        "Avery",
        "Pugh",
        "Mayer",
        "Bender",
        "Shepard",
        "Mcmahon",
        "Landry",
        "Case",
        "Sampson",
        "Moses",
        "Magana",
        "Blackburn",
        "Dunlap",
        "Gould",
        "Duffy",
        "Vaughan",
        "Herring",
        "Mckay",
        "Espinosa",
        "Rivers",
        "Farley",
        "Bernard",
        "Ashley",
        "Friedman",
        "Potts",
        "Truong",
        "Costa",
        "Correa",
        "Blevins",
        "Nixon",
        "Clements",
        "Fry",
        "Delarosa",
        "Best",
        "Benton",
        "Lugo",
        "Portillo",
        "Dougherty",
        "Crane",
        "Haley",
        "Phan",
        "Villalobos",
        "Blanchard",
        "Horne",
        "Finley",
        "Quintana",
        "Lynn",
        "Esquivel",
        "Bean",
        "Dodson",
        "Mullen",
        "Xiong",
        "Hayden",
        "Cano",
        "Levy",
        "Huber",
        "Richmond",
        "Moyer",
        "Lim",
        "Frye",
        "Sheppard",
        "Mccarty",
        "Avalos",
        "Booker",
        "Waller",
        "Parra",
        "Woodward",
        "Jaramillo",
        "Krueger",
        "Rasmussen",
        "Brandt",
        "Peralta",
        "Donaldson",
        "Stuart",
        "Faulkner",
        "Maynard",
        "Galindo",
        "Coffey",
        "Estes",
        "Sanford",
        "Burch",
        "Maddox",
        "Vo",
        "O’Connell",
        "Vu",
        "Andersen",
        "Spence",
        "Mcpherson",
        "Church",
        "Schmitt",
        "Stanton",
        "Leal",
        "Cherry",
        "Compton",
        "Dudley",
        "Sierra",
        "Pollard",
        "Alfaro",
        "Hester",
        "Proctor",
        "Lu",
        "Hinton",
        "Novak",
        "Good",
        "Madden",
        "Mccann",
        "Terrell",
        "Jarvis",
        "Dickson",
        "Reyna",
        "Cantrell",
        "Mayo",
        "Branch",
        "Hendrix",
        "Rollins",
        "Rowland",
        "Whitney",
        "Duke",
        "Odom",
        "Daugherty",
        "Travis",
        "Tang",
        "Archer"
    }
end

function LLTEUtil.getAlienName()
    local _MethodName = "Get Alien Name"
    LLTEUtil.Log(_MethodName, "Beginning...")

    local _Rgen = ESCCUtil.getRand()
    local _Language = Language(Seed(_Rgen:getFloat(0.0, 1000000.0)))

    local _Gender = { "m", "f", "n" } --Male / Female / Nonbinary

    return { name = _Language:getName(), gender = _Gender[_Rgen:getInt(1, #_Gender)] }
end

--Should be a 50/50 shot of getting an alien or human name. Comes with a gender because polishing dialogues is worth it.
function LLTEUtil.getRandomName(_A, _H)
    local _MethodName = "Get Random Name"
    LLTEUtil.Log(_MethodName, "Beginning...")

    _A = _A or true
    _H = _H or true
    local _Rgen = ESCCUtil.getRand()

    local _NameTable = {}
    if _A then
        table.insert(_NameTable, self.getAlienName())
        LLTEUtil.Log(_MethodName, "Name Table has " .. tostring(#_NameTable) .. " entries")
    end
    if _H then
        local _HumanNames = self.getHumanNameTable()
        table.insert(_NameTable, _HumanNames[_Rgen:getInt(1, #_HumanNames)])
        LLTEUtil.Log(_MethodName, "Name Table has " .. tostring(#_NameTable) .. " entries")
    end
    LLTEUtil.Log(_MethodName, "Number of names in the main name table is: " .. tostring(#_NameTable))

    local _Name = _NameTable[_Rgen:getInt(1, #_NameTable)]
    _Name.pn1 = "they"
    _Name.pn2 = "them"
    _Name.pn3 = "their"
    _Name.ptense = "were"
    if _Name.gender == "m" then
        _Name.pn1 = "he"
        _Name.pn2 = "him"
        _Name.pn3 = "his"
        _Name.ptense = "was"
    elseif _Name.gender == "f" then
        _Name.pn1 = "she"
        _Name.pn2 = "her"
        _Name.pn3 = "her"
        _Name.ptense = "was"
    end

    return _Name
end

function LLTEUtil.getHumanFullName()
    local _Rgen = ESCCUtil.getRand()
    local _HumanFirstNames = self.getHumanNameTable()
    local _HumanLastNames = self.getLastNameTable()

    local _FirstName = _HumanFirstNames[_Rgen:getInt(1, #_HumanFirstNames)]
    local _LastName = _HumanLastNames[_Rgen:getInt(1, #_HumanLastNames)]

    return _FirstName.name .. " " .. _LastName
end

--endregion

--region #SHIP GENERATION

--An incredibly strong capital ship that uses a predetermined plan. Cannot be dropped below 2% HP. Withdraws at 15% HP.
function LLTEUtil.spawnBladeOfEmpress(_DeleteOnLeft)
    local _MethodName = "Spawn the Blade of the Empress"
    LLTEUtil.Log(_MethodName, "Beginning...")

    local _Faction =  Galaxy():findFaction("The Cavaliers")
    if not _Faction then
        LLTEUtil.Log(_MethodName, "Could not find Cavaliers", 1)
        return
    end
    local _Plan = LoadPlanFromFile("data/plans/cavaliersboss.xml")
    local _Scale = 3.5

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local shipName = "Blade of the Empress"
    local _EmpressBlade = Sector():createShip(_Faction, shipName, _Plan, PirateGenerator.getGenericPosition())
    _EmpressBlade.title = "Adriana's Flagship"
    _EmpressBlade.name = shipName

    ShipUtility.addBossAntiTorpedoEquipment(_EmpressBlade)
    ShipUtility.addScalableArtilleryEquipment(_EmpressBlade, 5, 1, false)
    ShipUtility.addScalableArtilleryEquipment(_EmpressBlade, 5, 1, false)

    local _Amp = 1
    local _ActiveMods = Mods()
    for _, _Xmod in pairs(_ActiveMods) do
        if _Xmod.id == "1821043731" then --HET
            _Amp = 2
            break
        end
    end

    _EmpressBlade.crew = _EmpressBlade.idealCrew
    _EmpressBlade:addScript("icon.lua", "data/textures/icons/pixel/cavaliers.png")

    local _WithdrawData = {
        _Threshold = 0.15,
        _Invincibility = 0.02,
        _WithdrawMessage = "I'll be back!"
    }

    _EmpressBlade:addScript("ai/withdrawatlowhealth.lua", _WithdrawData)
    _EmpressBlade:setValue("_llte_empressblade", true)
    _EmpressBlade:setValue("is_cavaliers", true)
    _EmpressBlade.damageMultiplier = (_EmpressBlade.damageMultiplier or 1) * 5 * _Amp

    Boarding(_EmpressBlade).boardable = false
    _EmpressBlade.dockable = false

    if _DeleteOnLeft then
        LLTEUtil.Log(_MethodName, "Deleting entity on player leaving...")
        MissionUT.deleteOnPlayersLeft(_EmpressBlade)
    else
        LLTEUtil.Log(_MethodName, "Entity will not be deleted on player leaving.")
    end
    return _EmpressBlade
end

--An extremely strong capital ship that uses a predetermined plan instead of the randomly genreated ones.
function LLTEUtil.spawnCavalierSupercap(_DeleteOnLeft)
    local _MethodName = "Spawn Cavaliers Supercap"
    LLTEUtil.Log(_MethodName, "Beginning...")

    local _Faction =  Galaxy():findFaction("The Cavaliers")
    if not _Faction then
        LLTEUtil.Log(_MethodName, "Could not find Cavaliers", 1)
        return
    end

    local _Plan = LoadPlanFromFile("data/plans/cavaliersboss.xml")
    local _Scale = 2.2

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local shipName = self.getCapitalShipName()
    local _SuperCap = Sector():createShip(_Faction, shipName, _Plan, PirateGenerator.getGenericPosition())
    _SuperCap.title = "Cavaliers Battleship"
    _SuperCap.name = shipName --Spawning the ship with the name pre-generated doesn't seem to work anymore, for some reason.

    ShipUtility.addBossAntiTorpedoEquipment(_SuperCap)
    ShipUtility.addScalableArtilleryEquipment(_SuperCap, 2, 1, false)
    ShipUtility.addScalableArtilleryEquipment(_SuperCap, 2, 1, false)

    local _Amp = 1
    local _ActiveMods = Mods()
    for _, _Xmod in pairs(_ActiveMods) do
        if _Xmod.id == "1821043731" then --HET
            _Amp = 2
            break
        end
    end

    _SuperCap.crew = _SuperCap.idealCrew
    _SuperCap:addScript("icon.lua", "data/textures/icons/pixel/flagship.png")
    _SuperCap:setValue("_llte_cav_supercap", true)
    _SuperCap:setValue("is_cavaliers", true)
    _SuperCap.damageMultiplier = (_SuperCap.damageMultiplier or 1) * 2 * _Amp

    Boarding(_SuperCap).boardable = false
    _SuperCap.dockable = false

    if _DeleteOnLeft then
        LLTEUtil.Log(_MethodName, "Deleting entity on player leaving...")
        MissionUT.deleteOnPlayersLeft(_SuperCap)
    else
        LLTEUtil.Log(_MethodName, "Entity will not be deleted on player leaving.")
    end
    return _SuperCap
end

--A boss pirate enemy :D
function LLTEUtil.spawnAnimosity(_PirateLevel, _AddLoot)
    local _MethodName = "Spawn Animosity"
    LLTEUtil.Log(_MethodName, "Beginning...")

    local _Faction = Galaxy():getPirateFaction(_PirateLevel)
    if not _Faction then
        LLTEUtil.Log(_MethodName, "Could not initialize Pirate Faction", 1)
        return
    end

    local _Plan = LoadPlanFromFile("data/plans/animosity.xml")
    local _Scale = 2

    _Plan:scale(vec3(_Scale, _Scale, _Scale))

    local shipName = "Animosity"
    local _Animosity = Sector():createShip(_Faction, shipName, _Plan, PirateGenerator.getGenericPosition())
    _Animosity.title = "Animosity"
    _Animosity.name = shipName

    ShipUtility.addScalableArtilleryEquipment(_Animosity, 5, 1, false)
    ShipUtility.addScalableArtilleryEquipment(_Animosity, 5, 1, false)

    local _Amp = 1
    local _ActiveMods = Mods()
    for _, _Xmod in pairs(_ActiveMods) do
        if _Xmod.id == "1821043731" then --HET
            _Amp = 2
            break
        end
    end

    _Animosity.crew = _Animosity.idealCrew
    _Animosity:addScript("icon.lua", "data/textures/icons/pixel/skull_big.png")
    _Animosity:addScript("secondaryweapons.lua")
    _Animosity:addScript("megablocker.lua", 1)
    _Animosity:setValue("is_animosity", true)
    _Animosity:setValue("is_pirate", true)
    _Animosity.damageMultiplier = (_Animosity.damageMultiplier or 1) * 4 * _Amp

    Boarding(_Animosity).boardable = false
    _Animosity.dockable = false

    if _AddLoot then
        --Yeah, this guy drops some really quality loot. I think that's okay since he's late-game and fairly dangerous.
        local SectorTurretGenerator = include ("sectorturretgenerator")
        local _X, _Y = Sector():getCoordinates()
        local _TurretGenerator = SectorTurretGenerator()
        local _Rgen = ESCCUtil.getRand()

        local _Loot = Loot(_Animosity.index)
        local _TurretCount = _Rgen:getInt(2, 4)
        for _ = 1, _TurretCount do
            _Loot:insert(InventoryTurret(_TurretGenerator:generate(_X, _Y, 0, Rarity(self.getRandomRarity()))))
        end
        _Loot:insert(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(self.getRandomRarity()), random():createSeed()))
        _Loot:insert(SystemUpgradeTemplate("data/scripts/systems/militarytcs.lua", Rarity(self.getRandomRarity()), random():createSeed()))

        _Animosity:addScriptOnce("internal/common/entity/background/legendaryloot.lua")
    end
    return _Animosity
end

function LLTEUtil.getRandomRarity()
    local _Raregen = ESCCUtil.getRand()
    if _Raregen:getInt(1, 10) <= 2 then
        return RarityType.Legendary
    else
        return RarityType.Exotic
    end
end

--endregion

function LLTEUtil.allCavaliersDepart()
    local _Ships = {Sector():getEntitiesByScriptValue("is_cavaliers")}
    local _Rgen = ESCCUtil.getRand()
    for _, _S in pairs(_Ships) do
        _S:addScriptOnce("entity/utility/delayeddelete.lua", _Rgen:getFloat(4, 8))
    end
end

function LLTEUtil.rebuildShipWeapons(_Ship, _Strength)
    if not _Strength or _Strength <= 1 then
        --We've already done the work on this in empressframeworkmission.lua. No reason to do it again.
        return
    end

    local _TurretTypes = {
        WeaponType.ChainGun, 
        WeaponType.Bolter, 
        WeaponType.Laser,
        WeaponType.TeslaGun,
        WeaponType.PulseCannon,
        WeaponType.Cannon,
        WeaponType.PlasmaGun,
        WeaponType.RocketLauncher,
        WeaponType.RailGun,
        WeaponType.LightningGun
    }
    
    local _ActiveMods = Mods()
    local _HETEnabled = false

    for _, _Xmod in pairs(_ActiveMods) do
        if _Xmod.id == "1821043731" then
            _HETEnabled = true
        end
    end

    if _HETEnabled then
        table.insert(_TurretTypes, WeaponType.HETBolter)
        table.insert(_TurretTypes, WeaponType.HETRailGun)
        table.insert(_TurretTypes, WeaponType.HETChainGun)
        table.insert(_TurretTypes, WeaponType.HETLaser)
        table.insert(_TurretTypes, WeaponType.HETSwarmMissiles)
        table.insert(_TurretTypes, WeaponType.HETCannon)
        table.insert(_TurretTypes, WeaponType.HETTeslaGun)
        table.insert(_TurretTypes, WeaponType.HETPredatorCannon)
        table.insert(_TurretTypes, WeaponType.HETInterceptor)
        table.insert(_TurretTypes, WeaponType.HETFlamethrower)
    end
     
    local _Sector = Sector()
    local _ClearTurrets = {_Ship:getTurrets()}
    for _, _Turret in pairs(_ClearTurrets) do
        _Sector:deleteEntity(_Turret)
    end
    
    local _Faction = Faction(_Ship.factionIndex)
    local _Turrets = Balancing_GetEnemySectorTurrets(_Sector:getCoordinates()) * 2 + 3
    _Turrets = _Turrets + _Turrets * math.max(0, _Faction:getTrait("careful") or 0) * 0.5
    local _Rgen = ESCCUtil.getRand()
 
    local _AddWeaponSets = 1
    if _Ship:getValue("is_heavy_defender") then
        _AddWeaponSets = 2
    end
     
    local _X, _Y = Balancing_GetSectorByTechLevel(self.getTechLevelByStrength(_Strength))
    local _Seed = Server().seed + _Faction.index
    local SectorTurretGenerator = include("sectorturretgenerator")
    local _TurretGen = SectorTurretGenerator(_Seed)
     
    for _ = 1, _AddWeaponSets do
        local _XWType = _TurretTypes[_Rgen:getInt(1, #_TurretTypes)]
        local _Turret = _TurretGen:generate(_X, _Y, 0, nil, _XWType)
        _Turret.coaxial = false
        if _XWType == WeaponType.RocketLauncher then
            local _TWeapons = {_Turret:getWeapons()}
            _Turret:clearWeapons()
            for _, _W in pairs(_TWeapons) do
                if _XWType == WeaponType.RocketLauncher then
                    _W.seeker = true
                end
                _Turret:addWeapon(_W)
            end
        end
        ShipUtility.addTurretsToCraft(_Ship, _Turret, _Turrets)
    end
end

function LLTEUtil.getTechLevelByStrength(_Strength)
    local _Table = {
        24,
        31,
        38,
        45,
        52
    }

    return _Table[_Strength]
end

function LLTEUtil.getSpecialRailguns()
    local _Rgen = ESCCUtil.getRand()

    local _TurretGen = include("SectorTurretGenerator")
    local _BaseTurretGen = include("TurretGenerator")
    local _EXCTurretGen = _TurretGen(Seed(1))

    local _Turret = _EXCTurretGen:generate(0, 0, 0, Rarity(RarityType.Legendary), WeaponType.RailGun)
    local _Weapons = {_Turret:getWeapons()}

    local _DamageFactor = _Rgen:getFloat(2.5, 2.75)
    local _ROFFactor = _Rgen:getFloat(1.7, 1.9)
    local _ReachFactor = _Rgen:getFloat(1.5, 1.75)
    local _PenFactor = _Rgen:getInt(22, 28)

    local _OverallFactor = _PenFactor + math.floor(((_DamageFactor + _ROFFactor + _ReachFactor) * 5))

    _Turret:clearWeapons()
    for _, _W in pairs(_Weapons) do
        _W.damage = _W.damage * _DamageFactor
        _W.fireDelay = _W.fireDelay / _ROFFactor
        _W.reach = _W.reach * _ReachFactor
        _W.bouterColor = ColorHSV(227, 0.72, 0.96)
        _W.binnerColor = ColorHSV(228, 0.72, 0.62)
        _W.blockPenetration = _PenFactor
        _W.bwidth = 1 --0.75
        _W.bauraWidth = 5 --4.5
        _W.hullDamageMultiplier = 1
        _W.damageType = DamageType.Physical
        _Turret:addWeapon(_W)
    end

    local _ShootingTime = 20
    local _CoolingTime = 4
    
    _BaseTurretGen.createStandardCooling(_Turret, _CoolingTime, _ShootingTime)

    _Turret.ancient = true
    _Turret.coaxial = false
    _Turret.slots = 2
    _Turret.size = 1.5
    _Turret.turningSpeed = 2.5
    _Turret.title = "CAV-WRG-EXCALIBUR-" .. tostring(_OverallFactor)
    _Turret.flavorText = "Everyone comes home alive, except for your enemies."
    
    return InventoryTurret(_Turret)
end

--region #LOGGING

function LLTEUtil.Log(_MethodName, _Msg, _OverrideDebug)
    local _LocalDebug = LLTEUtil._Debug or 0
    if _OverrideDebug == 1 then
        _LocalDebug = 1
    end

    if _LocalDebug == 1 then
        print("[LLTE Utility] - [" .. _MethodName .. "] - " .. _Msg)
    end
end

--endregion

return LLTEUtil