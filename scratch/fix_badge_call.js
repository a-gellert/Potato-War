const fs = require('fs');

const path = 'gui/hud/hud.gui_script';
const raw = fs.readFileSync(path, 'utf8');
const isCRLF = raw.includes('\r\n');
const nl = isCRLF ? '\r\n' : '\n';

const lines = raw.split(/\r?\n/);

// 1. Remove line 129 (\t\tupdate_fighter_badges(self, dt)) inside update_squad_widget
for (let i = 0; i < 200; i++) {
  if (lines[i].includes('local function update_squad_widget') && lines[i + 1].includes('update_fighter_badges')) {
    console.log('Removing bad update_fighter_badges call at line', i + 2);
    lines.splice(i + 1, 1);
    break;
  }
}

// 2. Add update_fighter_badges(self, dt) in update(self, dt) after update_squad_widget(self)
for (let i = 500; i < lines.length; i++) {
  if (lines[i].trim() === 'update_squad_widget(self)') {
    console.log('Adding update_fighter_badges(self, dt) at line', i + 2);
    lines.splice(i + 1, 0, '\t\tupdate_fighter_badges(self, dt)');
    break;
  }
}

fs.writeFileSync(path, lines.join(nl), 'utf8');
console.log('Fixed hud.gui_script successfully!');
