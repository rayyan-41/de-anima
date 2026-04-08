const fs = require('fs');
const path = require('path');

const vaultDir = 'E:\\De Anima';
const coreTags = ['transformers', 'diffusion', 'agentic-ai', 'llm', 'slm', 'attention'];
const targetNotePath = 'E:\\De Anima\\Science\\Computer Science\\AI\\Transformer Models vs Diffusion in Agentic AI, LLMs and SLMs.md';

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    for (const file of list) {
        const fullPath = path.join(dir, file);
        if (fullPath.includes('_tmp') || fullPath.includes('.obsidian') || fullPath.includes('.trash') || fullPath.includes('paintings_source')) continue;
        const stat = fs.statSync(fullPath);
        if (stat && stat.isDirectory()) {
            results = results.concat(walk(fullPath));
        } else if (file.endsWith('.md') && fullPath !== targetNotePath) {
            results.push(fullPath);
        }
    }
    return results;
}

const files = walk(vaultDir);
const matches = [];

for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');
    const yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!yamlMatch) continue;
    const yaml = yamlMatch[1];

    let sharedCore = 0;
    const tagsMatch = yaml.match(/^tags:\s*([\s\S]*?)(?:^[a-zA-Z]|\n\n|$)/m);
    if (tagsMatch) {
        const tagsSection = tagsMatch[1];
        for (const tag of coreTags) {
            const tagRegex = new RegExp(`\\b${tag}\\b`, 'i');
            if (tagRegex.test(tagsSection)) {
                sharedCore++;
            }
        }
    }

    if (sharedCore > 0) {
        matches.push({
            file: path.basename(file),
            path: file,
            sharedCore
        });
    }
}

console.log(JSON.stringify(matches, null, 2));