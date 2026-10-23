-- gui/main_menu/menu_data.lua
-- Static option lists for the quick-battle lobby.

local M = {}

M.BIOMES = {
	{ id = "grass", ru = "Зеленые Холмы", en = "Green Meadows", pt = "Prados Verdes", fr = "Prairies vertes", es = "Prados Verdes", tr = "Yeşil Çayırlar" },
	{ id = "arctic", ru = "Ледяной архипелаг", en = "Arctic Ice", pt = "Gelo Ártico", fr = "Glace arctique", es = "Hielo Ártico", tr = "Arktik Buz" },
	{ id = "desert", ru = "Пустынные Дюны", en = "Desert Dunes", pt = "Dunas do Deserto", fr = "Dunes du désert", es = "Dunas del Desierto", tr = "Çöl Kumulları" },
	{ id = "volcano", ru = "Лавовые Пещеры", en = "Lava Caverns", pt = "Cavernas de Lava", fr = "Cavernes de lave", es = "Cavernas de Lava", tr = "Lav Mağaraları" },
	{ id = "alien", ru = "Инопланетный Мир", en = "Alien World", pt = "Mundo Alienígena", fr = "Monde extraterrestre", es = "Mundo Alienígena", tr = "Uzaylı Dünyası" },
}

M.RELIEFS = {
	{ id = "hills", ru = "Холмы", en = "Hills", pt = "Colinas", fr = "Collines", es = "Colinas", tr = "Tepeler" },
	{ id = "floating_islands", ru = "Парящие Острова", en = "Floating Islands", pt = "Ilhas Flutuantes", fr = "Îles flottantes", es = "Islas Flotantes", tr = "Yüzen Adalar" },
	{ id = "canyon_bridge", ru = "Каньон и Мост", en = "Canyon Bridge", pt = "Cânion e Ponte", fr = "Canyon et pont", es = "Cañón y Puente", tr = "Kanyon ve Köprü" },
	{ id = "cavern", ru = "Пещеры", en = "Caverns", pt = "Cavernas", fr = "Cavernes", es = "Cavernas", tr = "Mağaralar" },
	{ id = "bunkers", ru = "Бункеры", en = "Bunkers", pt = "Bunkers", fr = "Bunkers", es = "Búnkeres", tr = "Sığınaklar" },
	{ id = "islands", ru = "Острова", en = "Islands", pt = "Ilhas", fr = "Îles", es = "Islas", tr = "Adalar" },
	{ id = "swiss_cheese", ru = "Сырный Каньон", en = "Swiss Cheese", pt = "Queijo Suíço", fr = "Gruyère", es = "Queso Suizo", tr = "İsviçre Peyniri" },
	{ id = "flat", ru = "Равнина", en = "Flat Field", pt = "Campo Plano", fr = "Terrain plat", es = "Campo Llano", tr = "Düz Arazi" },
}

return M
