const fs = require('fs');
const path = require('path');

for (const sid of ['6922df57-22ad-4734-a16f-e70198c886a5', '0e70b8da-45a3-4eb3-b514-09d457625345']) {
  const p = path.join('C:\\Users\\gellert.alexandr\\.gemini\\antigravity\\brain', sid, '.system_generated', 'logs', 'transcript.jsonl');
  if (!fs.existsSync(p)) continue;
  console.log(`=== SESSION ${sid} ===`);
  const lines = fs.readFileSync(p, 'utf8').split('\n');
  for (const line of lines) {
    if (!line.trim()) continue;
    try {
      const obj = JSON.parse(line);
      if (obj.type === 'USER_INPUT') {
        console.log(`USER: ${obj.content}\n`);
      }
    } catch(e) {}
  }
}
