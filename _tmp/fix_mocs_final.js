const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'E:\\De Anima';

function walkDir(dir, callback) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (!['.trash', 'node_modules', '.obsidian', '.git', '_tmp', 'paintings_source'].includes(file)) {
                walkDir(fullPath, callback);
            }
        } else {
            if (file.includes('Map of Contents') && file.endsWith('.md')) {
                callback(fullPath);
            }
        }
    }
}

const mocs = [];
walkDir(VAULT_ROOT, (p) => mocs.push(p));

// Delete the legacy science MOC if it exists
const legacyScienceMoc = path.join(VAULT_ROOT, 'Science', '_Science - Map of Contents.md');
if (fs.existsSync(legacyScienceMoc)) {
    fs.unlinkSync(legacyScienceMoc);
    console.log(`Deleted legacy: ${legacyScienceMoc}`);
}

mocs.forEach(p => {
    if (p === legacyScienceMoc) return;

    let content = fs.readFileSync(p, 'utf8');

    // 1. Extract YAML
    let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!yamlMatch) return;
    let yaml = yamlMatch[0];

    // 2. Extract Quote and Intro
    let afterYaml = content.slice(yaml.length).trim();
    let introBlock = "";
    
    // Sometimes there are extra separators or headers before Structure
    let structureIndex = afterYaml.indexOf('## Structure');
    if (structureIndex !== -1) {
        introBlock = afterYaml.slice(0, structureIndex).trim();
    } else {
        introBlock = afterYaml;
    }
    
    // Clean up intro block: remove old Metadata, old total notes, extra ---
    introBlock = introBlock.replace(/\*\*Metadata:\*\*[\s\S]*?- - -/g, '').trim();
    introBlock = introBlock.replace(/\*Total Notes:.*?\*/g, '').trim();
    introBlock = introBlock.replace(/\*Last Updated:.*?\*/g, '').trim();
    introBlock = introBlock.replace(/#.*?[\r\n]+/g, '').trim(); // remove # headers like "# Science - Map of Contents"
    introBlock = introBlock.replace(/^- - -/gm, '').trim();
    introBlock = introBlock.replace(/## Notes/g, '').trim();

    if (p.includes('Biographies') && introBlock.length < 10) {
        introBlock = `> *Those who cannot remember the past are condemned to repeat it.* - George Santayana\n\nThe Biographies section chronicles the lives, achievements, and enduring impacts of historically significant individuals.`;
    }
    
    // 3. Extract all links and categorize them
    // We'll read the table rows to preserve categories, but deduplicate them
    let categories = new Map();
    let totalNotesCount = 0;
    
    let tableRegex = /\|(.+?)\|(.+?)\|(.+?)\|/g;
    let match;
    while ((match = tableRegex.exec(content)) !== null) {
        let col1 = match[1].trim();
        let col2 = match[2].trim();
        let col3 = match[3].trim();
        
        if (col1.toLowerCase() === 'topic area' || col1.includes('---')) continue;
        if (col1.toLowerCase() === 'title') continue; // old format
        
        // Extract links from col2
        let links = [];
        let linkMatch;
        let linkRegex = /\[\[(.*?)\]\]/g;
        while ((linkMatch = linkRegex.exec(col2)) !== null) {
            links.push(`[[${linkMatch[1]}]]`);
        }
        
        // Normalize category name (Title Case)
        let catName = col1.split(/[-_\s]+/).map(w => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase()).join(' ');
        if (catName === 'Ai') catName = 'AI';
        
        if (!categories.has(catName)) {
            categories.set(catName, new Set());
        }
        
        links.forEach(l => categories.get(catName).add(l));
    }
    
    // Rebuild rows
    let tableRows = [];
    for (let [cat, linksSet] of categories.entries()) {
        if (linksSet.size > 0) {
            let linksArray = Array.from(linksSet);
            totalNotesCount += linksArray.length;
            // Let's use today's date for Last Updated column
            tableRows.push(`| ${cat} | ${linksArray.join(', ')} | 2026-04-17 |`);
        }
    }
    
    // 4. Assemble the final MOC
    let finalContent = `${yaml}\n\n`;
    if (introBlock) {
        finalContent += `${introBlock}\n\n`;
    }
    
    finalContent += `**Metadata:**\n`;
    finalContent += `- Last Major Reorganization: 2026-04-17\n`;
    finalContent += `- Total Notes: ${totalNotesCount}\n`;
    finalContent += `- - -\n`;
    finalContent += `## Structure\n`;
    
    if (tableRows.length > 0) {
        finalContent += `| Topic Area | Notes | Last Updated |\n`;
        finalContent += `|------------|-------|--------------|\n`;
        finalContent += tableRows.join('\n') + `\n`;
    } else {
        finalContent += `| Topic Area | Notes | Last Updated |\n`;
        finalContent += `|------------|-------|--------------|\n`;
        finalContent += `| General | None | 2026-04-17 |\n`;
    }
    
    finalContent += `- - -\n\n`;
    finalContent += `*Last MOC Update: 2026-04-17 by GeminiCLI*\n`;
    finalContent += `*Next Review: 2027-04-17*\n`;
    
    fs.writeFileSync(p, finalContent, 'utf8');
    console.log(`Audited and Fixed: ${path.basename(p)} (${totalNotesCount} notes)`);
});
