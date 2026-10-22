const fs = require('fs');

let content = fs.readFileSync('lua_modules/player_profile.lua', 'utf8');

const startTag = 'M.SKINS = {\n';
const endTag = '\n}\n\nM.SKINS_BY_ID = {}';

const startIdx = content.indexOf(startTag);
const endIdx = content.indexOf(endTag);

if (startIdx === -1 || endIdx === -1) {
  console.error('Could not find start or end tags');
  process.exit(1);
}

const skinsBlock = content.substring(startIdx + startTag.length, endIdx);

// Split into individual skin entries
const entries = skinsBlock.split(/\n\t\{/).filter(s => s.trim().length > 0);
const skinMap = {};

for (const entry of entries) {
  const fullEntry = entry.startsWith('\t{') ? entry : '\t{' + entry;
  const idMatch = fullEntry.match(/id\s*=\s*"([^"]+)"/);
  if (idMatch) {
    skinMap[idMatch[1]] = fullEntry.trimEnd();
  }
}

const desiredOrder = [
  'classic',
  'cap',
  'bandana',
  'helmet',
  'beret',
  'pirate',
  'tophat',
  'wizard',
  'viking',
  'sombrero',
  'king',
  'ushanka',
  'chef'
];

console.log('Parsed skins:', Object.keys(skinMap).length);
const orderedEntries = desiredOrder.map(id => {
  if (!skinMap[id]) throw new Error('Missing skin: ' + id);
  return skinMap[id];
});

const newSkinsBlock = orderedEntries.join(',\n') + ',\n';
const newContent = content.substring(0, startIdx + startTag.length) + newSkinsBlock + content.substring(endIdx + 1);

fs.writeFileSync('lua_modules/player_profile.lua', newContent, 'utf8');
console.log('Successfully reordered skins in player_profile.lua');
