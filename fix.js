const fs = require('fs');
const path = require('path');

function processFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    
    // fix "- -" in tags
    let changed = false;
    if (content.includes('  - -')) {
        content = content.replace(/  - -\r?\n/g, '');
        changed = true;
    }
    
    // fix empty aliases with no []
    if (content.match(/aliases:\s*\r?\n/)) {
        let alias = path.basename(filePath, '.md');
        alias = alias.replace(/^(?:MATH|CS|AI|WEB|GEO|HIST|EMP|BIO|LIT|ARTH|SCI)\s*-\s*/i, '');
        content = content.replace(/aliases:\s*\r?\n/, 'aliases:\n  - "' + alias + '"\n');
        changed = true;
    }
    
    if (changed) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log("Fixed: " + filePath);
    }
}

function processDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            processDir(fullPath);
        } else if (fullPath.endsWith('.md')) {
            if (!file.includes('Map of Contents')) {
                processFile(fullPath);
            }
        }
    }
}

processDir('E:\\De Anima\\Science');
