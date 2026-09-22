import sys
import re

filepath = r'c:\Users\gellert.alexandr\Desktop\D_Projects\Potato War\gui\hud\hud.gui'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# find the weapon_panel and replace its size
content = re.sub(r'(id: "weapon_panel"[^}]*?size \{\n\s*x: )380\.0', r'\g<1>960.0', content)

start_str = 'nodes {\n  position {\n    x: -120.0\n  }\n  size {\n    x: 110.0\n    y: 44.0'
end_str = '  id: "txt_knife"\n  parent: "btn_knife"\n  inherit_alpha: true\n  outline_alpha: 0.0\n  shadow_alpha: 0.0\n}'

idx1 = content.find(start_str)
idx2 = content.find(end_str) + len(end_str)

if idx1 == -1 or idx2 == -1:
    print('Failed to find replace span')
    sys.exit(1)

labels = [
    '1 Граната', '2 Винтовка', '3 Нож', '4 Молотов', 
    '5 Автомат', '6 Базука', '7 Дробовик', '8 Св.Граната'
]

x_start = -402.5
spacing = 115.0

new_nodes = []

for i in range(8):
    x_pos = int(x_start + i * spacing)
    node_str = f'''nodes {{
  position {{
    x: {x_pos}.0
  }}
  size {{
    x: 108.0
    y: 36.0
  }}
  color {{
    x: 0.22
    y: 0.28
    z: 0.35
  }}
  type: TYPE_BOX
  texture: "game/box"
  id: "btn_wpn_{i+1}"
  parent: "weapon_panel"
  inherit_alpha: true
  slice9 {{
    x: 4.0
    y: 4.0
    z: 4.0
    w: 4.0
  }}
}}
nodes {{
  scale {{
    x: 0.4
    y: 0.4
  }}
  size {{
    x: 100.0
    y: 30.0
  }}
  type: TYPE_TEXT
  text: "{labels[i]}"
  font: "system_font"
  id: "txt_wpn_{i+1}"
  parent: "btn_wpn_{i+1}"
  inherit_alpha: true
  outline_alpha: 0.0
  shadow_alpha: 0.0
}}'''
    new_nodes.append(node_str)

new_content = content[:idx1] + '\n'.join(new_nodes) + content[idx2:]

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Success')
