-- lua_modules/weapons.lua
-- Centralized weapon definitions, elemental statuses, and arena pickups for Potato War
-- All weapon stats and elemental interactions are data-driven from this module.

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

M.LIST = {
	-- 1. Горячая Картошка (Граната) — Базовое оружие (Новобранец / универсал)
	{
		id               = "grenade",
		name             = "Горячая Картошка",
		name_en = "Hot Potato",
		name_pt = "Batata Quente",
		name_fr = "Patate Chaude",
		name_es = "Patata Caliente",
		name_tr = "Sıcak Patates",
		key_label        = "1",
		icon             = "grenade",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = -1, -- Unlimited!
		desc             = "Прыгучий горячий клубень с тикающим фитилем и мощным кратером",
		desc_en = "A bouncy hot tuber with a ticking fuse and a mighty crater",
		desc_pt = "Um tubérculo quente e saltitante com pavio tiquetaqueando e uma cratera poderosa",
		desc_fr = "Un tubercule brûlant et rebondissant, mèche qui tictaque et cratère monstrueux",
		desc_es = "Un tubérculo caliente y saltarín con mecha en cuenta atrás y un cráter enorme",
		desc_tr = "Zıplayan, sıcak bir yumru: fitili tik tak işliyor, bıraktığı krater devasa",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.55,
		friction         = 0.82,
		fuse_time        = 3.0,
		wind_sensitivity = 0.85, -- Standard wind drift
		blast_radius     = 36,
		max_damage       = 30,
		blast_force      = 180,
		max_power        = 600,
		power_scale      = 3.2,
		projectile_sprite = "grenade",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 2. Шампур-Снайпер (Винтовка) — Базовое оружие (Снайпер)
	{
		id               = "rifle",
		name             = "Шампур-Снайпер",
		name_en = "Skewer Sniper",
		name_pt = "Espeto Atirador",
		name_fr = "Brochette Sniper",
		name_es = "Brocheta Francotiradora",
		name_tr = "Şiş Keskin Nişancı",
		key_label        = "2",
		icon             = "skewer_rifle",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 3,
		desc             = "Заостренная бамбуковая шпажка — точечное пробитие насквозь",
		desc_en = "A sharpened bamboo skewer: precision piercing straight through",
		desc_pt = "Um espeto de bambu afiado: perfuração precisa de lado a lado",
		desc_fr = "Une brochette de bambou taillée en pointe : transpercement précis de part en part",
		desc_es = "Un pincho de bambú afilado: perforación precisa de lado a lado",
		desc_tr = "Sivriltilmiş bambu şiş: hedefi tam isabetle delip geçer",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 0.12,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 5.0,
		speed            = 950,
		wind_sensitivity = 0.28, -- Heavy, minimal wind drift!
		blast_radius     = 14,
		max_damage       = 45,
		blast_force      = 150,
		max_power        = 950,
		power_scale      = 4.8,
		projectile_sprite = "skewer_dart",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 3. Боевой Топор (Нож / Ближний бой) — Базовое оружие в стиле референса
	{
		id               = "knife",
		name             = "Боевой Топор",
		name_en = "Potato Peeler",
		name_pt = "Descascador",
		name_fr = "Épluche-Patates",
		name_es = "Pelapatatas",
		name_tr = "Patates Soyacağı",
		key_label        = "3",
		icon             = "knife",
		category         = M.CATEGORY_CLASS_BASE,
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

	-- 4. Фритюрное масло (Молотов) — Оружие на арене (Стихия Огня: Burning)
	{
		id               = "molotov",
		name             = "Фритюрное масло",
		name_en = "Frying Oil",
		name_pt = "Óleo de Fritura",
		name_fr = "Huile de Friture",
		name_es = "Aceite de Freír",
		name_tr = "Kızartma Yağı",
		key_label        = "4",
		icon             = "oil_bottle",
		category         = M.CATEGORY_ARENA_PICKUP,
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

	-- 5. Фри-автомат (Автомат) — Базовое оружие (Штурмовик)
	{
		id               = "burst",
		name             = "Фри-автомат",
		name_en = "Fry-O-Matic",
		name_pt = "Frita-Mática",
		name_fr = "Frito-Matic",
		name_es = "Fri-Automática",
		name_tr = "Kızartmatik",
		key_label        = "5",
		icon             = "rifle",
		category         = M.CATEGORY_CLASS_BASE,
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

	-- 6. Пюре-Базука (Базука) — Базовое оружие (Артиллерист / Ракетчик: Glued)
	{
		id               = "bazooka",
		name             = "Пюре-Базука",
		name_en = "Mash-Zooka",
		name_pt = "Purê-Bazuca",
		name_fr = "Purée-Zooka",
		name_es = "Puré-Bazuca",
		name_tr = "Püre-Bazuka",
		key_label        = "6",
		icon             = "masher_bazooka",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 2,
		desc             = "Ракетница-толкушка: облепляет цель густым пюре и замедляет (Клей)",
		desc_en = "Masher launcher: smothers the target in thick mash and slows it down (Glue)",
		desc_pt = "Lança-purê: cobre o alvo de purê grosso e o deixa lento (Cola)",
		desc_fr = "Lance-pilon : nappe la cible de purée épaisse et la ralentit (Colle)",
		desc_es = "Lanzapuré: cubre al objetivo de puré espeso y lo ralentiza (Pegamento)",
		desc_tr = "Ezme fırlatıcı: hedefi koyu pürede boğar ve yavaşlatır (Yapışkan)",
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
		projectile_sprite = "masher_rocket",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 7. Кухонная Тёрка (Дробовик) — Базовое оружие (Штурмовик / Сапер)
	{
		id               = "shotgun",
		name             = "Кухонная Тёрка",
		name_en = "Kitchen Grater",
		name_pt = "Ralador de Cozinha",
		name_fr = "Râpe de Cuisine",
		name_es = "Rallador de Cocina",
		name_tr = "Mutfak Rendesi",
		key_label        = "7",
		icon             = "grater",
		category         = M.CATEGORY_CLASS_BASE,
		default_ammo     = 3,
		desc             = "Веер острых картофельных чипсов — смертельно вблизи, сносится ветром!",
		desc_en = "A fan of sharp potato chips: deadly up close, blown away by the wind!",
		desc_pt = "Um leque de chips de batata afiados: mortal de perto, mas o vento leva embora!",
		desc_fr = "Un éventail de chips tranchantes : mortel de près, emporté par le vent !",
		desc_es = "Un abanico de patatas fritas afiladas: mortal de cerca, ¡el viento se las lleva!",
		desc_tr = "Keskin patates cipsi yelpazesi: yakında ölümcül, rüzgârda savrulur!",
		fire_mode        = "spread",
		on_hit           = "explode",
		shot_count       = 5,
		spread_angle     = 0.35,
		gravity_mult     = 0.3,
		bounciness       = 0.0,
		friction         = 1.0,
		fuse_time        = 3.0,
		speed            = 750,
		wind_sensitivity = 1.35, -- Light chips get easily pushed by wind!
		blast_radius     = 10,
		max_damage       = 22,
		blast_force      = 180,
		max_power        = 750,
		power_scale      = 4.0,
		projectile_sprite = "potato_chip",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 8. Золотой Клубень (Святая граната) — Оружие на арене (Легендарное)
	{
		id               = "holy_grenade",
		name             = "Золотой Клубень",
		name_en = "Holy Spud",
		name_pt = "Tubérculo Dourado",
		name_fr = "Tubercule Doré",
		name_es = "Tubérculo Dorado",
		name_tr = "Altın Yumru",
		key_label        = "8",
		icon             = "holy_spud",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "legendary",
		default_ammo     = 1,
		desc             = "Священная золотая картофелина — колоссальный божественный бабах!",
		desc_en = "A sacred golden potato: a colossal divine boom!",
		desc_pt = "Uma batata dourada sagrada: um estrondo divino colossal!",
		desc_fr = "Une pomme de terre dorée sacrée : un boum divin colossal !",
		desc_es = "Una patata dorada sagrada: ¡un estallido divino colosal!",
		desc_tr = "Kutsal altın patates: devasa, ilahi bir gümbürtü!",
		fire_mode        = "single",
		on_hit           = "explode",
		gravity_mult     = 1.0,
		bounciness       = 0.6,
		friction         = 0.78,
		fuse_time        = 4.0,
		wind_sensitivity = 0.70,
		blast_radius     = 55,
		max_damage       = 80,
		blast_force      = 250,
		max_power        = 580,
		power_scale      = 3.0,
		status_effect    = {
			type     = M.STATUS_TYPES.CONCUSSED,
			duration = 2,
			power    = 1,
		},
		projectile_sprite = "holy_spud",
		projectile_scale  = 1.0,
		projectile_tint   = {1, 1, 1, 1},
	},

	-- 9. Колорадский Десант (Банка с жуками) — Оружие на арене (Редкое)
	{
		id               = "beetle",
		name             = "Колорадский Десант",
		name_en = "Beetle Swarm",
		name_pt = "Desembarque de Besouros",
		name_fr = "Débarquement de Doryphores",
		name_es = "Desembarco de Escarabajos",
		name_tr = "Böcek Çıkarması",
		key_label        = "9",
		icon             = "beetle_crate",
		category         = M.CATEGORY_ARENA_PICKUP,
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

	-- 10. Грядковый Бур (Пробитие террейна) — Базовое оружие (Сапер)
	{
		id               = "drill",
		name             = "Грядковый Бур",
		name_en = "Garden Drill",
		name_pt = "Broca de Canteiro",
		name_fr = "Foret Potager",
		name_es = "Taladro de Huerto",
		name_tr = "Bahçe Matkabı",
		key_label        = "10",
		icon             = "drill_missile",
		category         = M.CATEGORY_CLASS_BASE,
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

	-- 11. Перцемолка «Острый Чили» — Оружие на арене / Базовое (Медик: Poisoned)
	{
		id               = "pepper",
		name             = "Перцемолка «Чили»",
		name_en = "Chili Pepper Mill",
		name_pt = "Moedor de Pimenta Chili",
		name_fr = "Moulin à Piment Chili",
		name_es = "Molinillo de Chile",
		name_tr = "Acı Biber Değirmeni",
		key_label        = "11",
		icon             = "pepper_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
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

	-- 12. Чесночный Динамит — Оружие на арене (Concussed)
	{
		id               = "garlic",
		name             = "Чесночный Динамит",
		name_en = "Garlic Dynamite",
		name_pt = "Dinamite de Alho",
		name_fr = "Dynamite à l'Ail",
		name_es = "Dinamita de Ajo",
		name_tr = "Sarımsak Dinamiti",
		key_label        = "12",
		icon             = "garlic_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
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

	-- Специальный миньон жука (порождается Колорадским Десантом)
	{
		id               = "beetle_minion",
		name             = "Колорадский Жук",
		name_en = "Colorado Beetle",
		name_pt = "Besouro-da-Batata",
		name_fr = "Doryphore",
		name_es = "Escarabajo de la Patata",
		name_tr = "Patates Böceği",
		key_label        = "",
		icon             = "beetle_minion",
		category         = M.CATEGORY_ARENA_PICKUP,
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
	{
		id               = "air_bomb",
		name             = "Авиабомба",
		name_en = "Air Bomb",
		name_pt = "Bomba Aérea",
		name_fr = "Bombe Aérienne",
		name_es = "Bomba Aérea",
		name_tr = "Hava Bombası",
		key_label        = "",
		icon             = "air_bomb",
		category         = M.CATEGORY_ARENA_PICKUP,
		pickup_rarity    = "rare",
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
}

-- Build fast lookup by id
M.BY_ID = {}
for i, weapon in ipairs(M.LIST) do
	M.BY_ID[weapon.id] = weapon
	weapon.index = i
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
		if w.category == M.CATEGORY_ARENA_PICKUP and w.id ~= "beetle_minion" then
			table.insert(res, w)
		end
	end
	return res
end

function M.get_random_arena_pickup(rarity)
	local pool = {}
	for _, w in ipairs(M.LIST) do
		if w.category == M.CATEGORY_ARENA_PICKUP and w.id ~= "beetle_minion" then
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
