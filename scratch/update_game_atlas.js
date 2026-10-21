const fs = require('fs');
const path = require('path');

const atlasPath = path.resolve(__dirname, '../main/assets/game.atlas');
let content = fs.readFileSync(atlasPath, 'utf8');

if (!content.includes('hp_frame.png')) {
    const isCrlf = content.includes('\r\n');
    const le = isCrlf ? '\r\n' : '\n';
    const addition = `images {${le}  image: "/main/assets/hp_frame.png"${le}}${le}images {${le}  image: "/main/assets/spore.png"${le}}${le}`;
    content = content.replace('extrude_borders: 2', addition + 'extrude_borders: 2');
    fs.writeFileSync(atlasPath, content, 'utf8');
    console.log("Added hp_frame and spore to game.atlas");
} else {
    console.log("Already contains hp_frame in game.atlas");
}
