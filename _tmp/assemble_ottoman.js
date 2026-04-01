const fs = require('fs');
const path = require('path');

const tmpDir = 'E:\\De Anima\\_tmp';
const targetFile = 'E:\\De Anima\\History\\Medieval\\The Ottoman Empire\\HIST - Ottoman Influence and Presence in the Balkans.md';

let finalContent = `**Metadata:**
- Creation Date: 2026-04-01
- Author: @machiavelli (Orchestrated by GeminiCLI)
- - -
TAGS: #history #empire #geopolitical #ottoman #balkans #ai-generated

# HIST - Ottoman Influence and Presence in the Balkans

`;

const links = [
    '[[HIST - Influence of Islamic Golden Age on the West]]',
    '[[HIST - The First Crusade]]',
    '[[The Ottoman Empire]]',
    '[[HIST - The Arab Spring - A Decade of Upheaval and Transformation]]'
];

for (let i = 1; i <= 10; i++) {
    const chunkPath = path.join(tmpDir, `ottoman-balkans_chunk_${i.toString().padStart(2, '0')}.md`);
    if (fs.existsSync(chunkPath)) {
        let content = fs.readFileSync(chunkPath, 'utf8');
        finalContent += content + '\n\n- - -\n\n';
    }
}

finalContent += `## Related Notes\n`;
links.forEach(l => {
    finalContent += `- ${l}\n`;
});

fs.writeFileSync(targetFile, finalContent);
console.log('Assembled successfully');

// cleanup
for (let i = 1; i <= 10; i++) {
    const chunkPath = path.join(tmpDir, `ottoman-balkans_chunk_${i.toString().padStart(2, '0')}.md`);
    if (fs.existsSync(chunkPath)) {
        fs.unlinkSync(chunkPath);
    }
}
