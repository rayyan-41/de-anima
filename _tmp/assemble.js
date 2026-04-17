const fs = require('fs');
const path = require('path');

const tmpDir = 'E:\\De Anima\\_tmp';
const targetFile = 'E:\\De Anima\\Reason\\ARG - The Historical Amnesia of the Islamic Golden Age.md';

let finalContent = `**Metadata:**
- Creation Date: 2026-04-01
- Author: @avicenna (Orchestrated by GeminiCLI)
- - -
TAGS: #reason #philosophy #historiography #epistemology #cli

# ARG - The Historical Amnesia of the Islamic Golden Age

`;

const links = [
    '[[HIST - Influence of Islamic Golden Age on the West]]',
    '[[BIO - Ibn e Sina]]',
    '[[BIO - Al-Ghazali]]',
    '[[REAS - Evolution of Metaphysics in Islam]]'
];

for (let i = 1; i <= 6; i++) {
    const chunkPath = path.join(tmpDir, `historical-amnesia_chunk_0${i}.md`);
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
for (let i = 1; i <= 6; i++) {
    const chunkPath = path.join(tmpDir, `historical-amnesia_chunk_0${i}.md`);
    if (fs.existsSync(chunkPath)) {
        fs.unlinkSync(chunkPath);
    }
}
