const fs = require('fs');

const files = [
    "E:\\De Anima\\History\\Historical Narratives\\Influence of Islamic Golden Age on the West.md",
    "E:\\De Anima\\Reason\\the Epistemic Gap and the Necessity of Revelation.md",
    "E:\\De Anima\\Reason\\The Historical Amnesia of the Islamic Golden Age.md"
];

files.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    if (content.includes('## Table of Contents') || content.includes('[!abstract] Table of Contents')) {
        console.log('Skipping (already has TOC):', file);
        return;
    }

    const lines = content.split('\n');
    const tocLines = ['## Table of Contents\n'];
    let hasHeaders = false;
    let inCodeBlock = false;

    for (let line of lines) {
        if (line.startsWith('```')) {
            inCodeBlock = !inCodeBlock;
            continue;
        }
        if (inCodeBlock) continue;

        // Match # or ## or ### etc.
        const match = line.match(/^(#{1,6})\s+(.+)/);
        if (match) {
            const title = match[2].trim();
            if (title === 'Table of Contents' || title === 'See Also') continue;
            hasHeaders = true;
            
            const level = match[1].length;
            const indentLevel = level > 1 ? level - 1 : 0;
            const indent = '  '.repeat(indentLevel);
            
            // Basic slugification
            const link = title.toLowerCase().replace(/[^\w\s-]/g, '').replace(/\s+/g, '-');
            tocLines.push(`${indent}- [${title}](#${link})`);
        }
    }

    if (hasHeaders) {
        // Insert after YAML frontmatter
        const yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
        if (yamlMatch) {
            const yamlBlock = yamlMatch[0];
            const restOfContent = content.slice(yamlBlock.length);
            const newContent = `${yamlBlock}\n${tocLines.join('\n')}\n\n${restOfContent}`;
            fs.writeFileSync(file, newContent, 'utf8');
            console.log('Added TOC to', file);
        } else {
            console.log('No YAML frontmatter found in', file);
        }
    }
});