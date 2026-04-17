const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const readdir = promisify(fs.readdir);
const stat = promisify(fs.stat);

async function walk(dir, fileList = []) {
  const files = await readdir(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    if (filePath.includes('.trash')) continue;
    
    const fileStat = await stat(filePath);
    if (fileStat.isDirectory()) {
      await walk(filePath, fileList);
    } else {
      if (file.endsWith('.md') && (file.toLowerCase().includes('map of contents') || file.toLowerCase().includes('moc'))) {
        fileList.push(filePath);
      }
    }
  }
  return fileList;
}

function parseMarkdownTable(text) {
  const rows = text.trim().split('\n').map(r => r.trim());
  if (rows.length < 3) return [];
  
  const headers = rows[0].split('|').map(h => h.trim()).filter(h => h);
  const dataRows = rows.slice(2);
  
  const parsed = [];
  for (const row of dataRows) {
    if (!row.includes('|')) continue;
    const cells = row.split('|').map(c => c.trim()).slice(1, -1);
    if (cells.length === 0) continue;
    parsed.push(cells);
  }
  return parsed;
}

function extractLinks(cell) {
  const linkRegex = /\[\[(.*?)\]\]/g;
  const links = [];
  let match;
  while ((match = linkRegex.exec(cell)) !== null) {
    links.push(`[[${match[1]}]]`);
  }
  return links;
}

async function processMocs() {
  const files = await walk('E:\\De Anima');
  
  const mocsData = {};
  let scienceMergedCategories = {};
  const today = '2026-04-17';
  const reviewDate = '2026-10-17';
  
  for (const file of files) {
    const content = fs.readFileSync(file, 'utf-8');
    
    // Extract frontmatter
    const frontmatterMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    const frontmatter = frontmatterMatch ? frontmatterMatch[0] : '';
    
    // Extract lines
    const lines = content.substring(frontmatter.length).split('\n');
    let proseLines = [];
    let inTable = false;
    let currentTable = [];
    let categories = {}; // Category -> Set of links
    
    for (let line of lines) {
      const t = line.trim();
      
      // Ignore known boilerplate lines
      if (t === '- - -' || t.startsWith('**Metadata:**') || t.startsWith('- Last Major Reorganization:') || 
          t.startsWith('- Total Notes:') || t.startsWith('## Structure') || t.startsWith('## Notes') ||
          t.startsWith('*Last MOC Update:') || t.startsWith('*Next Review:') || t.startsWith('*Total Notes:') ||
          t.startsWith('*Last Updated:')) {
        continue;
      }
      
      // Table detection
      if (t.startsWith('|')) {
        inTable = true;
        currentTable.push(t);
        continue;
      } else if (inTable) {
        // End of table
        inTable = false;
        const parsed = parseMarkdownTable(currentTable.join('\n'));
        for (const row of parsed) {
          // Identify category and notes
          let cat = 'Uncategorized';
          let notesStr = '';
          
          if (row.length >= 2) {
            if (row[0] && row[0].toLowerCase() !== 'title' && row[0] !== '') {
              cat = row[0];
              notesStr = row[1];
            } else if (row.length >= 3 && row[1].includes('[[')) {
              // Format: Title | Link | Date Added
              cat = 'Uncategorized';
              notesStr = row[1];
            } else {
              cat = row[0];
              notesStr = row[1];
            }
          }
          
          const links = extractLinks(notesStr);
          if (!categories[cat]) categories[cat] = new Set();
          links.forEach(l => categories[cat].add(l));
        }
        currentTable = [];
      }
      
      if (!inTable && t.length > 0 && !t.startsWith('#')) {
        proseLines.push(line); // Preserve original indentation for blockquotes
      }
    }
    
    // Check grammar for specific cases
    let prose = proseLines.join('\n').trim();
    prose = prose.replace('indexes the modern events', 'indexes modern events');
    
    mocsData[file] = {
      frontmatter,
      prose,
      categories
    };
    
    if (file.includes('_Science - Map of Contents.md')) {
      for (const [cat, links] of Object.entries(categories)) {
        if (!scienceMergedCategories[cat]) scienceMergedCategories[cat] = new Set();
        links.forEach(l => scienceMergedCategories[cat].add(l));
      }
    }
  }
  
  // Merge Science files
  const scienceMain = 'E:\\De Anima\\Science\\Map of Contents - Science.md';
  const scienceLegacy = 'E:\\De Anima\\Science\\_Science - Map of Contents.md';
  
  if (mocsData[scienceMain] && mocsData[scienceLegacy]) {
    const mainCats = mocsData[scienceMain].categories;
    for (const [cat, links] of Object.entries(scienceMergedCategories)) {
      // Map 'Uncategorized' to 'Computer Science' or similar if needed. For now, put in 'Computer Science' if it contains AI stuff, or just 'AI'.
      let targetCat = cat === 'Uncategorized' ? 'Artificial Intelligence' : cat;
      if (!mainCats[targetCat]) mainCats[targetCat] = new Set();
      links.forEach(l => mainCats[targetCat].add(l));
    }
  }
  
  // Now write the files
  for (const [file, data] of Object.entries(mocsData)) {
    if (file === scienceLegacy) {
      fs.unlinkSync(file); // Delete the legacy file
      continue;
    }
    
    const dirname = path.dirname(file);
    const folderName = path.basename(dirname);
    // Correct filename format: Map of Contents - [Domain/Subdomain].md
    // To find Domain/Subdomain, if root of domain it's Domain. If in a subfolder, it's Subfolder.
    let expectedName = `Map of Contents - ${folderName}.md`;
    if (folderName === 'Early and Late Medieval (476- 1799)') expectedName = 'Map of Contents - Early and Late Medieval.md';
    if (folderName === 'Contemporary (1800 - Present)') expectedName = 'Map of Contents - Contemporary.md';
    
    const expectedPath = path.join(dirname, expectedName);
    
    // Count notes
    let totalNotes = 0;
    const sortedCats = Object.keys(data.categories).sort();
    
    let tableStr = '| Topic Area | Notes | Last Updated |\n|-----------|-----------|--------------|\n';
    
    for (const cat of sortedCats) {
      if (data.categories[cat].size === 0) continue;
      const links = Array.from(data.categories[cat]);
      // Normalize category capitalization
      const displayCat = cat.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
      
      tableStr += `| ${displayCat} | ${links.join(', ')} | ${today} |\n`;
      totalNotes += links.length;
    }
    
    // Construct new content
    let newContent = `${data.frontmatter}\n\n`;
    if (data.prose) {
      newContent += `${data.prose}\n\n`;
    }
    
    // Metadata block
    let lastReorg = today;
    // try to extract from frontmatter or prose
    const dateMatch = data.frontmatter.match(/date:\s*(\d{4}-\d{2}-\d{2})/);
    if (dateMatch) lastReorg = dateMatch[1];
    
    newContent += `**Metadata:**\n- Last Major Reorganization: ${lastReorg}\n- Total Notes: ${totalNotes}\n- - -\n`;
    newContent += `## Structure\n${tableStr}- - -\n\n`;
    newContent += `*Last MOC Update: ${today} by GeminiCLI*\n*Next Review: ${reviewDate}*\n`;
    
    // Write new content
    fs.writeFileSync(expectedPath, newContent);
    
    // Delete old file if renamed
    if (file !== expectedPath) {
      fs.unlinkSync(file);
    }
  }
}

processMocs().catch(console.error);
