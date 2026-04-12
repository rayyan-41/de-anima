const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'E:\\De Anima';
const IGNORE_DIRS = ['_tmp', '.obsidian', 'paintings_source', '.trash', '.gemini', '.git', 'node_modules'];
const SACRED_FILES = ['Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md', 'GEMINI.md'];

function isMOC(filename) {
    return filename.includes('Map of Contents');
}

function walkDir(dir, callback) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            if (!IGNORE_DIRS.includes(file)) {
                walkDir(fullPath, callback);
            }
        } else {
            if (file.endsWith('.md')) {
                callback(fullPath);
            }
        }
    }
}

// 1. Map all existing files
const existingFiles = new Set();
const existingNames = new Map(); // lowercase name -> actual name

walkDir(VAULT_ROOT, (filePath) => {
    const filename = path.basename(filePath, '.md');
    existingFiles.add(filename);
    existingNames.set(filename.toLowerCase(), filename);
});

// Helper for mapping orphans
const renameMap = {
    "_history - map of contents": "Map of Contents - History",
    "timeline of the levant under muslim rule": "History of the Levant under Muslim Rule",
    "map of contents - contemporary history": "Map of Contents - History",
    "map of contents - early and late medieval history": "Map of Contents - History",
    "gemini": "GEMINI",
    "bio - euclid": "Euclid",
    "bio - gauss": "Gauss",
    "bio - euler": "Euler",
    "llms for reasoning.md": "LLMs for Reasoning",
    "transformer models vs diffusion in agentic ai, llms and slms.md": "Transformer Models vs Diffusion in Agentic AI, LLMs and SLMs",
    "kv caches and ai hardware architecture.md": "KV Caches and AI Hardware Architecture"
};

function fixOrphanLinks(content) {
    return content.replace(/\[\[(.*?)\]\]/g, (match, inner) => {
        let [link, display] = inner.split('|');
        let linkClean = link.trim();
        let displayStr = display ? `|${display}` : '';
        
        let linkLower = linkClean.toLowerCase();
        
        // Remove .md extension for links
        if (linkLower.endsWith('.md')) {
            linkClean = linkClean.slice(0, -3);
            linkLower = linkLower.slice(0, -3);
        }
        
        if (renameMap[linkLower]) {
            return `[[${renameMap[linkLower]}${displayStr}]]`;
        }
        
        // Match specific known orphan replacements
        if (linkClean === "Art/paintings_source/A_Sunday Afternoon_on_the Island_of_La Grande_Jatte.png") {
            return `[[A_Sunday Afternoon_on_the Island_of_La Grande_Jatte.webp${displayStr}]]`;
        }
        if (linkClean === "Art/paintings_source/School_Of_Athens.webp") {
            return `[[did-you-know-The-School-of-Athens-Raphael.webp${displayStr}]]`;
        }
        if (linkClean === "AI-1.1-Neural Networks Expanded") {
            return `[[1.0 - Neural Networks${displayStr}]]`;
        }

        if (existingNames.has(linkLower)) {
            let actualName = existingNames.get(linkLower);
            if (actualName !== linkClean) {
                return `[[${actualName}${displayStr}]]`;
            }
        }
        
        return match;
    });
}

// 2. Process properties and fix links for all notes
const allNotesData = [];

walkDir(VAULT_ROOT, (filePath) => {
    const filename = path.basename(filePath);
    if (SACRED_FILES.includes(filename)) return;
    
    let content = fs.readFileSync(filePath, 'utf-8');
    let originalContent = content;
    
    // Fix orphans in content
    content = fixOrphanLinks(content);
    
    let isMOCFile = isMOC(filename);
    
    if (!isMOCFile) {
        // Fix Unclosed frontmatter
        if (content.startsWith('---\n') || content.startsWith('---\r\n')) {
            const secondDashes = content.indexOf('---', 3);
            if (secondDashes === -1) {
                // Find first blank line or heading to close it
                const lines = content.split('\n');
                let insertIdx = 1;
                for (let i = 1; i < lines.length; i++) {
                    if (lines[i].trim() === '' || lines[i].startsWith('#')) {
                        insertIdx = i;
                        break;
                    }
                }
                lines.splice(insertIdx, 0, '---');
                content = lines.join('\n');
            }
        } else {
            // No frontmatter? Add one.
            if (!content.trim().startsWith('---')) {
                content = `---\ndate: 2023-10-24\nstatus: complete\ntags: [unassigned, unassigned, ai-generated]\nnote: ""\n---\n\n${content}`;
            }
        }
        
        // Parse YAML
        let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
        if (yamlMatch) {
            let fm = yamlMatch[1];
            let newFmLines = [];
            
            // Extract fields
            let dateMatch = fm.match(/date:\s*([^\r\n]+)/);
            let statusMatch = fm.match(/status:\s*([^\r\n]+)/);
            let tagsBlock = fm.match(/tags:\s*([\s\S]*?)(?=\n[a-z]+:|$)/);
            if (!tagsBlock) { // Try inline tags
                tagsBlock = fm.match(/tags:\s*\[(.*?)\]/);
            }
            let noteMatch = fm.match(/note:\s*([^\r\n]*)/);
            
            let date = dateMatch ? dateMatch[1].trim() : "2023-10-24";
            let status = statusMatch ? statusMatch[1].trim() : "complete";
            let note = noteMatch ? noteMatch[1].trim() : '""';
            if (note === "") note = '""';
            
            // Clean tags
            let tagsList = [];
            if (tagsBlock && tagsBlock[0].includes('[')) {
                let inner = fm.match(/tags:\s*\[(.*?)\]/);
                if (inner && inner[1]) {
                    tagsList = inner[1].split(',').map(t => t.trim().replace(/['"]/g, ''));
                }
            } else if (tagsBlock) {
                let lines = tagsBlock[1].split(/\r?\n/);
                tagsList = lines.map(l => {
                    let m = l.match(/^\s*-\s+(.*)$/);
                    return m ? m[1].trim().replace(/['"]/g, '') : null;
                }).filter(Boolean);
            }
            
            // Ensure valid tags array
            if (tagsList.length < 3) {
                const relativePath = path.relative(VAULT_ROOT, filePath);
                const domain = relativePath.split(path.sep)[0];
                const cat = relativePath.split(path.sep).length > 2 ? relativePath.split(path.sep)[1] : domain;
                if (!tagsList[0]) tagsList[0] = domain.toLowerCase();
                if (!tagsList[1]) tagsList[1] = cat.toLowerCase();
            }
            
            if (tagsList.length > 0 && tagsList[tagsList.length - 1] !== 'ai-generated') {
                if (tagsList.includes('ai-generated')) {
                    tagsList = tagsList.filter(t => t !== 'ai-generated');
                }
                tagsList.push('ai-generated');
            }
            if (tagsList.length === 0) {
                tagsList = ['root', 'general', 'ai-generated'];
            }
            
            // Format new YAML
            newFmLines.push(`date: ${date}`);
            newFmLines.push(`status: ${status}`);
            newFmLines.push(`tags: [${tagsList.join(', ')}]`);
            newFmLines.push(`note: ${note}`);
            
            let newYaml = `---\n${newFmLines.join('\n')}\n---`;
            content = content.replace(yamlMatch[0], newYaml);
            
            allNotesData.push({
                path: filePath,
                title: filename.replace('.md', ''),
                domain: tagsList[0],
                category: tagsList[1]
            });
        }
    }
    
    if (content !== originalContent) {
        fs.writeFileSync(filePath, content, 'utf-8');
    }
});

// 3. Process MOC files
const mocFiles = [];
walkDir(VAULT_ROOT, (filePath) => {
    if (isMOC(path.basename(filePath))) {
        mocFiles.push(filePath);
    }
});

mocFiles.forEach(mocPath => {
    let content = fs.readFileSync(mocPath, 'utf-8');
    const domain = path.basename(mocPath, '.md').replace('Map of Contents - ', '').replace('_', '').trim();
    
    // Fix frontmatter
    let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (!yamlMatch) {
        // Remove legacy DATE/TAGS
        content = content.replace(/^(?:DATE|TAGS|Date|Tags):\s*.*(?:\r?\n|$)/gm, '');
        content = `---\ndate: 2023-10-24\nstatus: complete\ntags: [${domain.toLowerCase()}, moc, ai-generated]\nnote: ""\n---\n\n${content.trimStart()}`;
        yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    }
    
    if (yamlMatch) {
        let fm = yamlMatch[1];
        let dateMatch = fm.match(/date:\s*([^\r\n]+)/);
        let date = dateMatch ? dateMatch[1].trim() : "2023-10-24";
        let newYaml = `---\ndate: ${date}\nstatus: complete\ntags: [${domain.toLowerCase()}, moc, ai-generated]\nnote: ""\n---`;
        content = content.replace(yamlMatch[0], newYaml);
    }
    
    // Fix separators in body
    let body = content.slice(content.indexOf('---', 3) + 3);
    body = body.replace(/^\s*---\s*$/gm, '- - -');
    content = content.slice(0, content.indexOf('---', 3) + 3) + body;
    
    // Extract Table
    let tableRegex = /\| Topic Area \| Notes \| Last Updated \|\r?\n\|[-\s]+\|[-\s]+\|[-\s]+\|\r?\n([\s\S]*?)(?=\n- - -|\n\n|\n\*Last|$)/;
    let tableMatch = content.match(tableRegex);
    let rows = [];
    if (tableMatch) {
        let lines = tableMatch[1].trim().split('\n');
        for (let line of lines) {
            let cols = line.split('|').map(c => c.trim());
            if (cols.length >= 4) {
                let cat = cols[1];
                let notesCol = cols[2];
                let dateCol = cols[3];
                
                // Prune dead links
                let noteLinks = notesCol.match(/\[\[(.*?)\]\]/g) || [];
                let validLinks = [];
                for (let link of noteLinks) {
                    let cleanLink = link.replace(/\[\[|\]\]/g, '').split('|')[0].trim();
                    if (existingFiles.has(cleanLink) || existingNames.has(cleanLink.toLowerCase())) {
                        validLinks.push(link);
                    }
                }
                if (validLinks.length > 0) {
                    rows.push({ category: cat, links: validLinks, date: dateCol });
                }
            }
        }
    }
    
    // Append missing notes to MOC
    let domainNotes = allNotesData.filter(n => n.domain.toLowerCase() === domain.toLowerCase());
    for (let note of domainNotes) {
        let cat = note.category;
        // Check if note is in rows
        let found = false;
        for (let row of rows) {
            if (row.links.some(l => l.includes(`[[${note.title}]]`) || l.includes(`[[${note.title}|`))) {
                found = true;
                break;
            }
        }
        if (!found) {
            let catRow = rows.find(r => r.category.toLowerCase() === cat.toLowerCase());
            if (catRow) {
                catRow.links.push(`[[${note.title}]]`);
            } else {
                rows.push({ category: cat, links: [`[[${note.title}]]`], date: "2023-10-24" });
            }
        }
    }
    
    // Reconstruct table
    let newTable = `| Topic Area | Notes | Last Updated |\n|------------|-------|--------------|\n`;
    let totalNotes = 0;
    for (let row of rows) {
        newTable += `| ${row.category} | ${row.links.join(', ')} | ${row.date} |\n`;
        totalNotes += row.links.length;
    }
    
    if (tableMatch) {
        content = content.replace(tableMatch[0], newTable.trim());
    } else {
        // Append table if not exist
        content += `\n\n## Structure\n\n${newTable}\n- - -\n`;
    }
    
    // Metadata block
    let metaBlock = `**Metadata:**\n- Last Major Reorganization: 2023-10-24\n- Total Notes: ${totalNotes}\n- - -`;
    if (content.includes('**Metadata:**')) {
        content = content.replace(/\*\*Metadata:\*\*[\s\S]*?- - -/, metaBlock);
    } else {
        content = content.replace(/---\r?\n\r?\n/, `---\n\n${metaBlock}\n\n`);
    }
    
    // Footer
    let footer = `*Last MOC Update: 2023-10-24 by GeminiCLI*\n*Next Review: 2024-10-24*`;
    if (content.includes('*Last MOC Update:*')) {
        content = content.replace(/\*Last MOC Update:.*[\s\S]*$/, footer);
    } else {
        content = content.trimEnd() + `\n\n${footer}\n`;
    }
    
    fs.writeFileSync(mocPath, content, 'utf-8');
});

console.log('Standardization, MOC Repair, and Orphan Link Fixes Complete.');
