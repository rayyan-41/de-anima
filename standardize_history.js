const fs = require('fs');
const path = require('path');

const historyDir = path.join(__dirname, 'History');

// Helper to recursively find markdown files
function walkDir(dir) {
    let results = [];
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
const prefixes = ['BIO - ', 'HIST - ', 'EMP - ', 'HRE- ', 'OTT- '];

function stripPrefix(name) {
    for (let p of prefixes) {
        if (name.startsWith(p)) return name.slice(p.length);
    }
    return name;
}

files.forEach(file => {
    const filename = path.basename(file);
    if (filename.includes('Map of Content')) return; // Skip MOCs

    let content = fs.readFileSync(file, 'utf8');

    // Remove wikilinks: [[Link|Text]] -> Text, [[Link]] -> Link
    content = content.replace(/\[\[(?:[^|\]]*\|)?([^\]]+)\]\]/g, '$1');

    // Remove Related Notes section
    const relatedNotesIndex = content.search(/^## Related Notes/m);
    if (relatedNotesIndex !== -1) {
        content = content.slice(0, relatedNotesIndex).trim() + '\n';
    }

    // Determine category based on path or filename
    let category = 'Medieval';
    if (file.includes('Biographies')) category = 'Biography';
    else if (file.includes('Contemporary')) category = 'Contemporary';
    else if (filename.includes('EMP')) category = 'Empire';
    else if (filename.includes('Geopolitical')) category = 'Geopolitical';

    // Parse existing tags or generate basic ones
    let existingTags = [];
    const yamlMatch = content.match(/^---\n([\s\S]*?)\n---/);
    let restOfContent = content;
    
    if (yamlMatch) {
        restOfContent = content.slice(yamlMatch[0].length).trim();
        const yaml = yamlMatch[1];
        const tagsMatch = yaml.match(/tags:\s*\[(.*?)\]/);
        if (tagsMatch && tagsMatch[1]) {
            existingTags = tagsMatch[1].split(',').map(t => t.trim().replace(/^#/, ''));
        } else {
            const listTags = yaml.match(/tags:\n([\s\S]*?)(?=\n[a-z]+:|\n---|$)/);
            if (listTags) {
                existingTags = listTags[1].split('\n')
                    .filter(line => line.trim().startsWith('-'))
                    .map(line => line.replace(/-\s*#?/, '').trim());
            }
        }
    }

    const newTitle = stripPrefix(filename.replace('.md', ''));
    
    let topicTags = existingTags.filter(t => t && t.toLowerCase() !== 'history' && t.toLowerCase() !== category.toLowerCase() && t.toLowerCase() !== 'ai-generated');
    if (topicTags.length === 0) topicTags = [newTitle.toLowerCase().replace(/[^a-z0-9]/g, '-')];
    // Keep to max ~8 topic tags
    topicTags = topicTags.slice(0, 8);

    const allTags = ['history', category.toLowerCase(), ...topicTags, 'ai-generated'];
    
    const newYaml = `---
title: "${newTitle}"
date: 2026-04-01
domain: History
category: ${category}
status: complete
tags: [${allTags.join(', ')}]
---`;

    const newContent = `${newYaml}\n\n${restOfContent}\n`;

    const newFilename = newTitle + '.md';
    const newFilePath = path.join(path.dirname(file), newFilename);

    fs.writeFileSync(file, newContent, 'utf8');
    if (file !== newFilePath) {
        fs.renameSync(file, newFilePath);
        console.log(`Renamed: ${filename} -> ${newFilename}`);
    } else {
        console.log(`Updated: ${filename}`);
    }
});

console.log("Done updating and renaming history files.");
