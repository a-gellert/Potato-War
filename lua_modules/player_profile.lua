-- lua_modules/player_profile.lua
-- Persistent storage for player points, unlocked skins, equipped skin, and campaign HP

local M = {}

-- Hats (kept under the historic "skins" name: saves store unlocked_skins / equipped_skin by these ids).
-- rarity drives the card frame in the shop and the drop chance from supply crates.
local function hat(id, image, price, rarity, names, descs)
	local s = { id = id, hat = image, price = price, rarity = rarity, tint = { 1.0, 1.0, 1.0, 1.0 } }
	for lang, v in pairs(names) do
		s["name_" .. lang] = v
	end
	for lang, v in pairs(descs) do
		s["desc_" .. lang] = v
	end
	s.name = names.ru
	s.desc = descs.ru
	return s
end

M.SKINS = {
	hat("classic", "none", 0, "common",
		{ ru = "Без Шапки", en = "Classic Spud", pt = "Sem Chapéu", fr = "Sans chapeau", es = "Sin sombrero", tr = "Şapkasız" },
		{ ru = "Классический бравый боец без головного убора", en = "Classic brave spud without headwear", pt = "Um valente soldado clássico, sem nada na cabeça", fr = "Un brave combattant classique, tête nue", es = "Un valiente soldado clásico, sin nada en la cabeza", tr = "Başlıksız, klasik ve cesur bir savaşçı" }),
	hat("cap", "hat_cap", 100, "common",
		{ ru = "Кепка Бойца", en = "Fighter Cap", pt = "Boné de Combate", fr = "Casquette de Combattant", es = "Gorra de Combate", tr = "Savaşçı Şapkası" },
		{ ru = "Спортивная бейсболка с козырьком", en = "Sporty baseball cap with visor", pt = "Boné esportivo com aba", fr = "Casquette de baseball sportive à visière", es = "Gorra de béisbol deportiva con visera", tr = "Siperlikli sportif beyzbol şapkası" }),
	hat("bandana", "hat_bandana", 250, "common",
		{ ru = "Бандана Ниндзя", en = "Ninja Bandana", pt = "Bandana Ninja", fr = "Bandeau Ninja", es = "Bandana Ninja", tr = "Ninja Bandanası" },
		{ ru = "Боевая повязка скрытного диверсанта", en = "Battle headband of a stealth commando", pt = "Faixa de batalha de um comando furtivo", fr = "Bandeau de combat d'un commando furtif", es = "Cinta de combate de un comando sigiloso", tr = "Gizli bir komandonun savaş bandı" }),
	hat("party", "hat_party", 350, "common",
		{ ru = "Праздничный колпак", en = "Party Hat", pt = "Chapéu de Festa", fr = "Chapeau de fête", es = "Gorro de Fiesta", tr = "Parti Şapkası" },
		{ ru = "Каждый взрыв — как праздничный салют", en = "Every blast is a celebration", pt = "Cada explosão é uma comemoração", fr = "Chaque explosion est une célébration", es = "Cada explosión es una celebración", tr = "Her patlama bir kutlama" }),
	hat("beret", "hat_beret", 450, "rare",
		{ ru = "Берет Десанта", en = "Elite Beret", pt = "Boina de Elite", fr = "Béret d'Élite", es = "Boina de Élite", tr = "Elit Bere" },
		{ ru = "Тактический берет ветерана", en = "Tactical beret of a veteran", pt = "Boina tática de um veterano", fr = "Béret tactique d'un vétéran", es = "Boina táctica de un veterano", tr = "Bir gazinin taktik beresi" }),
	hat("helmet", "hat_helmet", 600, "rare",
		{ ru = "Армейская каска", en = "Army Helmet", pt = "Capacete do Exército", fr = "Casque militaire", es = "Casco Militar", tr = "Asker Miğferi" },
		{ ru = "Каска настоящего ветерана окопов", en = "Helmet of a true trench veteran", pt = "Capacete de um verdadeiro veterano das trincheiras", fr = "Casque d'un vrai vétéran des tranchées", es = "Casco de un auténtico veterano de trincheras", tr = "Gerçek bir siper gazisinin miğferi" }),
	hat("headphones", "hat_headphones", 750, "rare",
		{ ru = "Наушники", en = "Headphones", pt = "Fones de Ouvido", fr = "Casque audio", es = "Auriculares", tr = "Kulaklık" },
		{ ru = "В бой — под любимый трек", en = "Fight to your favourite track", pt = "Lute ao som da sua música favorita", fr = "Se battre sur son morceau préféré", es = "Pelea con tu canción favorita", tr = "En sevdiğin şarkıyla savaş" }),
	hat("tophat", "hat_tophat", 900, "rare",
		{ ru = "Цилиндр Джентльмена", en = "Top Hat", pt = "Cartola", fr = "Haut-de-forme", es = "Chistera", tr = "Silindir Şapka" },
		{ ru = "Изысканный цилиндр с шелковой лентой", en = "Refined top hat with silk ribbon", pt = "Cartola refinada com fita de seda", fr = "Haut-de-forme raffiné avec ruban de soie", es = "Elegante chistera con cinta de seda", tr = "İpek kurdeleli zarif silindir şapka" }),
	hat("chef", "hat_chef", 1050, "epic",
		{ ru = "Колпак повара", en = "Chef Hat", pt = "Chapéu de Chef", fr = "Toque de chef", es = "Gorro de Chef", tr = "Aşçı Şapkası" },
		{ ru = "Шеф картофельной кухни", en = "Head chef of the potato kitchen", pt = "Chef da cozinha de batatas", fr = "Chef de la cuisine des patates", es = "Chef de la cocina de patatas", tr = "Patates mutfağının baş aşçısı" }),
	hat("cowboy", "hat_cowboy", 1250, "epic",
		{ ru = "Ковбойская шляпа", en = "Cowboy Hat", pt = "Chapéu de Caubói", fr = "Chapeau de cowboy", es = "Sombrero Vaquero", tr = "Kovboy Şapkası" },
		{ ru = "Шляпа самого быстрого стрелка", en = "Hat of the fastest gun in the field", pt = "Chapéu do pistoleiro mais rápido", fr = "Le chapeau de la gâchette la plus rapide", es = "Sombrero del pistolero más rápido", tr = "En hızlı silahşorun şapkası" }),
	hat("viking", "hat_viking", 1500, "epic",
		{ ru = "Шлем Викинга", en = "Viking Helmet", pt = "Capacete Viking", fr = "Casque Viking", es = "Casco Vikingo", tr = "Viking Miğferi" },
		{ ru = "Стальной шлем с могучими рогами", en = "Iron helmet flanked by fierce horns", pt = "Elmo de ferro com chifres ferozes", fr = "Casque de fer flanqué de cornes féroces", es = "Casco de hierro con cuernos feroces", tr = "Azgın boynuzlu demir miğfer" }),
	hat("pirate", "hat_pirate", 1800, "epic",
		{ ru = "Пиратская треуголка", en = "Pirate Hat", pt = "Chapéu Pirata", fr = "Chapeau de pirate", es = "Sombrero Pirata", tr = "Korsan Şapkası" },
		{ ru = "Гроза картофельных морей", en = "Terror of the potato seas", pt = "O terror dos mares de batata", fr = "La terreur des mers de patates", es = "El terror de los mares de patata", tr = "Patates denizlerinin korkulu rüyası" }),
	hat("wizard", "hat_wizard", 2200, "legendary",
		{ ru = "Шляпа волшебника", en = "Wizard Hat", pt = "Chapéu de Mago", fr = "Chapeau de sorcier", es = "Sombrero de Mago", tr = "Büyücü Şapkası" },
		{ ru = "Магия взрывчатки", en = "The magic of explosives", pt = "A magia dos explosivos", fr = "La magie des explosifs", es = "La magia de los explosivos", tr = "Patlayıcıların büyüsü" }),
	hat("propeller", "hat_propeller", 2600, "legendary",
		{ ru = "Кепка с пропеллером", en = "Propeller Cap", pt = "Boné de Hélice", fr = "Casquette à hélice", es = "Gorra con Hélice", tr = "Pervaneli Şapka" },
		{ ru = "Почти умеет летать", en = "It can almost fly", pt = "Quase sabe voar", fr = "Elle sait presque voler", es = "Casi sabe volar", tr = "Neredeyse uçabiliyor" }),
	hat("king", "hat_crown", 3000, "legendary",
		{ ru = "Корона Короля", en = "Royal Crown", pt = "Coroa Real", fr = "Couronne Royale", es = "Corona Real", tr = "Kraliyet Tacı" },
		{ ru = "Корона правителя картофельных полей", en = "Crown of the ruler of the potato fields", pt = "Coroa do soberano dos campos de batata", fr = "Couronne du maître des champs de patates", es = "Corona del soberano de los campos de patata", tr = "Patates tarlalarının hükümdarının tacı" }),
}

M.SKINS_BY_ID = {}
for _, s in ipairs(M.SKINS) do
	M.SKINS_BY_ID[s.id] = s
end

-- Aliases for Hat Shop
M.HATS = M.SKINS
M.HATS_BY_ID = M.SKINS_BY_ID

local function skin_field(skin, key, lang)
	lang = lang or "en"
	if lang == "ru" then
		return skin[key .. "_ru"] or skin[key] or ""
	end
	return skin[key .. "_" .. lang] or skin[key .. "_en"] or skin[key] or ""
end

function M.get_skin_name(skin, lang)
	if not skin then return "" end
	return skin_field(skin, "name", lang)
end
M.get_hat_name = M.get_skin_name

function M.get_skin_desc(skin, lang)
	if not skin then return "" end
	return skin_field(skin, "desc", lang)
end
M.get_hat_desc = M.get_skin_desc

-- Profile state
M.data = {
	language = nil,
	points = 0,
	stars = 0,
	squad = {
		{ id = 1, class_id = "recruit" },
		{ id = 2, class_id = "recruit" },
	},
	unlocked_skins = { ["classic"] = true },
	equipped_skin = "classic",
	tutorial_completed = false,
	onboarding_stage = 0,
	campaign_hp = 120,
	campaign_max_hp = 120,
	meta_upgrades = {
		max_hp = 0,
		starting_weapon = 0,
		hp_regen = 0,
	},
	campaign_map = nil,
	campaign_turn = 1,
	campaign_stats = {
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	},
	settings = { sfx = 1.0, music = 0.6 },
	weapon_levels = {},
	blueprints = {},
	commander_xp = 0,
	stats = { battles = 0, wins = 0, kills = 0, crates = 0 },
}

-- Localized status messages (lazy require: i18n loads player_profile lazily)
local function msg_pick(map)
	local ok, i18n = pcall(require, "lua_modules.i18n")
	local lang = (ok and i18n and i18n.current_lang) or "en"
	return map[lang] or map.en
end

local function get_save_path()
	if sys and sys.get_save_file then
		return sys.get_save_file("potato_war", "profile_save")
	end
	return nil
end

function M.load()
	local path = get_save_path()
	local loaded = (path and sys and sys.load) and sys.load(path) or nil
	if loaded and type(loaded) == "table" and loaded.unlocked_skins then
		M.data.language = loaded.language
		M.data.points = loaded.points or 0
		M.data.stars = loaded.stars or 0
		M.data.squad = loaded.squad or {
			{ id = 1, class_id = "recruit" },
			{ id = 2, class_id = "recruit" },
		}
		-- Ensure squad has at least 2 members
		if #M.data.squad < 2 then
			M.data.squad = {
				{ id = 1, class_id = "recruit" },
				{ id = 2, class_id = "recruit" },
			}
		end
		M.data.unlocked_skins = loaded.unlocked_skins or { ["classic"] = true }
		M.data.equipped_skin = loaded.equipped_skin or "classic"
		M.data.campaign_hp = loaded.campaign_hp or 100
		M.data.campaign_max_hp = loaded.campaign_max_hp or 100
		M.data.meta_upgrades = loaded.meta_upgrades or { max_hp = 0, starting_weapon = 0, hp_regen = 0 }
		M.data.campaign_map = loaded.campaign_map
		M.data.campaign_turn = loaded.campaign_turn or 1
		M.data.tutorial_completed = (loaded.tutorial_completed == true)
		M.data.onboarding_stage = loaded.onboarding_stage or (loaded.tutorial_completed and 2 or 0)
		M.data.campaign_stats = loaded.campaign_stats or {
			battles_won = 0,
			battles_lost = 0,
			sectors_conquered = 0,
			sectors_lost = 0,
			counterattacks_repelled = 0,
		}
		M.data.settings = loaded.settings or { sfx = 1.0, music = 0.6 }
		-- Progression (lua_modules/progression.lua)
		M.data.weapon_levels = loaded.weapon_levels or {}
		M.data.blueprints = loaded.blueprints or {}
		M.data.commander_xp = loaded.commander_xp or 0
		M.data.stats = loaded.stats or { battles = 0, wins = 0, kills = 0, crates = 0 }
	else
		M.data.language = nil
		M.data.points = 0
		M.data.stars = 0
		M.data.squad = {
			{ id = 1, class_id = "recruit" },
			{ id = 2, class_id = "recruit" },
		}
		M.data.unlocked_skins = { ["classic"] = true }
		M.data.equipped_skin = "classic"
		M.data.tutorial_completed = false
		M.data.onboarding_stage = 0
		M.data.campaign_hp = 100
		M.data.campaign_max_hp = 100
		M.data.meta_upgrades = { max_hp = 0, starting_weapon = 0, hp_regen = 0 }
		M.data.campaign_map = nil
		M.data.campaign_turn = 1
		M.data.campaign_stats = {
			battles_won = 0,
			battles_lost = 0,
			sectors_conquered = 0,
			sectors_lost = 0,
			counterattacks_repelled = 0,
		}
		M.data.settings = { sfx = 1.0, music = 0.6 }
		M.data.weapon_levels = {}
		M.data.blueprints = {}
		M.data.commander_xp = 0
		M.data.stats = { battles = 0, wins = 0, kills = 0, crates = 0 }
	end
	return M.data
end

function M.save()
	local path = get_save_path()
	if path and sys and sys.save then
		sys.save(path, M.data)
	end
end

function M.get_language()
	return M.data.language
end

function M.set_language(lang)
	if lang == "ru" or lang == "en" or lang == "pt" or lang == "fr" or lang == "es" or lang == "tr" then
		M.data.language = lang
		M.save()
	end
end

-- kind: "sfx" | "music"; 0..1
function M.get_volume(kind)
	local s = M.data.settings or {}
	local v = s[kind]
	if v == nil then
		v = (kind == "music") and 0.6 or 1.0
	end
	return v
end

function M.set_volume(kind, v)
	M.data.settings = M.data.settings or {}
	M.data.settings[kind] = v
	M.save()
end

function M.get_points()
	return M.data.points or 0
end

function M.add_points(amount)
	M.data.points = (M.data.points or 0) + (amount or 0)
	M.save()
	return M.data.points
end

function M.get_stars()
	return M.data.stars or 0
end

function M.add_stars(amount)
	M.data.stars = math.max(0, (M.data.stars or 0) + (amount or 0))
	M.save()
	return M.data.stars
end

function M.spend_stars(amount)
	local cur = M.get_stars()
	if cur >= amount then
		M.data.stars = cur - amount
		M.save()
		return true
	end
	return false
end

-- 1 star = 1000 points
function M.buy_star_with_points()
	if M.get_points() >= 1000 then
		M.data.points = M.data.points - 1000
		M.data.stars = (M.data.stars or 0) + 1
		M.save()
		return true, M.data.stars
	end
	return false, msg_pick({ ru = "Недостаточно очков (требуется 1000 очков)", en = "Not enough points (1000 points required)", pt = "Pontos insuficientes (necessário 1000 pontos)", fr = "Pas assez de points (1000 points requis)", es = "Puntos insuficientes (se requieren 1000 puntos)", tr = "Yeterli puan yok (1000 puan gerekli)" })
end

function M.get_squad()
	if not M.data.squad or #M.data.squad < 2 then
		M.data.squad = {
			{ id = 1, class_id = "recruit" },
			{ id = 2, class_id = "recruit" },
		}
	end
	return M.data.squad
end

-- Squad expansion: 3rd potato costs 3 stars, 4th potato costs 7 stars (max 4)
function M.get_next_potato_unlock_cost()
	local cur_count = #(M.get_squad())
	if cur_count == 2 then
		return 3
	elseif cur_count == 3 then
		return 7
	end
	return nil -- Squad is full (4/4)
end

function M.unlock_next_potato()
	local cost = M.get_next_potato_unlock_cost()
	if not cost then
		return false, msg_pick({ ru = "Максимальный размер банды (4 картошки)", en = "Maximum squad size reached (4 potatoes)", pt = "Tamanho máximo do bando atingido (4 batatas)", fr = "Taille maximale de la bande atteinte (4 patates)", es = "Tamaño máximo de la banda alcanzado (4 patatas)", tr = "Azami çete boyutuna ulaşıldı (4 patates)" })
	end
	if not M.spend_stars(cost) then
		return false, msg_pick({ ru = "Недостаточно звезд", en = "Not enough stars", pt = "Estrelas insuficientes", fr = "Pas assez d'étoiles", es = "Estrellas insuficientes", tr = "Yeterli yıldız yok" })
	end
	local new_id = #(M.data.squad) + 1
	table.insert(M.data.squad, { id = new_id, class_id = "recruit" })
	M.save()
	return true, new_id
end

function M.promote_potato(slot_index, new_class_id, star_cost)
	local sq = M.get_squad()
	local member = sq[slot_index]
	if not member then
		return false, msg_pick({ ru = "Боец не найден", en = "Fighter not found", pt = "Lutador não encontrado", fr = "Combattant introuvable", es = "Combatiente no encontrado", tr = "Savaşçı bulunamadı" })
	end
	star_cost = star_cost or 0
	if star_cost > 0 then
		if not M.spend_stars(star_cost) then
			return false, msg_pick({ ru = "Недостаточно звезд", en = "Not enough stars", pt = "Estrelas insuficientes", fr = "Pas assez d'étoiles", es = "Estrellas insuficientes", tr = "Yeterli yıldız yok" })
		end
	end
	member.class_id = new_class_id
	M.save()
	return true, member
end

function M.is_skin_unlocked(skin_id)
	return M.data.unlocked_skins[skin_id] == true
end
M.is_hat_unlocked = M.is_skin_unlocked

function M.buy_skin(skin_id)
	local skin = M.SKINS_BY_ID[skin_id]
	if not skin then
		return false, msg_pick({ ru = "Скин не найден", en = "Skin not found", pt = "Visual não encontrado", fr = "Apparence introuvable", es = "Aspecto no encontrado", tr = "Görünüm bulunamadı" })
	end
	if M.is_skin_unlocked(skin_id) then
		return true, msg_pick({ ru = "Уже куплен", en = "Already purchased", pt = "Já comprado", fr = "Déjà acheté", es = "Ya comprado", tr = "Zaten satın alındı" })
	end
	if M.get_points() < skin.price then
		return false, msg_pick({ ru = "Недостаточно очков", en = "Not enough points", pt = "Pontos insuficientes", fr = "Pas assez de points", es = "Puntos insuficientes", tr = "Yeterli puan yok" })
	end
	M.data.points = M.data.points - skin.price
	M.data.unlocked_skins[skin_id] = true
	M.data.equipped_skin = skin_id
	M.save()
	return true, msg_pick({ ru = "Куплено", en = "Purchased", pt = "Comprado", fr = "Acheté", es = "Comprado", tr = "Satın alındı" })
end
M.buy_hat = M.buy_skin

function M.equip_skin(skin_id)
	if M.is_skin_unlocked(skin_id) then
		M.data.equipped_skin = skin_id
		M.save()
		return true
	end
	return false
end
M.equip_hat = M.equip_skin

function M.get_equipped_skin()
	local id = M.data.equipped_skin or "classic"
	return M.SKINS_BY_ID[id] or M.SKINS[1]
end
M.get_equipped_hat = M.get_equipped_skin

function M.get_campaign_hp()
	return M.data.campaign_hp or 100
end

function M.set_campaign_hp(hp)
	local max_hp = M.data.campaign_max_hp or 100
	M.data.campaign_hp = math.max(1, math.min(max_hp, hp or max_hp))
	M.save()
end

function M.reset_campaign_hp()
	local max_hp = M.data.campaign_max_hp or 100
	M.data.campaign_hp = max_hp
	M.save()
end

function M.get_upgrade_level(upgrade_id)
	if not M.data.meta_upgrades then
		M.data.meta_upgrades = {}
	end
	return M.data.meta_upgrades[upgrade_id] or 0
end

function M.set_upgrade_level(upgrade_id, level)
	if not M.data.meta_upgrades then
		M.data.meta_upgrades = {}
	end
	M.data.meta_upgrades[upgrade_id] = level or 0
	M.save()
end

function M.get_next_skin_progress()
	local pts = M.get_points()
	for _, skin in ipairs(M.SKINS) do
		if skin.price > 0 and not M.is_skin_unlocked(skin.id) then
			local pct = math.min(1.0, math.max(0.0, pts / skin.price))
			local needed = math.max(0, skin.price - pts)
			return {
				skin = skin,
				hat = skin,
				current_points = pts,
				target_price = skin.price,
				needed = needed,
				percent = pct,
				can_buy = (pts >= skin.price)
			}
		end
	end
	return nil
end
M.get_next_hat_progress = M.get_next_skin_progress

function M.get_campaign_map()
	return M.data.campaign_map
end

function M.set_campaign_map(map_data)
	M.data.campaign_map = map_data
	M.save()
end

function M.get_campaign_turn()
	return M.data.campaign_turn or 1
end

function M.set_campaign_turn(turn)
	M.data.campaign_turn = turn or 1
	M.save()
end

function M.get_campaign_stats()
	return M.data.campaign_stats or {
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	}
end

function M.set_campaign_stats(stats)
	M.data.campaign_stats = stats
	M.save()
end

function M.reset_campaign_progress()
	M.data.campaign_map = nil
	M.data.campaign_turn = 1
	M.data.campaign_stats = {
		battles_won = 0,
		battles_lost = 0,
		sectors_conquered = 0,
		sectors_lost = 0,
		counterattacks_repelled = 0,
	}
	M.save()
end

function M.is_tutorial_completed()
	return M.data.tutorial_completed == true
end

function M.set_tutorial_completed(completed)
	M.data.tutorial_completed = (completed ~= false)
	M.save()
end

function M.get_onboarding_stage()
	return M.data.onboarding_stage or (M.data.tutorial_completed and 2 or 0)
end

function M.set_onboarding_stage(stage)
	M.data.onboarding_stage = stage or 0
	M.save()
end

function M.unlock_hat(skin_id)
	if not skin_id or not M.SKINS_BY_ID[skin_id] then return false end
	M.data.unlocked_skins[skin_id] = true
	M.save()
	return true
end
M.unlock_skin = M.unlock_hat

-- Initialize by loading on startup
M.load()

return M
