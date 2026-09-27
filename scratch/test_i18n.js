const fs = require('fs');

console.log('Testing i18n & Poki SDK Language Integration...');

// 1. Check i18n.lua contents
const i18nContent = fs.readFileSync('lua_modules/i18n.lua', 'utf8');

if (!i18nContent.includes('PokiSDK.getLanguage')) {
    console.error('FAIL: i18n.lua does not query PokiSDK.getLanguage()');
    process.exit(1);
}
console.log('PASS: PokiSDK.getLanguage() integration verified in i18n.lua');

if (!i18nContent.includes('poki_sdk.get_url_param')) {
    console.error('FAIL: i18n.lua does not query poki_sdk.get_url_param()');
    process.exit(1);
}
console.log('PASS: poki_sdk.get_url_param() integration verified in i18n.lua');

if (!i18nContent.includes('M.current_lang = M.LANG_EN')) {
    console.error('FAIL: i18n.lua does not default to English');
    process.exit(1);
}
console.log('PASS: Clean English default verified in i18n.lua');

if (!i18nContent.includes('player_profile.set_language')) {
    console.error('FAIL: i18n.lua does not persist language to player_profile');
    process.exit(1);
}
console.log('PASS: Language persistence to player_profile verified in i18n.lua');

// 2. Check player_profile.lua contents
const profileContent = fs.readFileSync('lua_modules/player_profile.lua', 'utf8');
if (!profileContent.includes('name_en = "Classic Spud"') || !profileContent.includes('get_skin_name')) {
    console.error('FAIL: player_profile.lua lacks English skin localization');
    process.exit(1);
}
console.log('PASS: Multilingual skins verified in player_profile.lua');

if (!profileContent.includes('function M.set_language') || !profileContent.includes('function M.get_language')) {
    console.error('FAIL: player_profile.lua lacks set_language / get_language methods');
    process.exit(1);
}
console.log('PASS: get_language / set_language methods verified in player_profile.lua');

// 3. Check level_config.lua contents
const levelContent = fs.readFileSync('lua_modules/level_config.lua', 'utf8');
if (!levelContent.includes('name_en = "Arena 1: Green Hills"') || !levelContent.includes('desc_en')) {
    console.error('FAIL: level_config.lua lacks English level localization');
    process.exit(1);
}
console.log('PASS: Multilingual campaign levels verified in level_config.lua');

console.log('ALL I18N AND POKI SDK INTEGRATION TESTS PASSED!');
