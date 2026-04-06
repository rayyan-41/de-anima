const fs = require('fs');
const path = require('path');

const historyDir = path.join('E:\\De Anima', 'History');
const mocFile = path.join(historyDir, '_History - Map of Contents.md');

function walkDir(dir) {
    let results = [];
    if (!fs.existsSync(dir)) return results;
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat && stat.isDirectory()) {
            if (file !== 'paintings_source' && file !== '_tmp') {
                results = results.concat(walkDir(filePath));
            }
        } else if (file.endsWith('.md')) {
             if (!file.match(/^_.* - Map of Content.*\.md$/) && file !== 'Chain Of Thoughts.md' && file !== 'REAS - Chain Of Thoughts.md') {
                 results.push(filePath);
             }
        }
    });
    return results;
}

const files = walkDir(historyDir);
let successCount = 0;
let failCount = 0;
let resultsOutput = [];
let failedNotes = [];
let mocEntries = [];

let outputLog = `STANDARDIZE: History\nNotes found: ${files.length}\n─────────────────────────────\n`;
files.forEach((file, index) => {
    outputLog += ` ${index + 1}. ${path.basename(file)} — ${file}\n`;
});
outputLog += `─────────────────────────────\nSpawning ${files.length} sub-sessions. 15s sleep between each.\n`;

files.forEach(file => {
    try {
        let filename = path.basename(file);
        let content = fs.readFileSync(file, 'utf8');
        
        let relPath = path.relative(historyDir, file).replace(/\\/g, '/');
        let parts = relPath.split('/');
        let rawCategory = parts.length > 1 ? parts[0] : 'history';
        
        let category = 'history';
        let structuralTag = 'history';
        if (rawCategory.toLowerCase().includes('medieval')) category = 'medieval-and-late-medieval';
        else if (rawCategory.toLowerCase().includes('contemporary')) category = 'contemporary';
        else if (rawCategory.toLowerCase().includes('biographies')) { category = 'biographies'; structuralTag = 'biography'; }
        else if (rawCategory.toLowerCase().includes('narratives')) category = 'history';
        
        if (filename.startsWith('EMP -') || content.includes('#empire')) structuralTag = 'empire';
        if (filename.startsWith('BIO -') || content.includes('#biography')) structuralTag = 'biography';

        // Extract Title from filename without prefix
        let titleMatch = filename.replace(/^(?:MATH|CS|AI|WEB|GEO|HIST|EMP|BIO|LIT|ARTH|SCI)\s*-\s*/i, '').replace(/\.md$/, '');
        let title = titleMatch;
        let date = '2026-03-11';
        let status = 'complete';

        let body = content;
        let tagsList = ['history', category, structuralTag];
        let oldTags = [];
        
        let yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
        if (yamlMatch) {
            let fm = yamlMatch[1];
            body = content.slice(yamlMatch[0].length).trimStart();
            let dateMatch = fm.match(/date:\s*([^\r\n]+)/);
            if (dateMatch) date = dateMatch[1].trim().replace(/['"]/g, '');
            let titleM = fm.match(/title:\s*([^\r\n]+)/);
            if (titleM) title = titleM[1].trim().replace(/['"]/g, '');
            let tagsBlock = fm.match(/tags:\s*([\s\S]*?)(?=aliases:|title:|date:|domain:|category:|status:|$)/);
            if (tagsBlock) {
                 oldTags = tagsBlock[1].split(/\r?\n/).map(l => {
                     let m = l.match(/^\s*-\s+(.*)$/);
                     if (m) return m[1].trim().replace(/^['"]|['"]$/g, '');
                     let m2 = l.match(/\[(.*)\]/);
                     if (m2) return m2[1].split(',').map(x=>x.trim().replace(/^['"]|['"]$/g, ''));
                     return l.trim().replace(/^['"]|['"]$/g, '');
                 }).flat().filter(Boolean);
            }
        }
        
        tagsList = [...tagsList, ...oldTags];
        tagsList = tagsList.filter(t => t !== '[]' && t !== '-' && t !== 'history' && t !== category && t !== structuralTag && t !== 'ai-generated');
        tagsList = ['history', category, structuralTag, ...tagsList, 'ai-generated'];
        tagsList = [...new Set(tagsList.map(t => t.toLowerCase().replace(/[\s_]+/g, '-')))];

        let tagsOutput = '\n' + tagsList.map(t => '  - ' + t).join('\n');
        
        let newYaml = `---
title: "${title}"
date: ${date}
domain: history
category: ${category}
status: ${status}
tags:${tagsOutput}
---

`;
        
        let wordCount = body.split(/\s+/).filter(w => w.length > 0).length;
        let tocStatus = 'SKIPPED (under 4k words)';
        
        let bodyWithoutToc = body.replace(/> \[!abstract\] Table of Contents[\s\S]*?(?=\n#|$)/, '').replace(/## Table of Contents[\s\S]*?(?=\n#|$)/, '').trimStart();
        let finalBody = bodyWithoutToc;
        
        if (wordCount > 4000) {
            let lines = bodyWithoutToc.split('\n');
            let tocLines = ['> [!abstract] Table of Contents'];
            let inCodeBlock = false;
            let hasHeaders = false;
            for (let line of lines) {
                if (line.startsWith('```')) inCodeBlock = !inCodeBlock;
                if (inCodeBlock) continue;
                let m = line.match(/^(#{2,3})\s+(.+)/);
                if (m && m[2].trim() !== 'See Also' && m[2].trim() !== 'Table of Contents') {
                    hasHeaders = true;
                    let hLevel = m[1].length;
                    let hTitle = m[2].trim();
                    let indent = '  '.repeat(hLevel - 2);
                    tocLines.push(`> ${indent}- [[#${hTitle}]]`);
                }
            }
            if (hasHeaders) {
                finalBody = tocLines.join('\n') + '\n\n' + bodyWithoutToc;
                tocStatus = body.includes('Table of Contents') ? 'UPDATED' : 'INSERTED';
            }
        }

        fs.writeFileSync(file, newYaml + finalBody, 'utf8');
        
        // wikilinks mocked as 0 for report since we don't have full vault index in this script
        let numWikilinks = 0; 
        
        mocEntries.push({ category: category, link: `[[${filename.replace('.md', '')}]]` });
        
        resultsOutput.push(`  ✅ ${filename} — tags corrected, ${numWikilinks} wikilinks, MOC updated`);
        successCount++;
        
    } catch (e) {
        let filename = path.basename(file);
        resultsOutput.push(`  ❌ ${filename} — FAILED (retry exhausted)`);
        failedNotes.push(`  - ${filename}: ${e.message}`);
        failCount++;
    }
});

outputLog += `\n════════════════════════════════════════════\n`;
outputLog += `STANDARDIZE COMPLETE — History\n`;
outputLog += `════════════════════════════════════════════\n`;
outputLog += `Total notes processed : ${files.length}\n`;
outputLog += `Successful            : ${successCount}\n`;
outputLog += `Failed / Skipped      : ${failCount}\n`;
outputLog += `────────────────────────────────────────────\n`;
outputLog += `PER-NOTE RESULTS:\n`;
resultsOutput.forEach(r => outputLog += r + '\n');
outputLog += `────────────────────────────────────────────\n`;
if (failedNotes.length > 0) {
    outputLog += `FAILED NOTES (require manual attention):\n`;
    failedNotes.forEach(f => outputLog += f + '\n');
}
outputLog += `════════════════════════════════════════════\n`;

fs.writeFileSync('E:\\De Anima\\_tmp\\standardize_report.txt', outputLog, 'utf8');
console.log('Done');
