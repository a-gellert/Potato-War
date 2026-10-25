const fs = require('fs');
const content = fs.readFileSync('gui/hud/hud.gui', 'utf8');

const nodes = [];
const blocks = content.split(/nodes\s*\{/);
blocks.forEach((b, idx) => {
  if (idx === 0) return;
  const mId = b.match(/id:\s*"([^"]+)"/);
  const mType = b.match(/type:\s*([^\s]+)/);
  const mParent = b.match(/parent:\s*"([^"]+)"/);
  const mX = b.match(/position\s*\{[^}]*x:\s*([-\d.]+)/);
  const mY = b.match(/position\s*\{[^}]*y:\s*([-\d.]+)/);
  const mTex = b.match(/texture:\s*"([^"]+)"/);
  const mSizeX = b.match(/size\s*\{[^}]*x:\s*([-\d.]+)/);
  const mSizeY = b.match(/size\s*\{[^}]*y:\s*([-\d.]+)/);
  const mXanchor = b.match(/xanchor:\s*([^\s]+)/);
  const mYanchor = b.match(/yanchor:\s*([^\s]+)/);
  const mAlpha = b.match(/alpha:\s*([-\d.]+)/);
  const mEnabled = b.match(/enabled:\s*([^\s]+)/);

  nodes.push({
    id: mId ? mId[1] : null,
    type: mType ? mType[1] : null,
    parent: mParent ? mParent[1] : null,
    x: mX ? parseFloat(mX[1]) : 0,
    y: mY ? parseFloat(mY[1]) : 0,
    tex: mTex ? mTex[1] : null,
    w: mSizeX ? parseFloat(mSizeX[1]) : 0,
    h: mSizeY ? parseFloat(mSizeY[1]) : 0,
    xanchor: mXanchor ? mXanchor[1] : null,
    yanchor: mYanchor ? mYanchor[1] : null,
    alpha: mAlpha ? parseFloat(mAlpha[1]) : 1,
    enabled: mEnabled ? mEnabled[1] : 'true'
  });
});

console.log('Total nodes:', nodes.length);
nodes.filter(n => !n.parent).forEach(n => {
  console.log('Root:', n.id, n.type, 'pos:', n.x, n.y, 'size:', n.w, n.h, 'tex:', n.tex, 'anchor:', n.xanchor, n.yanchor, 'enabled:', n.enabled);
});
