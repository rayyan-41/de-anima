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

mocs.forEach(p => {
    let content = fs.readFileSync(p, 'utf8');

    // Remove Metadata block
    // Matches **Metadata:** up to the next - - -
    content = content.replace(/\*\*Metadata:\*\*[\s\S]*?- - -\r?\n/g, '');

    // Remove Footer block
    // Matches *Last MOC Update: ... down to the end of the file or the *Next Review: ...*
    content = content.replace(/\*Last MOC Update:[\s\S]*?\*Next Review:.*?\*/g, '');

    // Clean up any trailing whitespace and newlines
    content = content.trimEnd() + '\n';

    fs.writeFileSync(p, content, 'utf8');
    console.log(`Cleaned: ${path.basename(p)}`);
});
