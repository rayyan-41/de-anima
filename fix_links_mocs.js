const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'E:\\De Anima';

function walkDir(dir, callback) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (!['.obsidian', '_tmp', '.trash', '.gemini', 'node_modules', '.git'].includes(file)) {
                walkDir(fullPath, callback);
            }
        } else {
            if (file.endsWith('.md')) {
                callback(fullPath);
            }
        }
    }
}

walkDir(VAULT_ROOT, (filePath) => {
    let content = fs.readFileSync(filePath, 'utf-8');
    let original = content;

    // Fix remaining orphan links
    content = content.replace(/\[\[(.*?)\]\]/g, (match, inner) => {
        let [link, display] = inner.split('|');
        let linkTrim = link.trim();
        let displayStr = display ? `|${display}` : '';
        
        if (linkTrim === "A_Sunday Afternoon_on_the Island_of_La Grande_Jatte.webp") {
            return `[[A_Sunday Afternoon_on_the Island_of_La Grande_Jatte.png${displayStr}]]`;
        }
        if (linkTrim === "did-you-know-The-School-of-Athens-Raphael.webp") {
            return `[[School_Of_Athens.webp${displayStr}]]`;
        }
        if (linkTrim === "Chain Of Thoughts") {
            return `[[Chain Of Thoughts${displayStr}]]`;
        }
        if (linkTrim === "GEMINI") {
            return `[[GEMINI${displayStr}]]`;
        }
        if (linkTrim.toLowerCase() === "map of contents - history" && !display) {
            return `[[Map of Contents - History|History MOC]]`;
        }
        
        // Remove .md in links inside MOCs
        if (linkTrim.endsWith('.md')) {
            linkTrim = linkTrim.slice(0, -3);
            return `[[${linkTrim}${displayStr}]]`;
        }
        
        return match;
    });

    // Fix unclosed frontmatter in quotes, caedis, orpheus
    const name = path.basename(filePath);
    if (['Orpheus and Eurydice.md', 'Lexicon.md', 'i. Caedis.md'].includes(name)) {
        if (!content.startsWith('---\n') && !content.startsWith('---\r\n')) {
            // Ensure proper format if it failed before
            let date = "2023-10-24";
            let status = "complete";
            let tags = "['literature', 'reference', 'cli']";
            let note = '""';
            content = `---\ndate: ${date}\nstatus: ${status}\ntags: ${tags}\nnote: ${note}\n---\n\n` + content.replace(/^.*$/m, '');
        } else {
            let lines = content.split('\n');
            let hasEnd = false;
            for(let i=1; i<lines.length; i++) {
                if(lines[i].startsWith('---')) {
                    hasEnd = true; break;
                }
            }
            if(!hasEnd) {
                lines.splice(5, 0, '---');
                content = lines.join('\n');
            }
        }
    }
    
    // Ensure all cli tags are replaced with cli as per instruction (or append cli)
    let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (yamlMatch) {
        let fm = yamlMatch[1];
        if (fm.includes('cli')) {
             let newFm = fm.replace(/['"]?cli['"]?/g, 'cli');
             content = content.replace(fm, newFm);
        }
    }

    if (content !== original) {
        fs.writeFileSync(filePath, content, 'utf-8');
    }
});

// Collect all notes to fix MOC desync properly
const allNotes = [];
walkDir(VAULT_ROOT, (filePath) => {
    const filename = path.basename(filePath);
    if (['GEMINI.md', 'Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md'].includes(filename)) return;
    
    let content = fs.readFileSync(filePath, 'utf-8');
    let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    let domain = 'root', category = 'general';
    if (yamlMatch) {
        let fm = yamlMatch[1];
        let tagsMatch = fm.match(/tags:\s*\[(.*?)\]/);
        if (tagsMatch) {
            let tags = tagsMatch[1].split(',').map(t => t.trim());
            if (tags.length >= 2) {
                domain = tags[0];
                category = tags[1];
            }
        }
    }
    allNotes.push({ path: filePath, name: filename.replace('.md', ''), domain, category });
});

const mocs = [];
walkDir(VAULT_ROOT, (filePath) => {
    const filename = path.basename(filePath);
    if (filename.includes('Map of Contents') || filename.startsWith('_')) {
        mocs.push(filePath);
    }
});

mocs.forEach(mocPath => {
    let content = fs.readFileSync(mocPath, 'utf-8');
    let domain = '';
    
    let name = path.basename(mocPath, '.md');
    if (name.includes(' - ')) {
        let parts = name.split(' - ');
        domain = parts[parts.length-1].replace('Map of Contents', '').trim();
        if (domain === '') domain = parts[0].replace('_', '').trim();
    } else {
        domain = name.replace('Map of Contents', '').replace('_', '').trim();
    }
    if (!domain) return;
    domain = domain.toLowerCase();
    
    let domainNotes = allNotes.filter(n => n.domain.toLowerCase() === domain && !n.name.includes('Map of Contents') && !n.name.startsWith('_'));
    
    let tableRegex = /\| Topic Area \| Notes \| Last Updated \|\r?\n\|[-\s]+\|[-\s]+\|[-\s]+\|\r?\n([\s\S]*?)(?=\n- - -|\n\n|\n\*Last|$)/;
    let tableMatch = content.match(tableRegex);
    
    let rows = [];
    if (tableMatch) {
        let lines = tableMatch[1].trim().split('\n');
        for (let line of lines) {
            let cols = line.split('|').map(c => c.trim());
            if (cols.length >= 4) {
                let noteLinks = cols[2].match(/\[\[(.*?)\]\]/g) || [];
                rows.push({ category: cols[1], links: noteLinks, date: cols[3] });
            }
        }
    }
    
    let appendedCount = 0;
    domainNotes.forEach(note => {
        let found = false;
        for (let row of rows) {
            if (row.links.some(l => l.includes(`[[${note.name}]]`) || l.includes(`[[${note.name}|`))) {
                found = true; break;
            }
        }
        if (!found) {
            let catRow = rows.find(r => r.category.toLowerCase() === note.category.toLowerCase());
            if (catRow) {
                catRow.links.push(`[[${note.name}]]`);
            } else {
                rows.push({ category: note.category, links: [`[[${note.name}]]`], date: '2023-10-24' });
            }
            appendedCount++;
        }
    });
    
    if (appendedCount > 0 || true) {
        let newTable = `| Topic Area | Notes | Last Updated |\n|------------|-------|--------------|\n`;
        let total = 0;
        for (let row of rows) {
            newTable += `| ${row.category} | ${row.links.join(', ')} | ${row.date} |\n`;
            total += row.links.length;
        }
        if (tableMatch) {
            content = content.replace(tableMatch[0], newTable.trim());
        } else {
            content += `\n## Structure\n${newTable}\n- - -\n`;
        }
        content = content.replace(/- Total Notes: \d+/, `- Total Notes: ${total}`);
        fs.writeFileSync(mocPath, content, 'utf-8');
    }
});

console.log('Orphans and MOCs updated.');
