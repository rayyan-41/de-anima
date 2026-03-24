const fs = require('fs');
const path = require('path');
const dir = 'E:\\De Anima\\Islam\\Fiqh\\Ibadat';
const chunks = ['chunk1.md', 'chunk2.md', 'chunk3.md', 'chunk4.md', 'chunk5.md'];

let content = '---\n' +
  'date: 2026-03-24\n' +
  'tags: [islam, fiqh, ibadat, hanafi, maliki, shafii, hanbali]\n' +
  'aliases: ["Salat al-Witr", "The Witr Prayer", "Fiqh of Witr"]\n' +
  '---\n\n' +
  '# FIQH - The Prayer of Witr: Rulings, Methodologies, and Variations Across the Four Madhabs\n\n';

for (const chunk of chunks) {
  content += fs.readFileSync(path.join(dir, chunk), 'utf-8') + '\n\n- - -\n\n';
}

fs.writeFileSync(path.join(dir, 'FIQH - The Prayer of Witr.md'), content);
console.log('Combined successfully');
