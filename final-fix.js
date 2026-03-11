const fs = require('fs');
const path = require('path');

function processDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            processDir(fullPath);
        } else if (fullPath.endsWith('.md')) {
            if (!file.includes('Map of Contents')) {
                let content = fs.readFileSync(fullPath, 'utf8');
                
                let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
                if (!yamlMatch) continue;
                
                let fm = yamlMatch[1];
                let body = content.slice(yamlMatch[0].length).trimStart();
                
                let dateStr = '2026-03-11';
                let dateMatch = fm.match(/date:\s*([^\r\n]+)/);
                if (dateMatch) dateStr = dateMatch[1].trim();
                
                let tagsList = [];
                let tagsBlock = fm.match(/tags:\s*([\s\S]*?)(?=aliases:|$)/);
                if (tagsBlock) {
                    let lines = tagsBlock[1].split(/\r?\n/);
                    tagsList = lines.map(l => {
                        let m = l.match(/^\s*-\s+(.*)$/);
                        return m ? m[1].trim().replace(/^['"]|['"]$/g, '') : null;
                    }).filter(Boolean);
                }
                if (tagsList.length === 0 && fm.includes('tags: []')) {
                    tagsList = [];
                }
                tagsList = tagsList.filter(t => t !== '-' && t !== '[]');
                tagsList = [...new Set(tagsList)];
                
                let aliasMatch = path.basename(fullPath, '.md');
                aliasMatch = aliasMatch.replace(/^(?:MATH|CS|AI|WEB|GEO|HIST|EMP|BIO|LIT|ARTH|SCI)\s*-\s*/i, '');
                
                let tagsOutput = tagsList.length ? '\n' + tagsList.map(t => '  - ' + t).join('\n') : ' []';
                let aliasesOutput = '\n  - "' + aliasMatch + '"';
                
                let newFm = "---\ndate: " + dateStr + "\ntags:" + tagsOutput + "\naliases:" + aliasesOutput + "\n---\n\n";
                fs.writeFileSync(fullPath, newFm + body, 'utf8');
            }
        }
    }
}
processDir('E:\\De Anima\\Science');
console.log('Done');
