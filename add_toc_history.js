const fs = require('fs');
const path = require('path');

const historyDir = path.join(__dirname, 'History');

function walkDir(dir) {
    let results = [];
    if (!fs.existsSync(dir)) return results;
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat && stat.isDirectory()) {
            results = results.concat(walkDir(filePath));
        } else if (file.endsWith('.md')) {
            results.push(filePath);
        }
    });
    return results;
}

const files = walkDir(historyDir);

files.forEach(file => {
    const filename = path.basename(file);
    if (filename.includes('Map of Content')) return;

    let content = fs.readFileSync(file, 'utf8');
    const wordCount = content.split(/\s+/).filter(w => w.length > 0).length;

    let threshold = 1000;
    if (filename.includes('BIO') || filename.includes('EMP')) {
        threshold = 1500;
    } else if (file.includes('Contemporary') || file.includes('Geopolitical')) {
        threshold = 5000;
    }

    if (wordCount >= threshold) {
        // Generate TOC
        const lines = content.split('\n');
        let inCodeBlock = false;
        const tocLines = ['## Table of Contents\n'];
        let hasHeaders = false;

        // Skip if TOC already exists
        if (content.includes('## Table of Contents')) return;

        for (let line of lines) {
            if (line.startsWith('```')) {
                inCodeBlock = !inCodeBlock;
                continue;
            }
            if (inCodeBlock) continue;

            const match = line.match(/^(#{2,4})\s+(.+)/);
            if (match && match[2].trim() !== 'See Also' && match[2].trim() !== 'Table of Contents') {
                hasHeaders = true;
                const level = match[1].length;
                const title = match[2].trim();
                const link = title.toLowerCase().replace(/[^\w\s-]/g, '').replace(/\s+/g, '-');
                const indent = '  '.repeat(level - 2);
                tocLines.push(`${indent}- [${title}](#${link})`);
            }
        }

        if (hasHeaders) {
            const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
            if (yamlMatch) {
                const yamlBlock = yamlMatch[0];
                const restOfContent = content.slice(yamlBlock.length);
                const newContent = `${yamlBlock}\n\n${tocLines.join('\n')}\n${restOfContent}`;
                fs.writeFileSync(file, newContent, 'utf8');
                console.log(`Added TOC to ${filename} (Word count: ${wordCount}, Threshold: ${threshold})`);
            }
        }
    }
});
console.log("Done adding TOC to History notes.");