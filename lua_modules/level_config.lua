-- lua_modules/level_config.lua
-- Central configuration module for Potato War levels:
-- Level number, enemy HP, enemy count, terrain type, enemy skill level, and biome themes.

local i18n = require("lua_modules.i18n")

local M = {}

-- Supported terrain types and default biomes
M.TERRAIN_TYPES = {
	HILLS = "hills",
	FLOATING_ISLANDS = "floating_islands",
	CANYON_BRIDGE = "canyon_bridge",
	CAVERN = "cavern",
	SWISS_CHEESE = "swiss_cheese",
	BUNKERS = "bunkers",
	ISLANDS = "islands",
	FLAT = "flat",
}

-- Supported enemy skill levels
M.SKILL_LEVELS = {
	EASY = "easy",
	NORMAL = "normal",
	HARD = "hard",
}

-- Deduce biome theme based on terrain type if not explicitly set
function M.deduce_biome(terrain_type)
	if terrain_type == "canyon" or terrain_type == "canyon_bridge" or terrain_type == "bunkers" then
		return "desert"
	elseif terrain_type == "floating_islands" then
		return "arctic"
	elseif terrain_type == "cavern" then
		return "volcano"
	elseif terrain_type == "swiss_cheese" then
		return "alien"
	else
		return "grass"
	end
end

-- Normalize skill level from various formats (number 1-3, strings, Russian terms)
function M.normalize_skill(skill)
	if type(skill) == "number" then
		if skill <= 1 then
			return "easy"
		elseif skill == 2 then
			return "normal"
		else
			return "hard"
		end
	end

	if type(skill) == "string" then
		local s = string.lower(skill)
		if s == "easy" or s == "легкий" or s == "лёгкий" or s == "fácil" or s == "facil" or s == "fácil" or s == "kolay" or s == "1" then
			return "easy"
		elseif s == "hard" or s == "сложный" or s == "тяжелый" or s == "тяжёлый" or s == "expert" or s == "difícil" or s == "dificil" or s == "difficile" or s == "difícil" or s == "zor" or s == "3" then
			return "hard"
		else
			return "normal"
		end
	end

	return "normal"
end

-- Normalize a single level configuration entry with all aliases and fallback defaults
function M.normalize_level(entry, level_index)
	local lvl = entry.level or entry.id or level_index or 1
	local terrain = entry.terrain_type or entry.terrain_preset or "hills"
	local biome = entry.biome or M.deduce_biome(terrain)
	local skill = M.normalize_skill(entry.enemy_skill or entry.bot_difficulty or entry.skill_level or "normal")

	local enemy_cnt = entry.enemy_count or entry.red_count or 1
	local player_cnt = entry.player_count or entry.blue_count or 1

	-- Normalize enemy HP (can be number or table per enemy)
	local enemy_hp = entry.enemy_hp
	if enemy_hp == nil then
		enemy_hp = (lvl == 1) and 85 or 100
	end

	-- Normalize enemy classes and unit levels (ranks)
	local enemy_classes = entry.enemy_classes
	if not enemy_classes or #enemy_classes == 0 then
		enemy_classes = {}
		for i = 1, enemy_cnt do
			table.insert(enemy_classes, "recruit")
		end
	end

	local enemy_levels = entry.enemy_levels
	if not enemy_levels or #enemy_levels == 0 then
		enemy_levels = {}
		for i = 1, enemy_cnt do
			table.insert(enemy_levels, 1)
		end
	end

	local sector_prefix = i18n.pick({ ru = "Сектор ", en = "Sector ", pt = "Setor ", fr = "Secteur ", es = "Sector ", tr = "Sektör " })
	local lvl_name = i18n.field(entry, "name")
	if lvl_name == nil or lvl_name == "" then lvl_name = sector_prefix .. tostring(lvl) end
	local lvl_desc = i18n.field(entry, "desc") or ""

	return {
		level = lvl,
		id = lvl,
		name = lvl_name,
		desc = lvl_desc,
		name_ru = entry.name_ru or entry.name,
		name_en = entry.name_en or entry.name,
		desc_ru = entry.desc_ru or entry.desc,
		desc_en = entry.desc_en or entry.desc,
		name_pt = entry.name_pt, name_fr = entry.name_fr, name_es = entry.name_es, name_tr = entry.name_tr,
		desc_pt = entry.desc_pt, desc_fr = entry.desc_fr, desc_es = entry.desc_es, desc_tr = entry.desc_tr,
		enemy_hp = enemy_hp,
		enemy_count = enemy_cnt,
		red_count = enemy_cnt, -- Backwards compatibility alias
		player_count = player_cnt,
		blue_count = player_cnt, -- Backwards compatibility alias
		terrain_type = terrain,
		terrain_preset = terrain, -- Backwards compatibility alias
		biome = biome,
		enemy_skill = skill,
		bot_difficulty = skill, -- Backwards compatibility alias
		skill_level = skill, -- Backwards compatibility alias
		enemy_classes = enemy_classes,
		enemy_levels = enemy_levels,
	}
end

-- Campaign levels table: All 18 campaign sectors
-- Parameters per level:
--   level: номер сектора/уровня (1..18)
--   name / name_en: названия сектора
--   desc / desc_en: тактическое описание
--   enemy_count: количество врагов (1..4)
--   enemy_hp: здоровье врагов (число или таблица { hp1, hp2, ... })
--   enemy_classes: таблица классов вражеских картошек ({ "recruit", "assault", ... })
--   enemy_levels: уровни/ранги врагов ({ 1, 2, ... })
--   terrain_type: тип террейна
--   biome: визуальный биом ("grass", "desert", "arctic", "volcano")
--   enemy_skill: точность/тактика ИИ ("easy", "normal", "hard")
M.LEVELS = {
	-- =========================================================================
	-- РЕГИОН 1: ПРИБРЕЖНЫЕ ЛУГА (Coastal Meadows) - Уровни 1..4 (Grass Biome)
	-- =========================================================================
	{
		level = 1,
		name = "Бухта Высадки",
		name_en = "Landing Cove",
		name_pt = "Enseada do Desembarque",
		name_fr = "Crique du Débarquement",
		name_es = "Cala del Desembarco",
		name_tr = "Çıkarma Koyu",
		desc = "Первая высадка десанта. Одинокий часовой-новобранец охраняет берег.",
		desc_en = "Beachhead landing. A lone rookie sentry patrols the sandy shores.",
		desc_pt = "Desembarque na praia. Uma sentinela novata e solitária patrulha as areias.",
		desc_fr = "Débarquement sur la plage. Une sentinelle novice et solitaire patrouille sur le sable.",
		desc_es = "Desembarco en la playa. Un centinela novato y solitario patrulla la arena.",
		desc_tr = "Sahile çıkarma. Yalnız bir acemi nöbetçi kumsalda dolaşıyor.",
		enemy_count = 1,
		enemy_hp = { 100 },
		enemy_classes = { "recruit" },
		enemy_levels = { 1 },
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "easy",
	},
	{
		level = 2,
		name = "Зеленые Холмы",
		name_en = "Green Hills",
		name_pt = "Colinas Verdes",
		name_fr = "Collines Vertes",
		name_es = "Colinas Verdes",
		name_tr = "Yeşil Tepeler",
		desc = "Холмистый рубеж. Разведчик-штурмовик занял позицию на возвышенности.",
		desc_en = "Rolling hills frontier. An assault scout holds high ground.",
		desc_pt = "Fronteira de colinas ondulantes. Um batedor de assalto domina o terreno elevado.",
		desc_fr = "Frontière de collines ondulées. Un éclaireur d'assaut tient les hauteurs.",
		desc_es = "Frontera de colinas ondulantes. Un explorador de asalto domina la altura.",
		desc_tr = "Dalgalı tepelerin sınırı. Bir saldırı izcisi yüksek zemini tutuyor.",
		enemy_count = 2,
		enemy_hp = { 100, 95 },
		enemy_classes = { "assault", "recruit" },
		enemy_levels = { 1, 1 },
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "easy",
	},
	{
		level = 3,
		name = "Изумрудная Долина",
		name_en = "Emerald Valley",
		name_pt = "Vale Esmeralda",
		name_fr = "Vallée d'Émeraude",
		name_es = "Valle Esmeralda",
		name_tr = "Zümrüt Vadisi",
		desc = "Передовой парный патруль: штурмовик и сапер минируют подходы.",
		desc_en = "Forward patrol pair: assault spud and sapper laying obstacles.",
		desc_pt = "Dupla de patrulha avançada: uma batata de assalto e um sapador espalhando obstáculos.",
		desc_fr = "Duo de patrouille avancée : une patate d'assaut et un sapeur qui sème des obstacles.",
		desc_es = "Pareja de patrulla avanzada: una patata de asalto y un zapador sembrando obstáculos.",
		desc_tr = "İleri devriye ikilisi: bir saldırı patatesi ve engel döşeyen bir istihkâmcı.",
		enemy_count = 2,
		enemy_hp = { 110, 105 },
		enemy_classes = { "assault", "sapper" },
		enemy_levels = { 1, 1 },
		terrain_type = "hills",
		biome = "grass",
		enemy_skill = "normal",
	},
	{
		level = 4,
		name = "Маяк Спокойствия",
		name_en = "Tranquil Lighthouse",
		name_pt = "Farol da Tranquilidade",
		name_fr = "Phare de la Tranquillité",
		name_es = "Faro de la Tranquilidad",
		name_tr = "Huzur Feneri",
		desc = "Островной маяк у берега. Снайпер прикрывает сапера над пропастью.",
		desc_en = "Coastal lighthouse isle. A sniper covers a fortification sapper.",
		desc_pt = "Ilhota do farol costeiro. Um franco-atirador protege um sapador de fortificações.",
		desc_fr = "Îlot du phare côtier. Un tireur d'élite couvre un sapeur de fortifications.",
		desc_es = "Islote del faro costero. Un francotirador cubre a un zapador de fortificaciones.",
		desc_tr = "Kıyıdaki fener adası. Bir keskin nişancı, tahkimat yapan bir istihkâmcıyı koruyor.",
		enemy_count = 2,
		enemy_hp = { 115, 110 },
		enemy_classes = { "sniper", "sapper" },
		enemy_levels = { 1, 1 },
		terrain_type = "islands",
		biome = "grass",
		enemy_skill = "normal",
	},

	-- =========================================================================
	-- РЕГИОН 2: ПУСТЫННЫЙ КАНЬОН (Desert Canyon) - Уровни 5..9 (Desert Biome)
	-- =========================================================================
	{
		level = 5,
		name = "Песчаные Дюны",
		name_en = "Sandy Dunes",
		name_pt = "Dunas Arenosas",
		name_fr = "Dunes de Sable",
		name_es = "Dunas Arenosas",
		name_tr = "Kum Tepeleri",
		desc = "Горячие дюны. Штурмовик при поддержке полевого медика держат оборону.",
		desc_en = "Blistering dunes. An assault backed by a combat medic holds the line.",
		desc_pt = "Dunas escaldantes. Um soldado de assalto apoiado por um médico de combate segura a linha.",
		desc_fr = "Dunes brûlantes. Un assaillant soutenu par un médecin de combat tient la ligne.",
		desc_es = "Dunas abrasadoras. Un asaltante con apoyo de un médico de combate mantiene la línea.",
		desc_tr = "Kavurucu kum tepeleri. Savaş sahası sağlıkçısı destekli bir saldırı eri cepheyi tutuyor.",
		enemy_count = 3,
		enemy_hp = { 110, 105, 100 },
		enemy_classes = { "assault", "medic", "sapper" },
		enemy_levels = { 1, 1, 1 },
		terrain_type = "flat",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 6,
		name = "Каньон Эхо",
		name_en = "Echo Canyon",
		name_pt = "Cânion do Eco",
		name_fr = "Canyon de l'Écho",
		name_es = "Cañón del Eco",
		name_tr = "Yankı Kanyonu",
		desc = "Глубокая пропасть. Трио врагов ведет перекрестный навесной обстрел.",
		desc_en = "Chasm depths. Enemy trio raining mortar fire across the chasm.",
		desc_pt = "Profundezas do abismo. Um trio inimigo faz chover tiros de morteiro por cima do desfiladeiro.",
		desc_fr = "Profondeurs du gouffre. Un trio ennemi fait pleuvoir des tirs de mortier au-dessus du ravin.",
		desc_es = "Profundidades del abismo. Un trío enemigo lanza una lluvia de morteros sobre el barranco.",
		desc_tr = "Uçurumun derinlikleri. Düşman üçlüsü uçurumun üzerine havan yağdırıyor.",
		enemy_count = 3,
		enemy_hp = { 85, 85, 85 },
		enemy_classes = { "artillery", "assault", "sapper" },
		enemy_levels = { 1, 1, 1 },
		terrain_type = "canyon_bridge",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 7,
		name = "Пыльный Перекресток",
		name_en = "Dusty Crossroads",
		name_pt = "Encruzilhada Empoeirada",
		name_fr = "Carrefour Poussiéreux",
		name_es = "Cruce Polvoriento",
		name_tr = "Tozlu Kavşak",
		desc = "Изрытая катакомбами земля. Снайпер и тяжелый сапер стерегут развилку.",
		desc_en = "Swiss-cheese earth. A sniper and heavy sapper guard the fork.",
		desc_pt = "Terra esburacada como queijo suíço. Um franco-atirador e um sapador pesado guardam a bifurcação.",
		desc_fr = "Sol troué comme du gruyère. Un tireur d'élite et un sapeur lourd gardent la bifurcation.",
		desc_es = "Tierra agujereada como queso suizo. Un francotirador y un zapador pesado vigilan la bifurcación.",
		desc_tr = "İsviçre peyniri gibi delik deşik toprak. Bir keskin nişancı ve ağır bir istihkâmcı yol ayrımını bekliyor.",
		enemy_count = 2,
		enemy_hp = { 95, 100 },
		enemy_classes = { "sniper", "sapper_2" },
		enemy_levels = { 2, 2 },
		terrain_type = "swiss_cheese",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 8,
		name = "Северный Мост",
		name_en = "North Bridge",
		name_pt = "Ponte do Norte",
		name_fr = "Pont du Nord",
		name_es = "Puente del Norte",
		name_tr = "Kuzey Köprüsü",
		desc = "Каменная арка над пропастью. Штурмовой отряд при поддержке артиллерии.",
		desc_en = "Stone bridge arch. Assault vanguard supported by artillery guns.",
		desc_pt = "Arco de ponte de pedra. Vanguarda de assalto apoiada por canhões de artilharia.",
		desc_fr = "Arche de pont en pierre. Une avant-garde d'assaut soutenue par des canons d'artillerie.",
		desc_es = "Arco de puente de piedra. Vanguardia de asalto apoyada por cañones de artillería.",
		desc_tr = "Taş köprü kemeri. Topçu desteğine sahip bir hücum öncüsü.",
		enemy_count = 3,
		enemy_hp = { 95, 95, 105 },
		enemy_classes = { "assault_2", "artillery", "medic" },
		enemy_levels = { 2, 1, 1 },
		terrain_type = "canyon_bridge",
		biome = "desert",
		enemy_skill = "normal",
	},
	{
		level = 9,
		name = "Золотой Оазис",
		name_en = "Golden Oasis",
		name_pt = "Oásis Dourado",
		name_fr = "Oasis Doré",
		name_es = "Oasis Dorado",
		name_tr = "Altın Vaha",
		desc = "Богатый сектор под охраной бронированного танка и штурмовика.",
		desc_en = "Lush oasis guarded by a heavily plated Tank and assault veteran.",
		desc_pt = "Oásis exuberante guardado por um Tanque de blindagem pesada e um veterano de assalto.",
		desc_fr = "Oasis luxuriante gardée par un Char lourdement blindé et un vétéran d'assaut.",
		desc_es = "Oasis exuberante custodiado por un Tanque de blindaje pesado y un veterano de asalto.",
		desc_tr = "Gür vahayı ağır zırhlı bir Tank ve bir saldırı gazisi koruyor.",
		enemy_count = 2,
		enemy_hp = { 140, 100 },
		enemy_classes = { "tank", "assault_2" },
		enemy_levels = { 2, 2 },
		terrain_type = "hills",
		biome = "desert",
		enemy_skill = "hard",
	},

	-- =========================================================================
	-- РЕГИОН 3: ЛЕДЯНОЙ ПЕРЕВАЛ (Ice Pass) - Уровни 10..13 (Arctic Biome)
	-- =========================================================================
	{
		level = 10,
		name = "Морозные Высоты",
		name_en = "Frost Heights",
		name_pt = "Alturas Congeladas",
		name_fr = "Hauteurs Glaciales",
		name_es = "Alturas Gélidas",
		name_tr = "Buz Zirveleri",
		desc = "Ледяные острова в небе. Мобильный ракетчик и меткий снайпер контролируют воздух.",
		desc_en = "Floating ice peaks. A mobile rocketeer and sharpshooter dominate the sky.",
		desc_pt = "Picos de gelo flutuantes. Um lançador de foguetes ágil e um atirador de elite dominam o céu.",
		desc_fr = "Pics de glace flottants. Un lance-roquettes mobile et un tireur d'élite dominent le ciel.",
		desc_es = "Picos de hielo flotantes. Un cohetero móvil y un tirador certero dominan el cielo.",
		desc_tr = "Yüzen buz zirveleri. Çevik bir roketatarcı ve keskin bir nişancı gökyüzüne hâkim.",
		enemy_count = 2,
		enemy_hp = { 100, 95 },
		enemy_classes = { "rocketeer", "sniper" },
		enemy_levels = { 2, 2 },
		terrain_type = "floating_islands",
		biome = "arctic",
		enemy_skill = "hard",
	},
	{
		level = 11,
		name = "Парящие Льдины",
		name_en = "Floating Floes",
		name_pt = "Blocos de Gelo Flutuantes",
		name_fr = "Banquises Flottantes",
		name_es = "Témpanos Flotantes",
		name_tr = "Yüzen Buz Kütleleri",
		desc = "Гряда дрейфующих ледяных глыб. Тройка элитных скалолазов с базуками.",
		desc_en = "Drifting glacial floes. Trio of high-altitude rocketeers and commando.",
		desc_pt = "Blocos glaciais à deriva. Um trio de lançadores de foguetes de alta altitude e um comando.",
		desc_fr = "Banquises à la dérive. Un trio de lance-roquettes d'altitude et un commando.",
		desc_es = "Témpanos glaciares a la deriva. Un trío de coheteros de altura y un comando.",
		desc_tr = "Sürüklenen buzul kütleleri. Yüksek irtifa roketatarlarından oluşan bir üçlü ve bir komando.",
		enemy_count = 3,
		enemy_hp = { 100, 100, 105 },
		enemy_classes = { "rocketeer", "commando", "sniper" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "floating_islands",
		biome = "arctic",
		enemy_skill = "hard",
	},
	{
		level = 12,
		name = "Хребет Метелей",
		name_en = "Blizzard Ridge",
		name_pt = "Cume das Nevascas",
		name_fr = "Crête des Blizzards",
		name_es = "Cresta de las Ventiscas",
		name_tr = "Tipi Sırtı",
		desc = "Подземная ледяная пещера. Осадный артиллерист и диверсант в засаде.",
		desc_en = "Subterranean ice cavern. Siege artillery and commando in ambush.",
		desc_pt = "Caverna de gelo subterrânea. Artilharia de cerco e um comando em emboscada.",
		desc_fr = "Caverne de glace souterraine. Artillerie de siège et commando en embuscade.",
		desc_es = "Caverna de hielo subterránea. Artillería de asedio y un comando emboscados.",
		desc_tr = "Yeraltı buz mağarası. Kuşatma topçusu ve bir komando pusuda.",
		enemy_count = 2,
		enemy_hp = { 115, 110 },
		enemy_classes = { "artillery_2", "commando" },
		enemy_levels = { 2, 2 },
		terrain_type = "cavern",
		biome = "arctic",
		enemy_skill = "hard",
	},
	{
		level = 13,
		name = "Ледяной Бастион",
		name_en = "Ice Bastion",
		name_pt = "Bastião de Gelo",
		name_fr = "Bastion de Glace",
		name_es = "Bastión de Hielo",
		name_tr = "Buz Tabyası",
		desc = "Неприступная крепость во льдах. Взвод из 3 ветеранов: Танк, Сапер II и Хирург.",
		desc_en = "Impregnable ice fort. 3-spud elite detachment: Tank, Sapper II, Surgeon.",
		desc_pt = "Forte de gelo inexpugnável. Destacamento de elite com 3 batatas: Tanque, Sapador II e Cirurgião.",
		desc_fr = "Fort de glace imprenable. Détachement d'élite de 3 patates : Char, Sapeur II et Chirurgien.",
		desc_es = "Fortaleza de hielo inexpugnable. Destacamento de élite de 3 patatas: Tanque, Zapador II y Cirujano.",
		desc_tr = "Aşılmaz buz kalesi. 3 patatalık seçkin müfreze: Tank, İstihkâmcı II ve Cerrah.",
		enemy_count = 3,
		enemy_hp = { 150, 120, 115 },
		enemy_classes = { "tank", "sapper_2", "surgeon" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "arctic",
		enemy_skill = "hard",
	},

	-- =========================================================================
	-- РЕГИОН 4: ВУЛКАНИЧЕСКИЕ БАСТИОНЫ (Volcano Bastions) - Уровни 14..18 (Volcano Biome)
	-- =========================================================================
	{
		level = 14,
		name = "Обсидиановые Врата",
		name_en = "Obsidian Gates",
		name_pt = "Portões de Obsidiana",
		name_fr = "Portes d'Obsidienne",
		name_es = "Puertas de Obsidiana",
		name_tr = "Obsidyen Kapıları",
		desc = "Вход в вулканический сектор. 3 укрепленных огневых рубежа противника.",
		desc_en = "Gateway to the volcano. Three fortified battle positions.",
		desc_pt = "Portal do vulcão. Três posições de combate fortificadas.",
		desc_fr = "Porte d'entrée du volcan. Trois positions de combat fortifiées.",
		desc_es = "Puerta del volcán. Tres posiciones de combate fortificadas.",
		desc_tr = "Yanardağın kapısı. Üç tahkim edilmiş savaş mevzii.",
		enemy_count = 3,
		enemy_hp = { 120, 115, 125 },
		enemy_classes = { "assault_2", "artillery_2", "surgeon" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 15,
		name = "Лавовое Ущелье",
		name_en = "Lava Gorge",
		name_pt = "Desfiladeiro de Lava",
		name_fr = "Gorge de Lave",
		name_es = "Garganta de Lava",
		name_tr = "Lav Geçidi",
		desc = "Мост над кипящей лавой. Опаснейший перекрестный огонь снайпера и ракетчика.",
		desc_en = "Bridge over boiling magma. Lethal crossfire from sniper and rocketeer.",
		desc_pt = "Ponte sobre magma fervente. Fogo cruzado letal de um franco-atirador e um lançador de foguetes.",
		desc_fr = "Pont au-dessus du magma bouillonnant. Feu croisé mortel d'un tireur d'élite et d'un lance-roquettes.",
		desc_es = "Puente sobre magma hirviente. Fuego cruzado letal de un francotirador y un cohetero.",
		desc_tr = "Kaynayan magmanın üzerinde köprü. Bir keskin nişancı ve bir roketatardan ölümcül çapraz ateş.",
		enemy_count = 3,
		enemy_hp = { 110, 125, 120 },
		enemy_classes = { "sniper", "rocketeer", "commando" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "canyon_bridge",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 16,
		name = "Катакомбы Угля",
		name_en = "Charcoal Catacombs",
		name_pt = "Catacumbas de Carvão",
		name_fr = "Catacombes de Charbon",
		name_es = "Catacumbas de Carbón",
		name_tr = "Kömür Katakombları",
		desc = "Лавовые подземные лабиринты. Осадная батарея и тяжелый сапер ведут бой на выживание.",
		desc_en = "Subterranean magma labyrinth. Heavy sapper and artillery duel to the end.",
		desc_pt = "Labirinto subterrâneo de magma. Um sapador pesado e a artilharia duelam até o fim.",
		desc_fr = "Labyrinthe souterrain de magma. Un sapeur lourd et l'artillerie se battent jusqu'au bout.",
		desc_es = "Laberinto subterráneo de magma. Un zapador pesado y la artillería se baten hasta el final.",
		desc_tr = "Yeraltı magma labirenti. Ağır istihkâmcı ile topçu sonuna kadar çarpışıyor.",
		enemy_count = 3,
		enemy_hp = { 130, 135, 120 },
		enemy_classes = { "sapper_2", "artillery_2", "assault_2" },
		enemy_levels = { 2, 2, 2 },
		terrain_type = "cavern",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 17,
		name = "Бункер Генералов",
		name_en = "Generals Bunker",
		name_pt = "Bunker dos Generais",
		name_fr = "Bunker des Généraux",
		name_es = "Búnker de los Generales",
		name_tr = "Generaller Sığınağı",
		desc = "Генеральный штаб красных картошек. 4 опытных офицера в глубоком бункере.",
		desc_en = "Red Spud High Command. 4 hardened officers in a fortified bunker.",
		desc_pt = "Alto Comando das Batatas Vermelhas. 4 oficiais calejados em um bunker fortificado.",
		desc_fr = "Haut Commandement des Patates Rouges. 4 officiers aguerris dans un bunker fortifié.",
		desc_es = "Alto Mando de las Patatas Rojas. 4 oficiales curtidos en un búnker fortificado.",
		desc_tr = "Kızıl Patates Yüksek Komutanlığı. Tahkimli bir sığınakta 4 savaş görmüş subay.",
		enemy_count = 4,
		enemy_hp = { 150, 130, 125, 130 },
		enemy_classes = { "tank", "artillery_2", "sniper", "surgeon" },
		enemy_levels = { 2, 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "volcano",
		enemy_skill = "hard",
	},
	{
		level = 18,
		name = "Вулканическая Цитадель (ФИНАЛ)",
		name_en = "Volcano Citadel (FINAL BOSS)",
		name_pt = "Cidadela Vulcânica (FINAL)",
		name_fr = "Citadelle Volcanique (FINAL)",
		name_es = "Ciudadela Volcánica (FINAL)",
		name_tr = "Volkanik Kale (FİNAL)",
		desc = "Финальная битва на вершине вулкана! Босс Генерал-Клубень с гвардией ветеранов!",
		desc_en = "Final boss confrontation! The Supreme Spud General and elite vanguard!",
		desc_pt = "Confronto final com o chefe! O Supremo General Batata e sua vanguarda de elite!",
		desc_fr = "Affrontement final avec le boss ! Le Général Patate Suprême et son avant-garde d'élite !",
		desc_es = "¡Enfrentamiento final contra el jefe! ¡El Supremo General Patata y su vanguardia de élite!",
		desc_tr = "Son patron savaşı! Yüce Patates Generali ve seçkin öncü birlikleri!",
		enemy_count = 4,
		enemy_hp = { 200, 140, 140, 135 },
		enemy_classes = { "tank", "artillery_2", "rocketeer", "surgeon" },
		enemy_levels = { 3, 2, 2, 2 },
		terrain_type = "bunkers",
		biome = "volcano",
		enemy_skill = "hard",
	},
}

-- Procedural generator for endless/high levels beyond the preconfigured 18 levels
function M.generate_endless_level(level_num)
	local presets = { "hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese", "islands", "bunkers" }
	local biomes = { "grass", "arctic", "desert", "volcano", "alien", "grass", "desert" }
	local idx = ((level_num - 1) % #presets) + 1

	local enemy_cnt = math.min(4, 2 + math.floor((level_num - 18) / 3))
	local scaled_hp = math.min(220, 120 + (level_num - 18) * 8)

	local class_pool = { "tank", "artillery_2", "rocketeer", "assault_2", "sniper", "sapper_2", "surgeon", "commando" }
	local enemy_classes = {}
	local enemy_levels = {}
	local enemy_hps = {}
	for i = 1, enemy_cnt do
		local pick = class_pool[((level_num + i) % #class_pool) + 1]
		table.insert(enemy_classes, pick)
		table.insert(enemy_levels, 2 + math.floor((level_num - 18) / 5))
		table.insert(enemy_hps, scaled_hp)
	end

	return M.normalize_level({
		level = level_num,
		name = "Арена " .. tostring(level_num) .. ": Экстрим",
		name_en = "Arena " .. tostring(level_num) .. ": Extreme",
		desc = "1 против волны элитных ботов-ветеранов!",
		desc_en = "Battle against elite spud veterans wave!",
		name_pt = "Arena " .. tostring(level_num) .. ": Extremo",
		name_fr = "Arène " .. tostring(level_num) .. " : Extrême",
		name_es = "Arena " .. tostring(level_num) .. ": Extremo",
		name_tr = "Arena " .. tostring(level_num) .. ": Ekstrem",
		desc_pt = "Uma contra uma onda de batatas veteranas de elite!",
		desc_fr = "Seul contre une vague de patates vétérans d'élite !",
		desc_es = "¡Uno contra una oleada de patatas veteranas de élite!",
		desc_tr = "Elit gazi patateler dalgasına karşı tek başına!",
		enemy_hp = enemy_hps,
		enemy_count = enemy_cnt,
		enemy_classes = enemy_classes,
		enemy_levels = enemy_levels,
		terrain_type = presets[idx],
		biome = biomes[idx],
		enemy_skill = "hard",
	}, level_num)
end

-- Get level configuration by level number
function M.get(level_num)
	level_num = level_num or 1
	if level_num >= 1 and level_num <= #M.LEVELS then
		return M.normalize_level(M.LEVELS[level_num], level_num)
	else
		return M.generate_endless_level(level_num)
	end
end

-- Get specific HP for enemy at index (1-based) on given level
function M.get_enemy_hp(level_num, enemy_index)
	local cfg = M.get(level_num)
	enemy_index = enemy_index or 1

	if type(cfg.enemy_hp) == "table" then
		if cfg.enemy_hp[enemy_index] then
			return cfg.enemy_hp[enemy_index]
		elseif #cfg.enemy_hp > 0 then
			return cfg.enemy_hp[#cfg.enemy_hp]
		else
			return 100
		end
	elseif type(cfg.enemy_hp) == "number" then
		return cfg.enemy_hp
	else
		return 100
	end
end

-- Get enemy count for given level
function M.get_enemy_count(level_num)
	local cfg = M.get(level_num)
	return cfg.enemy_count or 1
end

-- Get enemy class ID for enemy at index (1-based) on given level
function M.get_enemy_class(level_num, enemy_index)
	local cfg = M.get(level_num)
	enemy_index = enemy_index or 1
	if cfg.enemy_classes and #cfg.enemy_classes > 0 then
		return cfg.enemy_classes[enemy_index] or cfg.enemy_classes[#cfg.enemy_classes] or "recruit"
	end
	return "recruit"
end

-- Get enemy unit level / rank for enemy at index (1-based) on given level
function M.get_enemy_level(level_num, enemy_index)
	local cfg = M.get(level_num)
	enemy_index = enemy_index or 1
	if cfg.enemy_levels and #cfg.enemy_levels > 0 then
		return cfg.enemy_levels[enemy_index] or cfg.enemy_levels[#cfg.enemy_levels] or 1
	end
	return 1
end

-- Get terrain type for given level
function M.get_terrain_type(level_num)
	local cfg = M.get(level_num)
	return cfg.terrain_type or "hills"
end

-- Get biome for given level
function M.get_biome(level_num)
	local cfg = M.get(level_num)
	return cfg.biome or M.deduce_biome(cfg.terrain_type)
end

-- Get bot skill / difficulty for given level
function M.get_skill_level(level_num)
	local cfg = M.get(level_num)
	return cfg.enemy_skill or "normal"
end
M.get_bot_difficulty = M.get_skill_level

-- Get total number of predefined levels
function M.count()
	return #M.LEVELS
end

-- Register or override a level configuration dynamically
function M.set_level(level_num, config)
	if not config then return end
	config.level = level_num
	M.LEVELS[level_num] = M.normalize_level(config, level_num)
end

-- Quick match configurations (Quick Bot & Quick PvP)
function M.get_quick_match(mode)
	local pool_presets = {
		"hills", "floating_islands", "canyon_bridge", "cavern", "swiss_cheese",
		"bunkers", "islands", "pyramid_temple", "twin_peaks", "valley_caves"
	}
	local pool_biomes = { "grass", "arctic", "desert", "volcano", "alien" }
	local pick_preset = pool_presets[math.random(1, #pool_presets)]
	local pick_biome = pool_biomes[math.random(1, #pool_biomes)]

	if mode == "pvp_bots" or mode == "quick_pvp_bots" then
		return {
			name = "PvP vs Боты (3 на 3)",
			name_en = "PvP vs Bots (3v3)",
			name_pt = "PvP contra Bots (3x3)",
			name_fr = "PvP contre Bots (3 contre 3)",
			name_es = "PvP contra Bots (3 contra 3)",
			name_tr = "PvP - Botlara Karşı (3'e 3)",
			enemy_hp = 100,
			enemy_count = 3,
			red_count = 3,
			player_count = 3,
			blue_count = 3,
			terrain_type = pick_preset,
			terrain_preset = pick_preset,
			biome = pick_biome,
			enemy_skill = "hard",
			bot_difficulty = "hard",
		}
	elseif mode == "quick_pvp" then
		return {
			name = "Быстрый бой: 2 Игрока",
			name_en = "Quick Battle: 2 Players",
			name_pt = "Batalha Rápida: 2 Jogadores",
			name_fr = "Combat rapide : 2 joueurs",
			name_es = "Batalla rápida: 2 jugadores",
			name_tr = "Hızlı Savaş: 2 Oyuncu",
			enemy_hp = 120,
			enemy_count = 3,
			red_count = 3,
			player_count = 3,
			blue_count = 3,
			terrain_type = pick_preset,
			terrain_preset = pick_preset,
			biome = pick_biome,
			enemy_skill = "none",
			bot_difficulty = "none",
		}
	else
		return {
			name = "Быстрый бой vs Компьютер",
			name_en = "Quick Battle vs Computer",
			name_pt = "Batalha Rápida vs Computador",
			name_fr = "Combat rapide contre l'ordinateur",
			name_es = "Batalla rápida contra el ordenador",
			name_tr = "Hızlı Savaş: Bilgisayara Karşı",
			enemy_hp = 120,
			enemy_count = 3,
			red_count = 3,
			player_count = 3,
			blue_count = 3,
			terrain_type = pick_preset,
			terrain_preset = pick_preset,
			biome = pick_biome,
			enemy_skill = "normal",
			bot_difficulty = "normal",
		}
	end
end

return M
