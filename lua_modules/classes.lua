-- lua_modules/classes.lua
-- Potato Archetypes and Class Tree for Potato War
-- Provides base stats (HP, mass, speed), arsenal configurations, and class active skills.

local M = {}

M.DEFAULT_CLASS_ID = "recruit"

M.CLASSES = {
	-- 0. Базовый класс (новобранец) - начальный класс для всех картошек
	recruit = {
		id = "recruit",
		name = "Новобранец",
		name_en = "Recruit",
		name_pt = "Recruta",
		name_fr = "Recrue",
		name_es = "Recluta",
		name_tr = "Acemi",
		branch = "base",
		tier = 0,
		star_cost = 0,
		parent_class = nil,
		desc = "Базовый универсальный боец. Надежен, неприхотлив и готов ко всему.",
		desc_en = "A basic all-round fighter. Reliable, undemanding and ready for anything.",
		desc_pt = "Um combatente básico e versátil. Confiável, sem frescuras e pronto para tudo.",
		desc_fr = "Un combattant polyvalent de base. Fiable, sans chichis et prêt à tout.",
		desc_es = "Un combatiente básico y versátil. Fiable, sin exigencias y listo para todo.",
		desc_tr = "Temel, çok yönlü bir savaşçı. Güvenilir, gösterişsiz ve her şeye hazır.",
		stats = {
			base_hp = 100,
			max_hp = 100,
			mass = 1.0,
			walk_speed_mult = 1.0,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 2,
			knife = 3,
		},
		active_skill = {
			id = "sprint",
			name = "Марш-бросок",
			name_en = "Sprint Dash",
			name_pt = "Arrancada",
			name_fr = "Sprint Éclair",
			name_es = "Carrera Relámpago",
			name_tr = "Hızlı Koşu",
			desc = "+40% скорости и импульса прыжка на текущий ход",
			desc_en = "+40% speed and jump impulse for the current turn",
			desc_pt = "+40% de velocidade e impulso de salto no turno atual",
			desc_fr = "+40 % de vitesse et d'impulsion de saut pour le tour en cours",
			desc_es = "+40 % de velocidad e impulso de salto durante el turno actual",
			desc_tr = "Bu tur için %40 hız ve zıplama itkisi",
			cooldown_turns = 2,
			icon = "hand",
			effect_type = "mobility",
		},
	},

	-- Ветвь 1: ШТУРМОВИК
	assault = {
		id = "assault",
		name = "Штурмовик",
		name_en = "Assault",
		name_pt = "Assalto",
		name_fr = "Assaut",
		name_es = "Asalto",
		name_tr = "Saldırı",
		branch = "assault",
		tier = 1,
		star_cost = 2,
		parent_class = "recruit",
		desc = "Мастер ближнего и среднего боя с автоматическим картофельным оружием.",
		desc_en = "A master of close and mid-range combat with automatic potato weapons.",
		desc_pt = "Mestre do combate de curta e média distância com armas automáticas de batata.",
		desc_fr = "Un maître du combat rapproché et à moyenne portée, armé de patates automatiques.",
		desc_es = "Maestro del combate cercano y medio con armas de patata automáticas.",
		desc_tr = "Otomatik patates silahlarıyla yakın ve orta mesafe dövüşün ustası.",
		stats = {
			base_hp = 110,
			max_hp = 110,
			mass = 1.05,
			walk_speed_mult = 1.05,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			burst = 4,
			shotgun = 3,
			knife = 2,
		},
		active_skill = {
			id = "rapid_fire",
			name = "Шквал огня",
			name_en = "Rapid Fire",
			name_pt = "Rajada",
			name_fr = "Tir Rapide",
			name_es = "Ráfaga",
			name_tr = "Seri Ateş",
			desc = "Мгновенно пополняет боезапас автомата на 2 очереди",
			desc_en = "Instantly refills the fry-gun ammo by 2 bursts",
			desc_pt = "Reabastece instantaneamente a munição da automática em 2 rajadas",
			desc_fr = "Réapprovisionne instantanément le chargeur de l'automatique de 2 rafales",
			desc_es = "Rellena al instante la munición de la automática con 2 ráfagas",
			desc_tr = "Otomatik silahın cephanesini anında 2 seri doldurur",
			cooldown_turns = 3,
			icon = "rifle",
			effect_type = "offensive",
		},
	},

	assault_2 = {
		id = "assault_2",
		name = "Штурмовик II",
		name_en = "Assault II",
		name_pt = "Assalto II",
		name_fr = "Assaut II",
		name_es = "Asalto II",
		name_tr = "Saldırı II",
		branch = "assault",
		tier = 2,
		star_cost = 4,
		parent_class = "assault",
		desc = "Закаленный ветеран штурма: бронированный клубень с увеличенным арсеналом.",
		desc_en = "A battle-hardened assault veteran: an armored tuber with an expanded arsenal.",
		desc_pt = "Veterano de assalto calejado: um tubérculo blindado com arsenal ampliado.",
		desc_fr = "Un vétéran de l'assaut endurci : un tubercule blindé à l'arsenal étoffé.",
		desc_es = "Un veterano de asalto curtido: un tubérculo blindado con arsenal ampliado.",
		desc_tr = "Savaşta pişmiş saldırı gazisi: cephaneliği genişletilmiş zırhlı yumru.",
		stats = {
			base_hp = 130,
			max_hp = 130,
			mass = 1.15,
			walk_speed_mult = 1.08,
			jump_mult = 1.05,
		},
		base_arsenal = {
			grenade = -1,
			burst = 6,
			shotgun = 5,
			knife = 4,
			molotov = 2,
		},
		active_skill = {
			id = "tactical_breach",
			name = "Тактический прорыв",
			name_en = "Tactical Breach",
			name_pt = "Rompimento Tático",
			name_fr = "Percée Tactique",
			name_es = "Brecha Táctica",
			name_tr = "Taktik Hamle",
			desc = "Временный щит от взрывов (-50% урона на 1 ход) и рывок вперед",
			desc_en = "A temporary blast shield (-50% damage for 1 turn) and a forward dash",
			desc_pt = "Escudo temporário contra explosões (-50% de dano por 1 turno) e uma investida à frente",
			desc_fr = "Bouclier temporaire contre les explosions (-50 % de dégâts pendant 1 tour) et une ruée en avant",
			desc_es = "Escudo temporal contra explosiones (-50 % de daño durante 1 turno) y una embestida hacia delante",
			desc_tr = "Patlamalara karşı geçici kalkan (1 tur boyunca %50 daha az hasar) ve ileri atılış",
			cooldown_turns = 3,
			icon = "crosshair",
			effect_type = "buff",
		},
	},

	sniper = {
		id = "sniper",
		name = "Снайпер",
		name_en = "Sniper",
		name_pt = "Atirador",
		name_fr = "Sniper",
		name_es = "Francotirador",
		name_tr = "Keskin Nişancı",
		branch = "assault",
		tier = 2,
		star_cost = 4,
		parent_class = "assault",
		desc = "Точный стрелок со шпажкой-снайпером. Легкий клубень для дальних дистанций.",
		desc_en = "A precise marksman with a sniper skewer. A light tuber for long range.",
		desc_pt = "Atirador preciso com espeto de precisão. Um tubérculo leve para longas distâncias.",
		desc_fr = "Un tireur précis armé d'une brochette sniper. Un tubercule léger pour les longues distances.",
		desc_es = "Un tirador preciso con brocheta francotiradora. Un tubérculo ligero para largas distancias.",
		desc_tr = "Şiş tüfeğiyle isabetli bir nişancı. Uzun mesafeler için hafif bir yumru.",
		stats = {
			base_hp = 90,
			max_hp = 90,
			mass = 0.85,
			walk_speed_mult = 1.0,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			rifle = 5,
			knife = 3,
		},
		active_skill = {
			id = "eagle_eye",
			name = "Орлиный глаз",
			name_en = "Eagle Eye",
			name_pt = "Olho de Águia",
			name_fr = "Œil d'Aigle",
			name_es = "Ojo de Águila",
			name_tr = "Kartal Gözü",
			desc = "Игнорирует воздействие ветра и увеличивает урон выстрела на 30%",
			desc_en = "Ignores wind and boosts shot damage by 30%",
			desc_pt = "Ignora o vento e aumenta o dano do tiro em 30%",
			desc_fr = "Ignore le vent et augmente les dégâts du tir de 30 %",
			desc_es = "Ignora el viento y aumenta el daño del disparo un 30 %",
			desc_tr = "Rüzgârı yok sayar ve atış hasarını %30 artırır",
			cooldown_turns = 2,
			icon = "skewer_dart",
			effect_type = "buff",
		},
	},

	-- Ветвь 2: САПЕР
	sapper = {
		id = "sapper",
		name = "Сапер",
		name_en = "Sapper",
		name_pt = "Sapador",
		name_fr = "Sapeur",
		name_es = "Zapador",
		name_tr = "Istihkâmcı",
		branch = "sapper",
		tier = 1,
		star_cost = 2,
		parent_class = "recruit",
		desc = "Специалист по пробитию грунта, бурению укреплений и созданию укрытий.",
		desc_en = "A specialist in breaching soil, drilling through fortifications and building cover.",
		desc_pt = "Especialista em perfurar o solo, furar fortificações e criar abrigos.",
		desc_fr = "Spécialiste du percement de terrain, du forage de fortifications et de la création d'abris.",
		desc_es = "Especialista en perforar el terreno, taladrar fortificaciones y crear refugios.",
		desc_tr = "Toprağı delme, tahkimatları sondajlama ve siper kurma uzmanı.",
		stats = {
			base_hp = 120,
			max_hp = 120,
			mass = 1.25,
			walk_speed_mult = 0.95,
			jump_mult = 0.95,
		},
		base_arsenal = {
			grenade = -1,
			drill = 4,
			garlic = 2,
			shotgun = 2,
			dynamite = 1,
		},
		active_skill = {
			id = "trench_dig",
			name = "Окоп",
			name_en = "Trench Fortify",
			name_pt = "Fortificar Trincheira",
			name_fr = "Tranchée Fortifiée",
			name_es = "Trinchera Fortificada",
			name_tr = "Siper Takviyesi",
			desc = "Быстро углубляется в грунт и снижает входящий урон на 35%",
			desc_en = "Quickly digs into the ground and reduces incoming damage by 35%",
			desc_pt = "Cava rapidamente o solo e reduz o dano recebido em 35%",
			desc_fr = "S'enfonce vite dans le sol et réduit les dégâts reçus de 35 %",
			desc_es = "Se atrinchera rápido en el suelo y reduce el daño recibido un 35 %",
			desc_tr = "Toprağa hızla gömülür ve gelen hasarı %35 azaltır",
			cooldown_turns = 3,
			icon = "drill_missile",
			effect_type = "buff",
		},
	},

	sapper_2 = {
		id = "sapper_2",
		name = "Сапер II",
		name_en = "Sapper II",
		name_pt = "Sapador II",
		name_fr = "Sapeur II",
		name_es = "Zapador II",
		name_tr = "Istihkâmcı II",
		branch = "sapper",
		tier = 2,
		star_cost = 4,
		parent_class = "sapper",
		desc = "Мастер подрывных работ и тяжелого бурения. Высокая масса и устойчивость.",
		desc_en = "A master of demolition and heavy drilling. High mass and sturdiness.",
		desc_pt = "Mestre em demolição e perfuração pesada. Grande massa e resistência.",
		desc_fr = "Maître des travaux de démolition et du forage lourd. Grande masse et robustesse.",
		desc_es = "Maestro de la demolición y la perforación pesada. Gran masa y resistencia.",
		desc_tr = "Yıkım ve ağır sondaj ustası. Yüksek kütle ve dayanıklılık.",
		stats = {
			base_hp = 140,
			max_hp = 140,
			mass = 1.35,
			walk_speed_mult = 0.95,
			jump_mult = 0.95,
		},
		base_arsenal = {
			grenade = -1,
			drill = 6,
			garlic = 4,
			beetle = 2,
			bazooka = 2,
			cluster = 2,
		},
		active_skill = {
			id = "cluster_trap",
			name = "Минная ловушка",
			name_en = "Mine Trap",
			name_pt = "Armadilha de Mina",
			name_fr = "Piège Miné",
			name_es = "Trampa Minada",
			name_tr = "Mayın Tuzağı",
			desc = "Устанавливает взрывчатку с таймером в точке стояния",
			desc_en = "Plants a timed explosive at the spot where it stands",
			desc_pt = "Planta um explosivo com temporizador no local onde está",
			desc_fr = "Pose un explosif à minuterie à l'endroit où il se tient",
			desc_es = "Coloca un explosivo con temporizador en el punto donde está",
			desc_tr = "Durduğu noktaya zamanlayıcılı bir patlayıcı yerleştirir",
			cooldown_turns = 3,
			icon = "tnt_barrel",
			effect_type = "offensive",
		},
	},

	commando = {
		id = "commando",
		name = "Командо",
		name_en = "Commando",
		name_pt = "Comando",
		name_fr = "Commando",
		name_es = "Comando",
		name_tr = "Komando",
		branch = "sapper",
		tier = 2,
		star_cost = 4,
		parent_class = "sapper",
		desc = "Диверсант и специалист по скрытным операциям. Высокая подвижность и нож.",
		desc_en = "A saboteur and stealth-ops specialist. High mobility and a knife.",
		desc_pt = "Sabotador e especialista em operações furtivas. Muita mobilidade e uma faca.",
		desc_fr = "Saboteur et spécialiste des opérations discrètes. Très mobile, armé d'un couteau.",
		desc_es = "Saboteador y especialista en operaciones sigilosas. Mucha movilidad y un cuchillo.",
		desc_tr = "Sabotajcı ve gizli operasyon uzmanı. Yüksek hareket kabiliyeti ve bıçak.",
		stats = {
			base_hp = 105,
			max_hp = 105,
			mass = 0.90,
			walk_speed_mult = 1.20,
			jump_mult = 1.15,
		},
		base_arsenal = {
			grenade = -1,
			knife = 6,
			burst = 4,
			molotov = 3,
			garlic = 2,
			dynamite = 1,
		},
		active_skill = {
			id = "smoke_screen",
			name = "Дымовая завеса",
			name_en = "Smoke Screen",
			name_pt = "Cortina de Fumaça",
			name_fr = "Écran de Fumée",
			name_es = "Cortina de Humo",
			name_tr = "Duman Perdesi",
			desc = "Рассеивает дым, снимает негативные статусы и совершает акробатический прыжок",
			desc_en = "Spreads smoke, removes negative statuses and performs an acrobatic leap",
			desc_pt = "Espalha fumaça, remove status negativos e faz um salto acrobático",
			desc_fr = "Disperse de la fumée, retire les statuts négatifs et exécute un saut acrobatique",
			desc_es = "Esparce humo, elimina los estados negativos y realiza un salto acrobático",
			desc_tr = "Duman yayar, olumsuz etkileri temizler ve akrobatik bir sıçrayış yapar",
			cooldown_turns = 2,
			icon = "smoke",
			effect_type = "cleanse",
		},
	},

	-- Ветвь 3: АРТИЛЛЕРИСТ
	artillery = {
		id = "artillery",
		name = "Артиллерист",
		name_en = "Artillery",
		name_pt = "Artilharia",
		name_fr = "Artillerie",
		name_es = "Artillería",
		name_tr = "Topçu",
		branch = "artillery",
		tier = 1,
		star_cost = 2,
		parent_class = "recruit",
		desc = "Специалист по навесной стрельбе и тяжелым взрывам из толкушки-базуки.",
		desc_en = "A specialist in lobbed fire and heavy blasts from the masher-bazooka.",
		desc_pt = "Especialista em tiro parabólico e grandes explosões com o amassador-bazuca.",
		desc_fr = "Spécialiste du tir en cloche et des grosses explosions avec le pilon-bazooka.",
		desc_es = "Especialista en tiro curvo y grandes explosiones con el machacador-bazuca.",
		desc_tr = "Havan atışı ve ezici-bazukayla ağır patlamalar uzmanı.",
		stats = {
			base_hp = 110,
			max_hp = 110,
			mass = 1.30,
			walk_speed_mult = 0.90,
			jump_mult = 0.90,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 4,
			garlic = 2,
			homing = 1,
		},
		active_skill = {
			id = "siege_stance",
			name = "Осадный режим",
			name_en = "Siege Stance",
			name_pt = "Modo de Cerco",
			name_fr = "Mode Siège",
			name_es = "Modo Asedio",
			name_tr = "Kuşatma Duruşu",
			desc = "+35% к силе выстрела и радиусу взрыва следующего снаряда",
			desc_en = "+35% shot power and blast radius for the next projectile",
			desc_pt = "+35% de força de tiro e de raio de explosão no próximo projétil",
			desc_fr = "+35 % de puissance de tir et de rayon d'explosion pour le prochain projectile",
			desc_es = "+35 % de potencia de disparo y de radio de explosión en el próximo proyectil",
			desc_tr = "Sonraki mermi için %35 atış gücü ve patlama yarıçapı",
			cooldown_turns = 3,
			icon = "masher_bazooka",
			effect_type = "buff",
		},
	},

	artillery_2 = {
		id = "artillery_2",
		name = "Артиллерист II",
		name_en = "Artillery II",
		name_pt = "Artilharia II",
		name_fr = "Artillerie II",
		name_es = "Artillería II",
		name_tr = "Topçu II",
		branch = "artillery",
		tier = 2,
		star_cost = 4,
		parent_class = "artillery",
		desc = "Тяжелая осадная батарея: колоссальная разрушительная сила и воронки.",
		desc_en = "A heavy siege battery: colossal destructive power and craters.",
		desc_pt = "Bateria de cerco pesada: poder destrutivo colossal e crateras.",
		desc_fr = "Une lourde batterie de siège : puissance destructrice colossale et cratères.",
		desc_es = "Una pesada batería de asedio: poder destructivo colosal y cráteres.",
		desc_tr = "Ağır kuşatma bataryası: devasa yıkım gücü ve kraterler.",
		stats = {
			base_hp = 125,
			max_hp = 125,
			mass = 1.40,
			walk_speed_mult = 0.85,
			jump_mult = 0.85,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 6,
			airstrike = 1,
			holy_grenade = 1,
		},
		active_skill = {
			id = "carpet_salvo",
			name = "Артналет",
			name_en = "Artillery Salvo",
			name_pt = "Salva de Artilharia",
			name_fr = "Salve d'Artillerie",
			name_es = "Salva de Artillería",
			name_tr = "Topçu Yaylımı",
			desc = "Запрашивает сброс авиабомбы в точку прицела",
			desc_en = "Calls in an air bomb drop on the aimed spot",
			desc_pt = "Solicita o lançamento de uma bomba aérea no ponto de mira",
			desc_fr = "Appelle un largage de bombe aérienne sur le point visé",
			desc_es = "Solicita el lanzamiento de una bomba aérea en el punto de mira",
			desc_tr = "Nişan noktasına hava bombası atılmasını ister",
			cooldown_turns = 4,
			icon = "air_bomb",
			effect_type = "offensive",
		},
	},

	rocketeer = {
		id = "rocketeer",
		name = "Ракетчик",
		name_en = "Rocketeer",
		name_pt = "Foguetista",
		name_fr = "Fuséen",
		name_es = "Cohetero",
		name_tr = "Roketçi",
		branch = "artillery",
		tier = 2,
		star_cost = 4,
		parent_class = "artillery",
		desc = "Мобильный стрелок реактивными снарядами, преодолевающий любые высоты.",
		desc_en = "A mobile rocket shooter who clears any height.",
		desc_pt = "Atirador móvel de foguetes que supera qualquer altura.",
		desc_fr = "Un tireur de roquettes mobile qui franchit toutes les hauteurs.",
		desc_es = "Un tirador de cohetes móvil que supera cualquier altura.",
		desc_tr = "Her yüksekliği aşan, hareketli bir roket atıcı.",
		stats = {
			base_hp = 95,
			max_hp = 95,
			mass = 0.80,
			walk_speed_mult = 1.10,
			jump_mult = 1.25,
		},
		base_arsenal = {
			grenade = -1,
			bazooka = 5,
			homing = 2,
			drill = 3,
			burst = 2,
		},
		active_skill = {
			id = "rocket_jump",
			name = "Ракетный прыжок",
			name_en = "Rocket Jump",
			name_pt = "Salto-Foguete",
			name_fr = "Saut à la Roquette",
			name_es = "Salto Cohete",
			name_tr = "Roket Zıplaması",
			desc = "Высокий реактивный прыжок через горы и стены без урона для себя",
			desc_en = "A high rocket jump over mountains and walls without hurting yourself",
			desc_pt = "Um alto salto-foguete sobre montanhas e muros sem se machucar",
			desc_fr = "Un grand saut à la roquette par-dessus montagnes et murs, sans se blesser",
			desc_es = "Un gran salto cohete sobre montañas y muros sin hacerse daño",
			desc_tr = "Dağların ve duvarların üzerinden, kendine zarar vermeden yüksek roket zıplaması",
			cooldown_turns = 2,
			icon = "spark",
			effect_type = "mobility",
		},
	},

	-- Ветвь 4: МЕДИК
	medic = {
		id = "medic",
		name = "Медик",
		name_en = "Medic",
		name_pt = "Médico",
		name_fr = "Médic",
		name_es = "Médico",
		name_tr = "Sağlıkçı",
		branch = "medic",
		tier = 1,
		star_cost = 2,
		parent_class = "recruit",
		desc = "Полевой санитар: лечит союзников, очищает дебаффы и травит врагов перцем.",
		desc_en = "A field medic: heals allies, cleanses debuffs and poisons enemies with pepper.",
		desc_pt = "Paramédico de campo: cura aliados, remove debuffs e envenena inimigos com pimenta.",
		desc_fr = "Infirmier de terrain : soigne ses alliés, purge les débuffs et empoisonne les ennemis au piment.",
		desc_es = "Sanitario de campo: cura aliados, limpia debuffs y envenena enemigos con pimienta.",
		desc_tr = "Sahra sağlıkçısı: müttefikleri iyileştirir, zayıflatmaları temizler, düşmanları biberle zehirler.",
		stats = {
			base_hp = 105,
			max_hp = 105,
			mass = 1.0,
			walk_speed_mult = 1.05,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			pepper = 4,
			molotov = 2,
			shotgun = 2,
		},
		active_skill = {
			id = "first_aid",
			name = "Полевая аптечка",
			name_en = "Field Aid",
			name_pt = "Primeiros Socorros",
			name_fr = "Soins de Terrain",
			name_es = "Primeros Auxilios",
			name_tr = "Sahra Müdahalesi",
			desc = "Исцеляет +35 HP бойцу и очищает эффекты горения и яда",
			desc_en = "Heals a fighter for +35 HP and clears burning and poison effects",
			desc_pt = "Cura +35 HP de um combatente e remove os efeitos de queimadura e veneno",
			desc_fr = "Soigne un combattant de +35 PV et retire les effets de brûlure et de poison",
			desc_es = "Cura +35 HP a un combatiente y elimina los efectos de quemadura y veneno",
			desc_tr = "Bir savaşçıyı +35 HP iyileştirir ve yanma ile zehir etkilerini temizler",
			cooldown_turns = 2,
			icon = "circle",
			effect_type = "heal",
		},
	},

	surgeon = {
		id = "surgeon",
		name = "Хирург",
		name_en = "Surgeon",
		name_pt = "Cirurgião",
		name_fr = "Chirurgien",
		name_es = "Cirujano",
		name_tr = "Cerrah",
		branch = "medic",
		tier = 2,
		star_cost = 4,
		parent_class = "medic",
		desc = "Главврач картофельного госпиталя: мощное лечение, святая реанимация и биогель.",
		desc_en = "Chief physician of the potato hospital: powerful healing, holy resuscitation and biogel.",
		desc_pt = "Médico-chefe do hospital das batatas: cura poderosa, reanimação santa e biogel.",
		desc_fr = "Médecin-chef de l'hôpital des patates : soins puissants, réanimation sacrée et biogel.",
		desc_es = "Médico jefe del hospital patatero: curación poderosa, reanimación santa y biogel.",
		desc_tr = "Patates hastanesinin başhekimi: güçlü iyileştirme, kutsal canlandırma ve biyojel.",
		stats = {
			base_hp = 120,
			max_hp = 120,
			mass = 1.05,
			walk_speed_mult = 1.05,
			jump_mult = 1.0,
		},
		base_arsenal = {
			grenade = -1,
			pepper = 6,
			holy_grenade = 1,
			knife = 4,
			molotov = 3,
		},
		active_skill = {
			id = "biogel_surge",
			name = "Биогель / Реанимация",
			name_en = "Biogel Surge",
			name_pt = "Surto de Biogel",
			name_fr = "Poussée de Biogel",
			name_es = "Oleada de Biogel",
			name_tr = "Biyojel Dalgası",
			desc = "Исцеляет +50 HP, полностью снимает все негативные статусы и активирует регенерацию",
			desc_en = "Heals +50 HP, fully removes all negative statuses and activates regeneration",
			desc_pt = "Cura +50 HP, remove todos os status negativos e ativa a regeneração",
			desc_fr = "Soigne +50 PV, retire tous les statuts négatifs et active la régénération",
			desc_es = "Cura +50 HP, elimina por completo los estados negativos y activa la regeneración",
			desc_tr = "+50 HP iyileştirir, tüm olumsuz etkileri tamamen kaldırır ve yenilenmeyi başlatır",
			cooldown_turns = 3,
			icon = "holy_spud",
			effect_type = "heal",
		},
	},

	-- Ветвь 5: ТАНК
	tank = {
		id = "tank",
		name = "Танк",
		name_en = "Tank",
		name_pt = "Tanque",
		name_fr = "Char",
		name_es = "Tanque",
		name_tr = "Tank",
		branch = "tank",
		tier = 1,
		star_cost = 2,
		parent_class = "recruit",
		desc = "Тяжелобронированный рыцарь-клубень со щитом и боевым топором. Несгибаемая стойкость.",
		desc_en = "A heavily armored knight-tuber with a shield and battle axe. Unbending resilience.",
		desc_pt = "Cavaleiro-tubérculo fortemente blindado com escudo e machado de batalha. Resistência inabalável.",
		desc_fr = "Un chevalier-tubercule lourdement blindé, avec bouclier et hache de guerre. Une endurance inflexible.",
		desc_es = "Un caballero-tubérculo muy blindado con escudo y hacha de combate. Resistencia inquebrantable.",
		desc_tr = "Kalkanlı ve savaş baltalı, ağır zırhlı şövalye yumru. Eğilmez dayanıklılık.",
		stats = {
			base_hp = 150,
			max_hp = 150,
			mass = 1.60,
			walk_speed_mult = 0.85,
			jump_mult = 0.80,
		},
		base_arsenal = {
			grenade = -1,
			knife = 5,
			shotgun = 3,
			bazooka = 2,
		},
		active_skill = {
			id = "iron_bastion",
			name = "Стальной бастион",
			name_en = "Iron Bastion",
			name_pt = "Bastião de Ferro",
			name_fr = "Bastion de Fer",
			name_es = "Bastión de Hierro",
			name_tr = "Demir Kale",
			desc = "Поднимает щит: -50% получаемого урона на 1 ход и полная устойчивость к отбрасыванию",
			desc_en = "Raises a shield: -50% damage taken for 1 turn and full knockback immunity",
			desc_pt = "Ergue o escudo: -50% de dano recebido por 1 turno e imunidade total a repulsão",
			desc_fr = "Lève le bouclier : -50 % de dégâts subis pendant 1 tour et immunité totale au recul",
			desc_es = "Alza el escudo: -50 % de daño recibido durante 1 turno e inmunidad total al retroceso",
			desc_tr = "Kalkanı kaldırır: 1 tur boyunca %50 daha az hasar ve geri savrulmaya tam bağışıklık",
			cooldown_turns = 3,
			icon = "knife",
			effect_type = "buff",
		},
	},
}

-- Potato body art of each class (atlas images in main/assets/game.atlas)
M.SPRITES = {
	recruit = "recruit",
	assault = "assault",
	assault_2 = "assault",
	sniper = "sniper",
	sapper = "sapper",
	sapper_2 = "sapper",
	commando = "sapper",
	artillery = "tank",
	artillery_2 = "tank",
	rocketeer = "tank",
	medic = "medic",
	surgeon = "medic",
	engineer = "sapper",
	tank = "tank",
}

function M.sprite_of(class_id)
	return M.SPRITES[class_id] or "recruit"
end

-- Fast lookup / query helpers
function M.get(class_id)
	return M.CLASSES[class_id] or M.CLASSES[M.DEFAULT_CLASS_ID]
end

function M.get_default()
	return M.CLASSES[M.DEFAULT_CLASS_ID]
end

function M.get_star_cost(class_id)
	local c = M.get(class_id)
	return (c and c.star_cost) or 0
end

-- Pool of specialized classes (excluding 'recruit') for quick match / skirmish randomization
M.NON_RECRUIT_CLASS_IDS = {
	"assault", "assault_2", "sniper",
	"sapper", "sapper_2", "commando",
	"artillery", "artillery_2", "rocketeer",
	"medic", "surgeon", "tank"
}

function M.get_random_specialized_class()
	return M.NON_RECRUIT_CLASS_IDS[math.random(1, #M.NON_RECRUIT_CLASS_IDS)]
end

function M.list()
	local result = {}
	for _, c in pairs(M.CLASSES) do
		table.insert(result, c)
	end
	table.sort(result, function(a, b)
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		return a.id < b.id
	end)
	return result
end

function M.get_by_branch(branch)
	local result = {}
	for _, c in pairs(M.CLASSES) do
		if c.branch == branch then
			table.insert(result, c)
		end
	end
	return result
end

function M.get_promotions(class_id)
	local result = {}
	for _, c in pairs(M.CLASSES) do
		if c.parent_class == class_id then
			table.insert(result, c)
		end
	end
	return result
end

-- Extensible registration API: allows registering new custom archetypes at runtime
function M.register(class_def)
	if not class_def or not class_def.id then
		return false
	end
	class_def.stats = class_def.stats or { base_hp = 100, max_hp = 100, mass = 1.0, walk_speed_mult = 1.0, jump_mult = 1.0 }
	class_def.base_arsenal = class_def.base_arsenal or { grenade = -1 }
	M.CLASSES[class_def.id] = class_def
	return true
end

return M
