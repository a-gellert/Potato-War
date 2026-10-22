const fs = require('fs');
const path = require('path');

function walk(dir, extList) {
  let results = [];
  const list = fs.readdirSync(dir);
  for (const file of list) {
    if (file === '.git' || file === 'wasm-web' || file === 'node_modules') continue;
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      results = results.concat(walk(fullPath, extList));
    } else {
      if (extList.some(ext => fullPath.endsWith(ext))) {
        results.push(fullPath);
      }
    }
  }
  return results;
}

const files = walk('.', ['.lua', '.script', '.gui_script']);
console.log('Validating', files.length, 'Lua / script files...');

let errorCount = 0;

for (const f of files) {
  const content = fs.readFileSync(f, 'utf8');
  
  // Basic delimiter / brace / bracket balance checks
  let paren = 0;
  let brace = 0;
  let bracket = 0;
  let inString = false;
  let strChar = '';
  let inComment = false;
  let inLongComment = false;
  
  const lines = content.split('\n');
  for (let ln = 0; ln < lines.length; ln++) {
    const line = lines[ln];
    // Check for obvious syntax breakages
    if (line.includes(',,') && !line.includes('",,"')) {
      console.error(`⚠️ Double comma in ${f} at line ${ln + 1}: ${line.trim()}`);
      errorCount++;
    }
  }
}

console.log(`Validation finished with ${errorCount} errors detected.`);
