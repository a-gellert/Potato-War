-- lua_modules/weapons.lua
-- Centralized weapon definitions, elemental statuses, and arena pickups for Potato War
-- All weapon stats and elemental interactions are data-driven from this module.
--
-- Weapon fields beyond the physics numbers:
--   rarity          "common" | "rare" | "epic" | "legendary" (card frame, blueprint drop weight)
--   icon            atlas image for HUD / cards; projectile_sprite: image of the flying shell
--   sfx             shot sound; explode_sfx: explosion sound override
--   spin            the shell tumbles instead of pointing along its flight
--   art_angle       direction (degrees) the projectile art points to when unrotated
--   fixed_power     always fired at max_power (straight-shooting guns)
--   aim             "arc" (dotted trajectory, default) | "target" (tap a spot on the map)
--   homing          { delay, turn, speed }: steers to its locked target after `delay` seconds
--   cluster         { count, weapon }: releases bomblets when it bursts
--   fuse_fx         sparkling fuse with a hissing sound
--   internal        only spawned by other weapons or world events, never carried

local M = {}

M.TYPES = {
	GRENADE      = "grenade",
	RIFLE        = "rifle",
	KNIFE        = "knife",
	MOLOTOV      = "molotov",
	BURST        = "burst",
	BAZOOKA      = "bazooka",
	SHOTGUN      = "shotgun",
	HOLY_GRENADE = "holy_grenade",
	BEETLE       = "beetle",
	DRILL        = "drill",
	PEPPER       = "pepper",
	GARLIC       = "garlic",
	DYNAMITE     = "dynamite",
	CLUSTER      = "cluster",
	HOMING       = "homing",
	AIRSTRIKE    = "airstrike",
	AIR_BOMB     = "air_bomb",
}

-- Elemental & Tactical Status States
M.STATUS_TYPES = {
	BURNING   = "burning",   -- Fire DoT, ignites terrain, flammable
	POISONED  = "poisoned",  -- Acid/Toxin DoT, weakens attack power (-20%)
	GLUED     = "glued",     -- Sticky mash/syrup: -60% movement speed, disables/halves jumping
	CONCUSSED = "concussed", -- Stunned/dazed: aim wobble, power penalty, shortens turn timer
}

-- Elemental Combination Reactions
M.COMBOS = {
	sticky_inferno = {
		id = "sticky_inferno",
		req = { glued = true, burning = true },
		name = "Липкий ад",
		name_en = "Sticky Inferno",
		name_pt = "Inferno Grudento",
		name_fr = "Enfer Collant",
		name_es = "Infierno Pegajoso",
		name_tr = "Yapışkan Cehennem",
		bonus_damage = 25,
		duration_bonus = 2,
		desc = "Липкая картофельная масса вспыхивает ярким пламенем, нанося мгновенный урон и продлевая горение!",
		desc_en = "The sticky potato mass bursts into bright flames, dealing instant damage and prolonging the burn!",
		desc_pt = "A massa pegajosa de batata explode em chamas vivas, causando dano instantâneo e prolongando a queimadura!",
		desc_fr = "La pâte de pomme de terre collante s'embrase en vives flammes, infligeant des dégâts instantanés et prolongeant la brûlure !",
		desc_es = "¡La masa pegajosa de patata estalla en llamas vivas, causando daño instantáneo y alargando la quemadura!",
		desc_tr = "Yapışkan patates hamuru parlak alevlerle tutuşur, anında hasar verir ve yanmayı uzatır!",
	},
	toxic_burst = {
		id = "toxic_burst",
		req = { poisoned = true, burning = true },
		name = "Токсичный взрыв",
		name_en = "Toxic Burst",
		name_pt = "Explosão Tóxica",
		name_fr = "Explosion Toxique",
		name_es = "Explosión Tóxica",
		name_tr = "Zehirli Patlama",
		bonus_damage = 20,
		aoe_radius = 28,
		desc = "Ядовитые пары перца взрываются при контакте с огнем!",
		desc_en = "Poisonous pepper fumes explode on contact with fire!",
		desc_pt = "Os vapores venenosos da pimenta explodem em contato com o fogo!",
		desc_fr = "Les vapeurs toxiques du piment explosent au contact du feu !",
		desc_es = "¡Los vapores venenosos del pimiento estallan al contacto con el fuego!",
		desc_tr = "Biberin zehirli buharı ateşle temas edince patlar!",
	},
	paralyzed = {
		id = "paralyzed",
		req = { glued = true, concussed = true },
		name = "Паралич",
		name_en = "Paralyzed",
		name_pt = "Paralisado",
		name_fr = "Paralysé",
		name_es = "Paralizado",
		name_tr = "Felç",
		bonus_damage = 10,
		immobilize = true,
		desc = "Оглушенный боец полностью застревает в картофельном пюре!",
		desc_en = "The stunned fighter gets completely stuck in the mashed potatoes!",
		desc_pt = "O combatente atordoado fica completamente preso no purê de batata!",
		desc_fr = "Le combattant sonné reste totalement englué dans la purée !",
		desc_es = "¡El combatiente aturdido queda totalmente atrapado en el puré de patata!",
		desc_tr = "Sersemleyen savaşçı patates püresine tamamen yapışıp kalır!",
	},
	neurotoxin = {
		id = "neurotoxin",
		req = { poisoned = true, concussed = true },
		name = "Нейротоксин",
		name_en = "Neurotoxin",
		name_pt = "Neurotoxina",
		name_fr = "Neurotoxine",
		name_es = "Neurotoxina",
		name_tr = "Nörotoksin",
		bonus_damage = 15,
		damage_reduction = 0.40,
		desc = "Яд парализует нервную систему: снижение урона на 40% и усиленный DoT!",
		desc_en = "The poison paralyzes the nervous system: 40% damage reduction and a stronger DoT!",
		desc_pt = "O veneno paralisa o sistema nervoso: redução de dano de 40% e DoT reforçado!",
		desc_fr = "Le poison paralyse le système nerveux : dégâts réduits de 40 % et DoT renforcé !",
		desc_es = "¡El veneno paraliza el sistema nervioso: reducción de daño del 40 % y DoT reforzado!",
		desc_tr = "Zehir sinir sistemini felç eder: hasar %40 azalır ve DoT güçlenir!",
	},
}

-- Evaluate elemental combination between existing active statuses and an incoming status
function M.eval_combo(current_statuses, new_status_type)
	if not current_statuses or not new_status_type then
		return nil
	end

	local has_status = function(st)
		return (current_statuses[st] and current_statuses[st].duration > 0) or (new_status_type == st)
	end

	if has_status("glued") and has_status("burning") then
		return M.COMBOS.sticky_inferno
	elseif has_status("poisoned") and has_status("burning") then
		return M.COMBOS.toxic_burst
	elseif has_status("glued") and has_status("concussed") then
		return M.COMBOS.paralyzed
	elseif has_status("poisoned") and has_status("concussed") then
		return M.COMBOS.neurotoxin
	end

	return nil
end

M.CATEGORY_CLASS_BASE  = "class_base"
M.CATEGORY_ARENA_PICKUP = "arena_pickup"
M.CATEGORY_INTERNAL = "internal"

local DEFS = {
	-- Граната — базовое бесконечное оружие любого класса
	grenade = {
		id               = "grenade",
		name             = "Граната",
		name_en = "Grenade",
		name_pt = "Granada",
		name_fr = "Grenade",
		name_es = "Granada",
		name_tr = "El Bombası",
		icon             = "w_grenade",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "common",
		default_ammo     = -1, -- Unlimited!
		desc             = "Отскакивает от земли и взрывается через 3 секунды",
		desc_en = "Bounces around and explodes after 3 seconds",
		desc_pt = "Quica e explode após 3 segundos",
		desc_fr = "Rebondit puis explose après 3 secondes",
		desc_es = "Rebota y explota a los 3 segundos",
		desc_tr = "Seker ve 3 saniye sonra patlar",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.55,
		friction         = 0.82,
		fuse_time        = 3.0,
		wind_sensitivity = 0.85,
		blast_radius     = 36,
		max_damage       = 30,
		blast_force      = 180,
		max_power        = 600,
		power_scale      = 3.2,
		sfx              = "throw",
		spin             = true,
		projectile_sprite = "w_grenade",
		projectile_scale  = 0.75,
	},

	-- Базука — ракета, оставляет липкое пюре (Клей)
	bazooka = {
		id               = "bazooka",
		name             = "Базука",
		name_en = "Bazooka",
		name_pt = "Bazuca",
		name_fr = "Bazooka",
		name_es = "Bazuca",
		name_tr = "Bazuka",
		icon             = "w_bazooka",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "common",
		default_ammo     = 2,
		desc             = "Ракета взрывается при попадании и оставляет липкое пюре (Клей). Её сносит ветер",
		desc_en = "The rocket explodes on impact and leaves sticky mash (Glue). Wind pushes it",
		desc_pt = "O foguete explode no impacto e deixa purê grudento (Cola). O vento o empurra",
		desc_fr = "La roquette explose à l'impact et laisse de la purée collante (Colle). Le vent la pousse",
		desc_es = "El cohete explota al impactar y deja puré pegajoso (Pegamento). El viento lo empuja",
		desc_tr = "Roket çarpınca patlar ve yapışkan püre bırakır (Yapışkan). Rüzgâr onu iter",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.4,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 6.0,
		wind_sensitivity = 0.50,
		blast_radius     = 48,
		max_damage       = 65,
		blast_force      = 220,
		max_power        = 700,
		power_scale      = 3.5,
		status_effect    = {
			type     = M.STATUS_TYPES.GLUED,
			duration = 2,
			power    = 1,
		},
		sfx              = "shot_rocket",
		projectile_sprite = "p_rocket",
		projectile_scale  = 0.65,
	},

	-- Дробовик — веер дроби по прямой
	shotgun = {
		id               = "shotgun",
		name             = "Дробовик",
		name_en = "Shotgun",
		name_pt = "Espingarda",
		name_fr = "Fusil à pompe",
		name_es = "Escopeta",
		name_tr = "Pompalı Tüfek",
		icon             = "w_shotgun",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "common",
		default_ammo     = 3,
		desc             = "Пять дробин веером по прямой. Смертельно вблизи",
		desc_en = "Five pellets in a straight fan. Deadly up close",
		desc_pt = "Cinco balins em leque reto. Mortal de perto",
		desc_fr = "Cinq plombs en éventail droit. Mortel de près",
		desc_es = "Cinco perdigones en abanico recto. Mortal de cerca",
		desc_tr = "Düz yelpazede beş saçma. Yakında ölümcül",
		fire_mode        = "spread",
		on_hit           = "explode",
		shot_count       = 5,
		spread_angle     = 0.22,
		gravity_mult     = 0.15,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 1.2,
		speed            = 900,
		wind_sensitivity = 0.15,
		blast_radius     = 10,
		max_damage       = 18,
		blast_force      = 150,
		max_power        = 900,
		power_scale      = 5.0,
		fixed_power      = true,
		sfx              = "shot_shotgun",
		projectile_sprite = "p_pellet",
		projectile_scale  = 0.7,
	},

	-- Снайперка — быстрая пуля почти по прямой
	rifle = {
		id               = "rifle",
		name             = "Снайперка",
		name_en = "Sniper Rifle",
		name_pt = "Rifle Sniper",
		name_fr = "Fusil de sniper",
		name_es = "Rifle de Francotirador",
		name_tr = "Keskin Nişancı Tüfeği",
		icon             = "w_sniper",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "rare",
		default_ammo     = 3,
		desc             = "Быстрая пуля летит почти по прямой. Огромный урон при прямом попадании",
		desc_en = "A fast bullet flies almost straight. Massive damage on a direct hit",
		desc_pt = "Bala rápida que voa quase reta. Dano enorme no acerto direto",
		desc_fr = "Une balle rapide vole presque droit. Énormes dégâts en tir direct",
		desc_es = "Una bala rápida vuela casi recta. Daño enorme en impacto directo",
		desc_tr = "Hızlı mermi neredeyse düz uçar. Tam isabette büyük hasar",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.06,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 3.0,
		speed            = 1250,
		wind_sensitivity = 0.10,
		blast_radius     = 14,
		max_damage       = 55,
		blast_force      = 160,
		max_power        = 1250,
		power_scale      = 6.0,
		fixed_power      = true,
		sfx              = "shot_sniper",
		projectile_sprite = "p_bullet",
		projectile_scale  = 0.75,
	},

	-- Святая картошка — легендарный взрыв (Контузия)
	holy_grenade = {
		id               = "holy_grenade",
		name             = "Святая картошка",
		name_en = "Holy Potato",
		name_pt = "Batata Sagrada",
		name_fr = "Patate Sacrée",
		name_es = "Patata Sagrada",
		name_tr = "Kutsal Patates",
		icon             = "w_holy",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "legendary",
		rarity           = "legendary",
		default_ammo     = 1,
		desc             = "Золотая картошка: колоссальный взрыв и оглушение (Контузия)",
		desc_en = "A golden potato: a colossal blast that stuns (Concussion)",
		desc_pt = "Uma batata dourada: explosão colossal que atordoa (Concussão)",
		desc_fr = "Une patate dorée : explosion colossale qui étourdit (Commotion)",
		desc_es = "Una patata dorada: explosión colosal que aturde (Conmoción)",
		desc_tr = "Altın patates: devasa ve sersemleten patlama (Sarsıntı)",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.6,
		friction         = 0.78,
		fuse_time        = 4.0,
		wind_sensitivity = 0.70,
		blast_radius     = 70,
		max_damage       = 90,
		blast_force      = 320,
		max_power        = 580,
		power_scale      = 3.0,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 2,
			power    = 1,
		},
		sfx              = "throw",
		explode_sfx      = "holy",
		spin             = true,
		projectile_sprite = "w_holy",
		projectile_scale  = 0.75,
	},

	-- Динамит — огромный взрыв, бросок недалеко
	dynamite = {
		id               = "dynamite",
		name             = "Динамит",
		name_en = "Dynamite",
		name_pt = "Dinamite",
		name_fr = "Dynamite",
		name_es = "Dinamita",
		name_tr = "Dinamit",
		icon             = "w_dynamite",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
		rarity           = "epic",
		default_ammo     = 1,
		desc             = "Огромный взрыв через 4 секунды. Бросок недалеко",
		desc_en = "A huge blast after 4 seconds. Short throw",
		desc_pt = "Explosão enorme após 4 segundos. Lançamento curto",
		desc_fr = "Énorme explosion après 4 secondes. Lancer court",
		desc_es = "Gran explosión a los 4 segundos. Lanzamiento corto",
		desc_tr = "4 saniye sonra dev patlama. Kısa atış",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.25,
		friction         = 0.6,
		fuse_time        = 4.0,
		wind_sensitivity = 0.30,
		blast_radius     = 60,
		max_damage       = 70,
		blast_force      = 300,
		max_power        = 430,
		power_scale      = 2.6,
		sfx              = "throw",
		spin             = true,
		fuse_fx          = true,
		projectile_sprite = "w_dynamite",
		projectile_scale  = 0.7,
	},

	-- Кассетная бомба — разлетается на пять бомбочек
	cluster = {
		id               = "cluster",
		name             = "Кассетная бомба",
		name_en = "Cluster Bomb",
		name_pt = "Bomba de Fragmentação",
		name_fr = "Bombe à fragmentation",
		name_es = "Bomba de Racimo",
		name_tr = "Misket Bombası",
		icon             = "w_cluster",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
		rarity           = "epic",
		default_ammo     = 1,
		desc             = "При ударе разлетается на пять бомбочек",
		desc_en = "Bursts into five bomblets on impact",
		desc_pt = "Explode em cinco bombinhas no impacto",
		desc_fr = "Éclate en cinq petites bombes à l'impact",
		desc_es = "Estalla en cinco bombitas al impactar",
		desc_tr = "Çarpınca beş küçük bombaya ayrılır",
		fire_mode        = "single",
		on_hit           = "explode",
		cluster          = { count = 5, weapon = "bomblet" },
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 0.40,
		blast_radius     = 26,
		max_damage       = 22,
		blast_force      = 160,
		max_power        = 600,
		power_scale      = 3.2,
		sfx              = "throw",
		spin             = true,
		projectile_sprite = "w_cluster",
		projectile_scale  = 0.7,
	},

	-- Самонаводящаяся ракета — летит к врагу, ближайшему к прицелу
	homing = {
		id               = "homing",
		name             = "Самонаводящаяся ракета",
		name_en = "Homing Missile",
		name_pt = "Míssil Teleguiado",
		name_fr = "Missile à tête chercheuse",
		name_es = "Misil Teledirigido",
		name_tr = "Güdümlü Füze",
		icon             = "w_homing",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
		rarity           = "epic",
		default_ammo     = 1,
		desc             = "Через мгновение после пуска летит к врагу, ближайшему к прицелу",
		desc_en = "Moments after launch it flies to the enemy nearest your aim",
		desc_pt = "Logo após o disparo voa até o inimigo mais perto da mira",
		desc_fr = "Peu après le tir, elle vole vers l'ennemi le plus proche de ta visée",
		desc_es = "Poco después del disparo vuela hacia el enemigo más cercano a tu mira",
		desc_tr = "Fırlatıldıktan hemen sonra nişana en yakın düşmana uçar",
		fire_mode        = "single",
		on_hit           = "explode",
		homing           = { delay = 0.5, turn = 3.6, speed = 480 },
		gravity_mult     = 0.5,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 7.0,
		wind_sensitivity = 0.50,
		blast_radius     = 40,
		max_damage       = 50,
		blast_force      = 230,
		max_power        = 680,
		power_scale      = 3.5,
		sfx              = "shot_rocket",
		projectile_sprite = "p_missile",
		projectile_scale  = 0.65,
	},

	-- Авиаудар — самолёт сбрасывает бомбы в указанную точку
	airstrike = {
		id               = "airstrike",
		name             = "Авиаудар",
		name_en = "Airstrike",
		name_pt = "Ataque Aéreo",
		name_fr = "Frappe aérienne",
		name_es = "Ataque Aéreo",
		name_tr = "Hava Saldırısı",
		icon             = "w_airstrike",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "legendary",
		rarity           = "legendary",
		default_ammo     = 1,
		desc             = "Самолёт сбрасывает пять бомб туда, куда ты укажешь",
		desc_en = "A plane drops five bombs where you point",
		desc_pt = "Um avião solta cinco bombas onde você apontar",
		desc_fr = "Un avion largue cinq bombes là où tu vises",
		desc_es = "Un avión suelta cinco bombas donde apuntes",
		desc_tr = "Uçak gösterdiğin yere beş bomba atar",
		fire_mode        = "airstrike",
		aim              = "target",
		bombs            = 5,
		bomb_spacing     = 34,
		bomb_weapon      = "airstrike_bomb",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 6.0,
		wind_sensitivity = 0.35,
		blast_radius     = 26,
		max_damage       = 24,
		blast_force      = 170,
		max_power        = 1,
		power_scale      = 1.0,
		sfx              = "radio",
		projectile_sprite = "p_airbomb",
		projectile_scale  = 0.7,
	},

	-- 3. Боевой Топор (Нож / Ближний бой) — Базовое оружие в стиле референса
	knife = {
		id               = "knife",
		name             = "Боевой Топор",
		name_en = "Potato Peeler",
		name_pt = "Descascador",
		name_fr = "Épluche-Patates",
		name_es = "Pelapatatas",
		name_tr = "Patates Soyacağı",
		icon             = "knife",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "common",
		sfx              = "whoosh",
		default_ammo     = 4,
		desc             = "Сокрушительный рубящий удар боевым топором в упор!",
		desc_en = "A crushing point-blank chop with the peeler!",
		desc_pt = "Um golpe esmagador à queima-roupa com o descascador!",
		desc_fr = "Un coup fracassant à bout portant avec l'éplucheur !",
		desc_es = "¡Un tajo demoledor a quemarropa con el pelapatatas!",
		desc_tr = "Patates soyacağıyla yakın mesafeden ezici bir darbe!",
		fire_mode        = "melee",
		on_hit           = "explode",
		melee_range      = 42,
		blast_radius     = 30,
		max_damage       = 60,
		blast_force      = 220,
		gravity_mult     = 0.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 0.0,
		wind_sensitivity = 0.0, -- Melee immune to wind
		max_power        = 1,
		power_scale      = 1.0,
		projectile_sprite = "knife",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 5. Фри-автомат (Автомат) — Базовое оружие (Штурмовик)
	burst = {
		id               = "burst",
		name             = "Фри-автомат",
		name_en = "Fry-O-Matic",
		name_pt = "Frita-Mática",
		name_fr = "Frito-Matic",
		name_es = "Fri-Automática",
		name_tr = "Kızartmatik",
		icon             = "rifle",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "rare",
		sfx              = "shot_sniper",
		default_ammo     = 3,
		desc             = "Три быстрых выстрела хрустящей картошкой фри подряд",
		desc_en = "Three rapid shots of crispy french fries in a row",
		desc_pt = "Três disparos rápidos de batata frita crocante em sequência",
		desc_fr = "Trois tirs rapides de frites croustillantes à la suite",
		desc_es = "Tres disparos rápidos de patatas fritas crujientes seguidos",
		desc_tr = "Art arda üç hızlı çıtır patates kızartması atışı",
		fire_mode        = "multi_shot",
		on_hit           = "explode",
		shot_count       = 3,
		shot_delay       = 0.12,
		shot_spread      = 0.06,
		gravity_mult     = 0.15,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 4.0,
		speed            = 900,
		wind_sensitivity = 0.40,
		blast_radius     = 12,
		max_damage       = 30,
		blast_force      = 120,
		max_power        = 900,
		power_scale      = 4.5,
		projectile_sprite = "fry_bullet",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 4. Фритюрное масло (Молотов) — Оружие на арене (Стихия Огня: Burning)
	molotov = {
		id               = "molotov",
		name             = "Фритюрное масло",
		name_en = "Frying Oil",
		name_pt = "Óleo de Fritura",
		name_fr = "Huile de Friture",
		name_es = "Aceite de Freír",
		name_tr = "Kızartma Yağı",
		icon             = "oil_bottle",
		category         = M.CATEGORY_ARENA_PICKUP,
		rarity           = "rare",
		sfx              = "throw",
		pickup_rarity    = "common",
		default_ammo     = 2,
		desc             = "Кипящее масло: заливает все фритюром и поджигает врагов (Горение)",
		desc_en = "Boiling oil: deep-fries everything and sets enemies ablaze (Burning)",
		desc_pt = "Óleo fervente: frita tudo e incendeia os inimigos (Queimadura)",
		desc_fr = "Huile bouillante : tout passe à la friteuse et les ennemis s'enflamment (Brûlure)",
		desc_es = "Aceite hirviendo: lo fríe todo y prende fuego a los enemigos (Quemadura)",
		desc_tr = "Kaynar yağ: her şeyi kızartır, düşmanları tutuşturur (Yanma)",
		fire_mode        = "single",
		on_hit           = "napalm",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 0.90,
		blast_radius     = 18,
		max_damage       = 20,
		blast_force      = 100,
		max_power        = 550,
		power_scale      = 3.0,
		napalm_count     = 6,
		napalm_spread    = 40,
		napalm_burn_time = 2.5,
		napalm_radius    = 10,
		napalm_dps       = 10,
		status_effect    = {
			type     = M.STATUS_TYPES.BURNING,
			duration = 3,
			power    = 14,
		},
		projectile_sprite = "oil_bottle",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 11. Перцемолка «Острый Чили» — Оружие на арене / Базовое (Медик: Poisoned)
	pepper = {
		id               = "pepper",
		name             = "Перцемолка «Чили»",
		name_en = "Chili Pepper Mill",
		name_pt = "Moedor de Pimenta Chili",
		name_fr = "Moulin à Piment Chili",
		name_es = "Molinillo de Chile",
		name_tr = "Acı Biber Değirmeni",
		icon             = "pepper_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
		rarity           = "rare",
		sfx              = "throw",
		pickup_rarity    = "common",
		default_ammo     = 2,
		desc             = "Жгучий помол кайенского перца: ядовитое облако отравляет бойцов (Яд)",
		desc_en = "A fiery grind of cayenne pepper: a toxic cloud poisons the fighters (Poison)",
		desc_pt = "Moagem ardente de pimenta-caiena: a nuvem tóxica envenena os combatentes (Veneno)",
		desc_fr = "Une mouture brûlante de piment de Cayenne : le nuage toxique empoisonne les combattants (Poison)",
		desc_es = "Molienda ardiente de pimienta de cayena: la nube tóxica envenena a los combatientes (Veneno)",
		desc_tr = "Yakıcı kırmızı biber öğütmesi: zehirli bulut savaşçıları zehirler (Zehir)",
		fire_mode        = "single",
		on_hit           = "pepper",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 1.20, -- Spice cloud catches wind
		blast_radius     = 22,
		max_damage       = 20,
		blast_force      = 120,
		max_power        = 560,
		power_scale      = 3.0,
		pepper_count     = 6,
		pepper_spread    = 42,
		pepper_burn_time = 3.0,
		pepper_radius    = 11,
		pepper_dps       = 12,
		status_effect    = {
			type     = M.STATUS_TYPES.POISONED,
			duration = 3,
			power    = 10,
		},
		projectile_sprite = "pepper_bomb",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 10. Грядковый Бур (Пробитие террейна) — Базовое оружие (Сапер)
	drill = {
		id               = "drill",
		name             = "Грядковый Бур",
		name_en = "Garden Drill",
		name_pt = "Broca de Canteiro",
		name_fr = "Foret Potager",
		name_es = "Taladro de Huerto",
		name_tr = "Bahçe Matkabı",
		icon             = "drill_missile",
		category         = M.CATEGORY_CLASS_BASE,
		rarity           = "rare",
		sfx              = "shot_rocket",
		default_ammo     = 2,
		desc             = "Пружинный бур: просверливает грунт и взрывается в бункере врага!",
		desc_en = "Spring drill: bores through the soil and explodes inside the enemy bunker!",
		desc_pt = "Broca de mola: perfura o solo e explode dentro do bunker inimigo!",
		desc_fr = "Foret à ressort : creuse le sol et explose dans le bunker ennemi !",
		desc_es = "Taladro de resorte: perfora el suelo y estalla dentro del búnker enemigo.",
		desc_tr = "Yaylı matkap: toprağı deler ve düşman sığınağında patlar!",
		fire_mode        = "single",
		on_hit           = "drill",
		gravity_mult     = 0.22,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		speed            = 850,
		wind_sensitivity = 0.25, -- Heavy drill, cut through wind
		blast_radius     = 42,
		max_damage       = 60,
		blast_force      = 200,
		max_power        = 850,
		power_scale      = 4.2,
		drill_dist       = 65,
		projectile_sprite = "drill_missile",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 12. Чесночный Динамит — Оружие на арене (Concussed)
	garlic = {
		id               = "garlic",
		name             = "Чесночный Динамит",
		name_en = "Garlic Dynamite",
		name_pt = "Dinamite de Alho",
		name_fr = "Dynamite à l'Ail",
		name_es = "Dinamita de Ajo",
		name_tr = "Sarımsak Dinamiti",
		icon             = "garlic_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
		rarity           = "epic",
		sfx              = "throw",
		pickup_rarity    = "rare",
		default_ammo     = 2,
		desc             = "Связка ядреного чеснока: колоссальная ударная волна и оглушение (Контузия)",
		desc_en = "A bundle of pungent garlic: a colossal shockwave and stun (Concussion)",
		desc_pt = "Um molho de alho forte: onda de choque colossal e atordoamento (Concussão)",
		desc_fr = "Une botte d'ail bien costaud : onde de choc colossale et étourdissement (Commotion)",
		desc_es = "Un manojo de ajo potente: onda expansiva colosal y aturdimiento (Conmoción)",
		desc_tr = "Bir deste keskin sarımsak: devasa şok dalgası ve sersemletme (Sarsıntı)",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.85,
		bounciness       = 0.35,
		friction         = 0.85,
		fuse_time        = 3.2,
		wind_sensitivity = 0.80,
		blast_radius     = 55,
		crater_radius    = 14,
		max_damage       = 25,
		blast_force      = 320,
		max_power        = 620,
		power_scale      = 3.2,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 2,
			power    = 1,
		},
		projectile_sprite = "garlic_bomb",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 9. Колорадский Десант (Банка с жуками) — Оружие на арене (Редкое)
	beetle = {
		id               = "beetle",
		name             = "Колорадский Десант",
		name_en = "Beetle Swarm",
		name_pt = "Desembarque de Besouros",
		name_fr = "Débarquement de Doryphores",
		name_es = "Desembarco de Escarabajos",
		name_tr = "Böcek Çıkarması",
		icon             = "beetle_crate",
		category         = M.CATEGORY_ARENA_PICKUP,
		rarity           = "epic",
		sfx              = "throw",
		pickup_rarity    = "rare",
		default_ammo     = 2,
		desc             = "Банка с жуками: раскалывается и выпускает 3 жуков-диверсантов!",
		desc_en = "A jar of beetles: it cracks open and unleashes 3 saboteur bugs!",
		desc_pt = "Um pote de besouros: racha e solta 3 besouros sabotadores!",
		desc_fr = "Un bocal de doryphores : il se brise et lâche 3 insectes saboteurs !",
		desc_es = "Un tarro de escarabajos: se rompe y suelta 3 bichos saboteadores.",
		desc_tr = "Böcek kavanozu: çatlar ve 3 sabotajcı böceği salar!",
		fire_mode        = "single",
		on_hit           = "beetles",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		wind_sensitivity = 0.75,
		blast_radius     = 20,
		max_damage       = 24,
		blast_force      = 160,
		max_power        = 620,
		power_scale      = 3.2,
		beetle_count     = 3,
		projectile_sprite = "beetle_crate",
		projectile_scale  = 0.9,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- Специальный миньон жука (порождается Колорадским Десантом)
	beetle_minion = {
		id               = "beetle_minion",
		name             = "Колорадский Жук",
		name_en = "Colorado Beetle",
		name_pt = "Besouro-da-Batata",
		name_fr = "Doryphore",
		name_es = "Escarabajo de la Patata",
		name_tr = "Patates Böceği",
		icon             = "beetle_minion",
		category         = M.CATEGORY_INTERNAL,
		rarity           = "epic",
		internal         = true,
		default_ammo     = 0,
		desc             = "Жук-диверсант, грызет клубни и взрывается!",
		desc_en = "A saboteur beetle: gnaws on tubers and explodes!",
		desc_pt = "Besouro sabotador: rói tubérculos e explode!",
		desc_fr = "Un doryphore saboteur : il grignote les tubercules et explose !",
		desc_es = "Un escarabajo saboteador: roe tubérculos y explota.",
		desc_tr = "Sabotajcı böcek: yumruları kemirir ve patlar!",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.4,
		friction         = 0.75,
		fuse_time        = 2.0,
		wind_sensitivity = 0.60,
		blast_radius     = 20,
		max_damage       = 24,
		blast_force      = 180,
		max_power        = 300,
		power_scale      = 2.0,
		projectile_sprite = "beetle_minion",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- Снаряд с дирижабля / Артналет (Оружие на арене)
	air_bomb = {
		id               = "air_bomb",
		name             = "Авиабомба",
		name_en = "Air Bomb",
		name_pt = "Bomba Aérea",
		name_fr = "Bombe Aérienne",
		name_es = "Bomba Aérea",
		name_tr = "Hava Bombası",
		icon             = "air_bomb",
		category         = M.CATEGORY_INTERNAL,
		rarity           = "rare",
		internal         = true,
		default_ammo     = 0,
		desc             = "Снаряд с дирижабля: умеренный урон 30 HP и воронка",
		desc_en = "A zeppelin shell: moderate 30 HP damage and a crater",
		desc_pt = "Projétil de dirigível: dano moderado de 30 HP e uma cratera",
		desc_fr = "Un obus de dirigeable : dégâts modérés de 30 PV et un cratère",
		desc_es = "Proyectil de dirigible: daño moderado de 30 HP y un cráter",
		desc_tr = "Zeplin mermisi: orta düzeyde 30 HP hasar ve bir krater",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.4,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 6.0,
		wind_sensitivity = 0.40,
		blast_radius     = 28,
		max_damage       = 30,
		blast_force      = 200,
		max_power        = 700,
		power_scale      = 3.5,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 1,
			power    = 1,
		},
		projectile_sprite = "air_bomb",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- Бомбочка кассетной бомбы
	bomblet = {
		id               = "bomblet",
		name             = "Бомбочка",
		name_en = "Bomblet",
		name_pt = "Bombinha",
		name_fr = "Petite bombe",
		name_es = "Bombita",
		name_tr = "Küçük Bomba",
		icon             = "p_bomblet",
		category         = M.CATEGORY_INTERNAL,
		internal         = true,
		rarity           = "epic",
		default_ammo     = 0,
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 4.0,
		wind_sensitivity = 0.20,
		blast_radius     = 20,
		max_damage       = 16,
		blast_force      = 120,
		max_power        = 300,
		power_scale      = 2.0,
		spin             = true,
		projectile_sprite = "p_bomblet",
		projectile_scale  = 0.9,
	},

	-- Бомба авиаудара
	airstrike_bomb = {
		id               = "airstrike_bomb",
		name             = "Авиабомба",
		name_en = "Air Bomb",
		name_pt = "Bomba Aérea",
		name_fr = "Bombe Aérienne",
		name_es = "Bomba Aérea",
		name_tr = "Hava Bombası",
		icon             = "p_airbomb",
		category         = M.CATEGORY_INTERNAL,
		internal         = true,
		rarity           = "legendary",
		default_ammo     = 0,
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 6.0,
		wind_sensitivity = 0.0, -- bombs land where the player pointed
		blast_radius     = 26,
		max_damage       = 24,
		blast_force      = 170,
		max_power        = 400,
		power_scale      = 2.0,
		art_angle        = -90,
		projectile_sprite = "p_airbomb",
		projectile_scale  = 0.7,
	},
}

-- Display order: carried weapons first (HUD inventory, arsenal screen), internal shells last
local ORDER = {
	"grenade", "bazooka", "shotgun", "rifle", "burst", "knife", "molotov", "pepper",
	"garlic", "drill", "beetle", "dynamite", "cluster", "homing", "holy_grenade", "airstrike",
	"beetle_minion", "air_bomb", "bomblet", "airstrike_bomb",
}

M.LIST = {}
M.PLAYER_LIST = {}
M.BY_ID = {}
for i, id in ipairs(ORDER) do
	local weapon = DEFS[id]
	weapon.index = i
	weapon.projectile_tint = weapon.projectile_tint or { 1, 1, 1, 1 }
	M.LIST[i] = weapon
	M.BY_ID[id] = weapon
	if not weapon.internal then
		table.insert(M.PLAYER_LIST, weapon)
	end
end

function M.get(id)
	return M.BY_ID[id] or M.LIST[1]
end

function M.get_by_index(idx)
	return M.LIST[idx] or M.LIST[1]
end

function M.count()
	return #M.LIST
end

-- Category queries
function M.is_class_base(id)
	local w = M.get(id)
	return w and (w.category == M.CATEGORY_CLASS_BASE)
end

function M.is_arena_pickup(id)
	local w = M.get(id)
	return w and (w.category == M.CATEGORY_ARENA_PICKUP)
end

function M.get_base_weapons()
	local res = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_CLASS_BASE then
			table.insert(res, w)
		end
	end
	return res
end

function M.get_arena_pickups()
	local res = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_ARENA_PICKUP then
			table.insert(res, w)
		end
	end
	return res
end

function M.get_random_arena_pickup(rarity)
	local pool = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_ARENA_PICKUP then
			if not rarity or w.pickup_rarity == rarity then
				table.insert(pool, w)
			end
		end
	end
	if #pool == 0 then
		return M.get("molotov")
	end
	return pool[math.random(1, #pool)]
end

return M
