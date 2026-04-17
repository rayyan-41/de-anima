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

async function extractData() {
  const files = await walk('E:\\De Anima');
  const result = {};

  for (const file of files) {
    const content = fs.readFileSync(file, 'utf-8');
    
    // Extract frontmatter
    const frontmatterMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
    const frontmatter = frontmatterMatch ? frontmatterMatch[0] : '';
    
    // Extract everything between frontmatter and **Metadata:**
    let prose = '';
    const afterFrontmatter = content.substring(frontmatter.length);
    
    const metadataIndex = afterFrontmatter.indexOf('**Metadata:**');
    if (metadataIndex !== -1) {
      prose = afterFrontmatter.substring(0, metadataIndex).trim();
    } else {
      // Find where ## Structure starts if no metadata
      const structureIndex = afterFrontmatter.indexOf('## Structure');
      if (structureIndex !== -1) {
          prose = afterFrontmatter.substring(0, structureIndex).trim();
      } else {
          prose = afterFrontmatter.trim();
      }
    }
    
    result[file] = {
      content: content,
      frontmatter: frontmatter,
      prose: prose,
    };
  }
  
  fs.writeFileSync('E:\\De Anima\\_tmp\\mocs_data.json', JSON.stringify(result, null, 2));
}

extractData().catch(console.error);
