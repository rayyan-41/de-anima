const fs = require('fs');
const path = require('path');

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
walkDir('E:\\De Anima', (p) => mocs.push(p));

mocs.forEach(p => {
    let content = fs.readFileSync(p, 'utf8');
    
    // Find the end of YAML frontmatter
    let frontmatterEnd = content.indexOf('---', 3) + 3;
    let afterFrontmatter = content.substring(frontmatterEnd);
    
    // Find the start of Metadata
    let metadataStart = afterFrontmatter.indexOf('**Metadata:**');
    let intro = "";
    if (metadataStart !== -1) {
        intro = afterFrontmatter.substring(0, metadataStart).trim();
    } else {
        let structureStart = afterFrontmatter.indexOf('## Structure');
        if (structureStart !== -1) {
            intro = afterFrontmatter.substring(0, structureStart).trim();
        } else {
            intro = "NO INTRO FOUND";
        }
    }
    
    console.log("=== " + p + " ===");
    console.log(intro);
    console.log("");
});
