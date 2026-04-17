const fs = require('fs');
const path = require('path');

const tmpDir = 'E:\\De Anima\\_tmp';
const targetFile = 'E:\\De Anima\\History\\HIST - Evolution of Intellectual Thought in Europe.md';

let finalContent = `**Metadata:**
- Creation Date: 2026-04-01
- Author: @machiavelli (Orchestrated by GeminiCLI)
- - -
TAGS: #history #philosophy #enlightenment #secularism #cli

# HIST - Evolution of Intellectual Thought in Europe

`;

const links = [
    '[[HIST - Influence of Islamic Golden Age on the West]]',
    '[[REAS - From Descartes to Darwin - Innate Existence of God]]',
    '[[REAS - Evolution of Metaphysics in Islam]]',
    '[[REAS - An Effort to Understand Iqbal]]'
];

for (let i = 1; i <= 7; i++) {
    const chunkPath = path.join(tmpDir, `intellectual-thought_chunk_0${i}.md`);
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
for (let i = 1; i <= 7; i++) {
    const chunkPath = path.join(tmpDir, `intellectual-thought_chunk_0${i}.md`);
    if (fs.existsSync(chunkPath)) {
        fs.unlinkSync(chunkPath);
    }
}
