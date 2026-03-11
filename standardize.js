const fs = require('fs');
const path = require('path');

function processFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    
    let dateStr = '2026-03-11';
    let tagsList = [];
    
    let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    let frontmatterRaw = "";
    let contentWithoutFm = content;
    
    if (yamlMatch) {
        frontmatterRaw = yamlMatch[1];
        contentWithoutFm = content.slice(yamlMatch[0].length).trimStart();
    } else {
        let topLinesMatch = content.match(/^((?:DATE|TAGS|Date|Tags):\s*.*(?:\r?\n|$))+/i);
        if (topLinesMatch) {
            frontmatterRaw = topLinesMatch[0];
            contentWithoutFm = content.slice(topLinesMatch[0].length).trimStart();
        }
    }
    
    // strip redundant DATE/TAGS immediately after the block
    contentWithoutFm = contentWithoutFm.replace(/^((?:DATE|TAGS|Date|Tags):\s*.*(?:\r?\n|$))+/i, '').trimStart();
    
    let dateMatch = frontmatterRaw.match(/(?:DATE|Date|date):\s*([^\r\n]+)/i);
    if (dateMatch) {
        let rawDate = dateMatch[1].trim();
        rawDate = rawDate.replace(/^['"]|['"]$/g, '');
        if (rawDate) dateStr = rawDate;
    }
    
    let tagsMatch = frontmatterRaw.match(/(?:TAGS|Tags|tags):\s*([^\r\n]+)/i);
    if (tagsMatch) {
        let rawTags = tagsMatch[1].trim();
        if (rawTags !== 'null' && rawTags !== '[]' && rawTags !== '') {
             if (rawTags.startsWith('[')) {
                 rawTags = rawTags.slice(1, -1);
                 tagsList = rawTags.split(',').map(t => t.trim().replace(/^['"]|['"]$/g, ''));
             } else {
                 tagsList = rawTags.split(/[,\s]+/).map(t => t.replace(/^#/, '').trim());
             }
        }
    } else {
        let multiLineTagsMatch = frontmatterRaw.match(/tags:\s*\r?\n((?:\s+-\s+[^\r\n]+\r?\n?)+)/i);
        if (multiLineTagsMatch) {
             let lines = multiLineTagsMatch[1].split(/\r?\n/);
             tagsList = lines.map(l => {
                 let m = l.match(/^\s*-\s+(.*)$/);
                 return m ? m[1].trim().replace(/^['"]|['"]$/g, '') : '';
             }).filter(Boolean);
        }
    }
    
    tagsList = tagsList.filter(Boolean).map(t => t.toLowerCase());
    tagsList = [...new Set(tagsList)];
    
    let aliasList = [];
    let aliasMatch = frontmatterRaw.match(/aliases:\s*\r?\n((?:\s+-\s+[^\r\n]+\r?\n?)+)/i);
    if (aliasMatch) {
         let lines = aliasMatch[1].split(/\r?\n/);
         aliasList = lines.map(l => {
             let m = l.match(/^\s*-\s+(.*)$/);
             return m ? m[1].trim().replace(/^['"]|['"]$/g, '') : '';
         }).filter(Boolean);
    } else {
         let singleAliasMatch = frontmatterRaw.match(/aliases:\s*([^\r\n]+)/i);
         if (singleAliasMatch) {
             let rawA = singleAliasMatch[1].trim();
             if (rawA !== '[]' && rawA !== 'null' && rawA !== '') {
                  aliasList.push(rawA);
             }
         }
    }
    
    if (aliasList.length === 0) {
        let alias = path.basename(filePath, '.md');
        alias = alias.replace(/^(?:MATH|CS|AI|WEB|GEO|HIST|EMP|BIO|LIT|ARTH|SCI)\s*-\s*/i, '');
        aliasList.push(alias);
    }
    
    aliasList = [...new Set(aliasList)];
    
    let tagsOutput = tagsList.length ? '\n' + tagsList.map(t => '  - ' + t).join('\n') : ' []';
    let aliasesOutput = aliasList.length ? '\n' + aliasList.map(a => '  - "' + a + '"').join('\n') : ' []';
    
    let newFm = "---\ndate: " + dateStr + "\ntags:" + tagsOutput + "\naliases:" + aliasesOutput + "\n---\n\n";
    
    fs.writeFileSync(filePath, newFm + contentWithoutFm, 'utf8');
    console.log("Updated: " + filePath);
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
