const fs = require('fs');
const path = require('path');

const vaultPath = 'E:\\De Anima';
const domains = ['Art', 'History', 'Islam', 'Literature', 'Reason', 'Science'];
const sacredFiles = ['Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md', 'GEMINI.md'];

const validDomains = new Set(['art', 'history', 'islam', 'literature', 'reason', 'science']);
const validCategories = new Set([
    'art-history', 'art-theory',
    'medieval-and-late-medieval', 'contemporary', 'biographies', 'empire', 'biography', 'geopolitical', 'history',
    'aqeedah', 'fiqh', 'fiqh/ibadat', 'fiqh/muamalat', 'fiqh/contemporary', 'ibadat', 'muamalat', 'contemporary-fiqh',
    'books', 'myths-and-legends', 'short-stories', 'reference', 'literature',
    'philosophy', 'logic', 'metaphysics', 'ethics', 'epistemology', 'reason/philosophy',
    'astronomy', 'mathematics', 'computer-science', 'ai', 'web-dev', 'science', 'science/math', 'science/cs', 'science/ai', 'science/web'
]);

let allNotes = [];
let noteNameLowerToPath = new Map();
let noteNameToActualName = new Map();

function crawlDir(dir, domain) {
    if (!fs.existsSync(dir)) return;
    const items = fs.readdirSync(dir);
    for (const item of items) {
        if (['.obsidian', '.trash', '_tmp', '.tmp', 'paintings_source', 'node_modules', '.git'].includes(item)) continue;
        const fullPath = path.join(dir, item);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
            crawlDir(fullPath, domain);
        } else if (item.endsWith('.md')) {
            if (sacredFiles.includes(item)) continue;
            
            const isMoc = item.includes('Map of Contents') || item.includes('MOC') || item.startsWith('_');
            const name = item.replace(/\.md$/i, '');
            const content = fs.readFileSync(fullPath, 'utf8');
            
            allNotes.push({
                fullPath,
                name,
                domain,
                isMoc,
                content,
                linksOut: new Set(),
                linksIn: new Set()
            });
            noteNameLowerToPath.set(name.toLowerCase(), fullPath);
            noteNameToActualName.set(name.toLowerCase(), name);
        }
    }
}

for (const dom of domains) {
    crawlDir(path.join(vaultPath, dom), dom);
}

// Build adjacency and find orphans
let orphans = []; // { sourcePath, brokenLink }
for (const note of allNotes) {
    const linkRegex = /\[\[(.*?)\]\]/g;
    let match;
    while ((match = linkRegex.exec(note.content)) !== null) {
        let target = match[1];
        if (target.includes('|')) target = target.split('|')[0];
        if (target.includes('#')) target = target.split('#')[0];
        target = target.trim();
        if (!target) continue;

        const targetLower = target.toLowerCase();
        note.linksOut.add(targetLower);

        if (noteNameLowerToPath.has(targetLower)) {
            const targetNote = allNotes.find(n => n.name.toLowerCase() === targetLower);
            if (targetNote) {
                targetNote.linksIn.add(note.name.toLowerCase());
            }
        } else {
            orphans.push({ source: note.fullPath.replace(vaultPath + '\\', '').replace(/\\/g, '/'), brokenLink: match[1] });
        }
    }
}

// 1. Orphan Links
console.log("🔴 ORPHAN LINKS");
console.log("| Source File | Broken Link | Suggested Fix |");
console.log("|------------|-------------|---------------|");
if (orphans.length === 0) {
    console.log("| None | None | - |");
} else {
    for (const o of orphans) {
        console.log(`| ${o.source} | [[${o.brokenLink}]] | Create note / Correct link |`);
    }
}
console.log("\n");

// 2. Island Notes
console.log("🟡 ISLAND NOTES");
console.log("| Note | Incoming Links | Outgoing Links | Suggested Connections |");
console.log("|------|---------------|----------------|----------------------|");
let hasIslands = false;
for (const note of allNotes) {
    if (note.isMoc) continue;
    if (note.linksIn.size === 0 && note.linksOut.size < 2) {
        hasIslands = true;
        console.log(`| ${note.name}.md | ${note.linksIn.size} | ${note.linksOut.size} | Suggest manual review |`);
    }
}
if (!hasIslands) console.log("| None | 0 | 0 | - |");
console.log("\n");

// 3. Properties Non-Conformance
console.log("🔴 PROPERTIES ISSUES");
console.log("| Note | Problem | Suggested Fix |");
console.log("|------|---------|---------------|");
let hasProps = false;
for (const note of allNotes) {
    if (note.isMoc) continue;
    
    const lines = note.content.split(/\r?\n/);
    if (lines[0] !== '---') {
        hasProps = true;
        console.log(`| ${note.name}.md | Missing frontmatter entirely | Add YAML block with date/status/tags/note |`);
        continue;
    }
    
    const endIdx = lines.indexOf('---', 1);
    if (endIdx === -1) {
        hasProps = true;
        console.log(`| ${note.name}.md | Unclosed frontmatter block | Close with --- |`);
        continue;
    }
    
    const fm = lines.slice(1, endIdx);
    const fmString = fm.join('\n');
    
    // Check fields exist
    const hasDate = /^date:/m.test(fmString);
    const hasStatus = /^status:/m.test(fmString);
    const hasTags = /^tags:/m.test(fmString);
    const hasNote = /^note:/m.test(fmString);
    
    let missingFields = [];
    if (!hasDate) missingFields.push('date:');
    if (!hasStatus) missingFields.push('status:');
    if (!hasTags) missingFields.push('tags:');
    if (!hasNote) missingFields.push('note:');
    
    if (missingFields.length > 0) {
        hasProps = true;
        console.log(`| ${note.name}.md | Missing fields: ${missingFields.join(', ')} | Add required fields |`);
    }
    
    // Check forbidden fields
    const hasTitle = /^title:/m.test(fmString);
    const hasDomain = /^domain:/m.test(fmString);
    const hasCategory = /^category:/m.test(fmString);
    let forbidden = [];
    if (hasTitle) forbidden.push('title:');
    if (hasDomain) forbidden.push('domain:');
    if (hasCategory) forbidden.push('category:');
    if (forbidden.length > 0) {
        hasProps = true;
        console.log(`| ${note.name}.md | Legacy fields present: ${forbidden.join(', ')} | Remove legacy fields |`);
    }
    
    // Validate status
    const statusMatch = fmString.match(/^status:\s*(.+)$/m);
    if (statusMatch) {
        const statusVal = statusMatch[1].trim();
        if (statusVal !== 'complete' && statusVal !== 'incomplete') {
            hasProps = true;
            console.log(`| ${note.name}.md | Invalid status: ${statusVal} | Set to complete or incomplete |`);
        }
    }
    
    // Validate tags
    let tagsStr = '';
    const tagsMatchInline = fmString.match(/^tags:\s*\[(.*?)\]/m);
    let tagsList = [];
    if (tagsMatchInline) {
        tagsStr = tagsMatchInline[1];
        tagsList = tagsStr.split(',').map(t => t.trim().replace(/^['"]|['"]$/g, ''));
    } else {
        // Multi-line tags parsing
        let inTags = false;
        for (const line of fm) {
            if (/^tags:/.test(line)) {
                inTags = true;
                const inline = line.replace(/^tags:/, '').trim();
                if (inline && inline.startsWith('[') && inline.endsWith(']')) {
                     tagsList = inline.slice(1, -1).split(',').map(t=>t.trim().replace(/^['"]|['"]$/g, ''));
                     break;
                } else if (inline) {
                     tagsList.push(inline);
                }
            } else if (inTags) {
                if (line.trim().startsWith('-')) {
                    tagsList.push(line.trim().replace(/^- /, '').trim().replace(/^['"]|['"]$/g, ''));
                } else if (/^\w+:/m.test(line)) {
                    inTags = false;
                }
            }
        }
    }
    
    if (tagsList.length > 0) {
        const domainTag = tagsList[0];
        const categoryTag = tagsList[1];
        const lastTag = tagsList[tagsList.length - 1];
        
        if (!validDomains.has(domainTag.toLowerCase())) {
            hasProps = true;
            console.log(`| ${note.name}.md | Invalid domain tag: ${domainTag} | Change to valid domain |`);
        }
        if (categoryTag && !validCategories.has(categoryTag.toLowerCase())) {
            hasProps = true;
            console.log(`| ${note.name}.md | Invalid category tag: ${categoryTag} | Change to valid category |`);
        }
        if (lastTag !== 'cli') {
            hasProps = true;
            console.log(`| ${note.name}.md | tags: missing 'cli' as last item (found ${lastTag}) | Append cli |`);
        }
    } else if (hasTags) {
        hasProps = true;
        console.log(`| ${note.name}.md | Tags array is empty or malformed | Fix tags array |`);
    }
}
if (!hasProps) console.log("| None | All conform | - |");
console.log("\n");

// 4. MOC Desync
console.log("🔴 MOC DESYNC");
console.log("| Domain | Note Missing from MOC |");
console.log("|--------|----------------------|");
let hasDesync = false;
for (const dom of domains) {
    const mocNote = allNotes.find(n => n.domain === dom && n.isMoc);
    if (!mocNote) {
        hasDesync = true;
        console.log(`| ${dom} | Missing MOC file |`);
        continue;
    }
    
    const mocLinks = new Set();
    const linkRegex = /\[\[(.*?)\]\]/g;
    let match;
    while ((match = linkRegex.exec(mocNote.content)) !== null) {
        let target = match[1];
        if (target.includes('|')) target = target.split('|')[0];
        if (target.includes('#')) target = target.split('#')[0];
        mocLinks.add(target.trim().toLowerCase());
    }
    
    for (const note of allNotes) {
        if (note.domain === dom && !note.isMoc) {
            if (!mocLinks.has(note.name.toLowerCase())) {
                hasDesync = true;
                console.log(`| ${dom} | ${note.name}.md |`);
            }
        }
    }
}
if (!hasDesync) console.log("| None | None |");

