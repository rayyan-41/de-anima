const fs = require('fs');
const path = require('path');

const VAULT_ROOT = 'E:\\De Anima';
const IGNORE_DIRS = ['_tmp', '.obsidian', 'paintings_source', '.trash', '.gemini', '.git', 'node_modules'];
const SACRED_FILES = ['Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md', 'GEMINI.md'];

function isMOC(filename) {
    return filename.includes('Map of Contents');
}

function walkDir(dir, callback) {
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

const allNotes = []; // { path, filename, title, links: [], frontmatter: null, domain: '', isMOC: false }
const noteIndex = new Map(); // targetName -> note object
const contentMap = new Map(); // path -> content

// 1. Collect all notes
walkDir(VAULT_ROOT, (filePath) => {
    const filename = path.basename(filePath);
    const relativePath = path.relative(VAULT_ROOT, filePath);
    const parts = relativePath.split(path.sep);
    const domain = parts.length > 1 ? parts[0] : (parts[0] === 'Reason' ? 'Reason' : 'Root');

    let content = '';
    try {
        content = fs.readFileSync(filePath, 'utf-8');
    } catch (e) {
        return;
    }
    contentMap.set(filePath, content);

    const note = {
        path: filePath,
        relativePath,
        filename,
        basename: filename.replace('.md', ''),
        links: [],
        frontmatter: null,
        domain: domain,
        isMOC: isMOC(filename),
        isSacred: SACRED_FILES.includes(filename),
        inDegree: 0,
        outDegree: 0,
        frontmatterStr: '',
        frontmatterIssues: []
    };

    // Extract frontmatter
    const fmMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    if (fmMatch) {
        note.frontmatterStr = fmMatch[1];
        // simple key-value parse
        const lines = note.frontmatterStr.split('\n');
        note.frontmatter = {};
        for (const line of lines) {
            const colonIdx = line.indexOf(':');
            if (colonIdx > -1) {
                const key = line.substring(0, colonIdx).trim();
                const val = line.substring(colonIdx + 1).trim();
                note.frontmatter[key] = val;
            }
        }
    }

    // Extract links
    // Regex to match [[Link]] or [[Link|Text]] or [[Link#Heading]]
    const linkRegex = /\[\[(.*?)\]\]/g;
    let match;
    while ((match = linkRegex.exec(content)) !== null) {
        let target = match[1];
        if (target.includes('|')) target = target.split('|')[0];
        if (target.includes('#')) target = target.split('#')[0];
        target = target.trim();
        if (target) {
            note.links.push(target);
        }
    }

    note.outDegree = note.links.length;

    allNotes.push(note);
    noteIndex.set(note.basename.toLowerCase(), note);
});

// Calculate inDegree
for (const note of allNotes) {
    for (const link of note.links) {
        const target = noteIndex.get(link.toLowerCase());
        if (target) {
            target.inDegree++;
        }
    }
}

const orphanLinks = []; // { source, link }
const islandNotes = []; // { note, inDegree, outDegree }
const propertiesIssues = []; // { note, problem }
const mocDesync = []; // { domain, note }

// Check 1: Orphan Links
for (const note of allNotes) {
    for (const link of note.links) {
        if (!noteIndex.has(link.toLowerCase())) {
            orphanLinks.push({ source: note.relativePath, link: link });
        }
    }
}

// Check 2: Island Notes
for (const note of allNotes) {
    if (!note.isMOC && !note.isSacred) {
        if (note.inDegree === 0 && note.outDegree < 2) {
            islandNotes.push({ note: note.relativePath, inDegree: note.inDegree, outDegree: note.outDegree });
        }
    }
}

// Check 3: Properties Non-Conformance
for (const note of allNotes) {
    if (note.isMOC || note.isSacred) continue;

    if (!note.frontmatter) {
        propertiesIssues.push({ note: note.relativePath, problem: "Missing frontmatter entirely" });
        continue;
    }

    const missingFields = [];
    const requiredFields = ['title', 'date', 'domain', 'category', 'status', 'tags'];
    for (const field of requiredFields) {
        // Just checking if the line exists in frontmatter string since our parser is basic
        const regex = new RegExp(`^${field}\\s*:`, 'm');
        if (!regex.test(note.frontmatterStr)) {
            missingFields.push(field);
        }
    }

    if (missingFields.length > 0) {
        propertiesIssues.push({ note: note.relativePath, problem: `Missing fields: ${missingFields.join(', ')}` });
    }

    const statusMatch = note.frontmatterStr.match(/^status\s*:\s*(.*)/m);
    if (statusMatch) {
        const statusVal = statusMatch[1].trim();
        if (statusVal !== 'complete' && statusVal !== 'incomplete') {
            propertiesIssues.push({ note: note.relativePath, problem: `Invalid status: ${statusVal}` });
        }
    }
}

// Check 4: MOC Desync
// Get MOC files per domain
const domainMOCs = {};
for (const note of allNotes) {
    if (note.isMOC) {
        domainMOCs[note.domain] = note;
    }
}

for (const note of allNotes) {
    if (note.isMOC || note.isSacred || note.domain === 'Root') continue;
    
    const moc = domainMOCs[note.domain];
    if (moc) {
        // Check if note is linked in MOC
        let isLinked = false;
        for (const link of moc.links) {
            if (link.toLowerCase() === note.basename.toLowerCase()) {
                isLinked = true;
                break;
            }
        }
        if (!isLinked) {
            mocDesync.push({ domain: note.domain, note: note.relativePath });
        }
    } else {
        // MOC not found for domain
        mocDesync.push({ domain: note.domain, note: note.relativePath + " (No MOC found for domain)" });
    }
}

// Format the output
let output = "";

output += "🔴 ORPHAN LINKS\n";
output += "| Source File | Broken Link | Suggested Fix |\n";
output += "|------------|-------------|---------------|\n";
for (const item of orphanLinks) {
    output += `| ${item.source.replace(/\\/g, '/')} | [[${item.link}]] | Create note / Correct link |\n`;
}
output += "\n";

output += "🟡 ISLAND NOTES\n";
output += "| Note | Incoming Links | Outgoing Links | Suggested Connections |\n";
output += "|------|---------------|----------------|----------------------|\n";
for (const item of islandNotes) {
    output += `| ${item.note.replace(/\\/g, '/')} | ${item.inDegree} | ${item.outDegree} | Add links |\n`;
}
output += "\n";

output += "🔴 PROPERTIES ISSUES\n";
output += "| Note | Problem | Suggested Fix |\n";
output += "|------|---------|---------------|\n";
for (const item of propertiesIssues) {
    output += `| ${item.note.replace(/\\/g, '/')} | ${item.problem} | Fix YAML block |\n`;
}
output += "\n";

output += "🔴 MOC DESYNC\n";
output += "| Domain | Note Missing from MOC |\n";
output += "|--------|----------------------|\n";
for (const item of mocDesync) {
    output += `| ${item.domain} | ${path.basename(item.note)} |\n`;
}

console.log(output);
