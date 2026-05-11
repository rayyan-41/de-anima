const fs = require('fs');
const path = require('path');

const slug = 'historical-ascent-reason';
const chunksDir = 'E:\\De Anima\\_tmp';
const outputFile = 'E:\\De Anima\\Reason\\The Historical Ascent of Reason and the Absolute Idea.md';

let content = `---
title: "The Historical Ascent of Reason and the Absolute Idea"
domain: reason
category: philosophy
status: complete
tags:
  - reason
  - philosophy
  - reason/philosophy
  - hegel
  - absolute-idea
  - dialectic
  - history-of-philosophy
  - logic
  - cli
---

`;

for(let i=1; i<=6; i++) {
    const file = path.join(chunksDir, `${slug}_chunk_0${i}.md`);
    if(fs.existsSync(file)) {
        content += fs.readFileSync(file, 'utf8').trim() + '\n\n- - -\n\n';
    }
}

content = content.replace(/\n\n- - -\n\n$/, '\n');
fs.writeFileSync(outputFile, content, 'utf8');
console.log('Assembled to ' + outputFile);
