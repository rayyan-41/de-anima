const fs = require('fs');
const path = require('path');

const dir = 'E:/De Anima/Reason';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.md'));

const sacredFiles = ['Chain Of Thoughts.md', 'REAS - Chain Of Thoughts.md'];

files.forEach(file => {
  if (sacredFiles.includes(file)) return;
  const filePath = path.join(dir, file);
  let content = fs.readFileSync(filePath, 'utf8');

  let date = 'Unknown';
  let tags = '[]';

  // Extract from existing YAML if it exists
  const yamlMatch = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (yamlMatch) {
    const yaml = yamlMatch[1];
    const dateMatch = yaml.match(/date:\s*(.*)/);
    const tagsMatch = yaml.match(/tags:\s*(.*)/);
    if (dateMatch) date = dateMatch[1].trim();
    if (tagsMatch) tags = tagsMatch[1].trim();
    content = content.replace(/^---\r?\n[\s\S]*?\r?\n---/, '');
  }
  
  // Extract from body (e.g., **DATE:**, **TAGS:**) and remove those lines
  const bodyDateMatch = content.match(/\*\*DATE:\*\*\s*(.*)/i);
  const bodyTagsMatch = content.match(/\*\*TAGS:\*\*\s*(.*)/i);
  if (bodyDateMatch && date === 'Unknown') date = bodyDateMatch[1].trim();
  if (bodyTagsMatch && tags === '[]') tags = bodyTagsMatch[1].trim();

  // Remove specific metadata and property lines
  content = content.replace(/\*\*Metadata:\*\*[\s\S]*?(- - -|---)/gi, '');
  content = content.replace(/\*\*DATE:\*\*.*?\r?\n/gi, '');
  content = content.replace(/\*\*TAGS:\*\*.*?\r?\n/gi, '');
  content = content.replace(/^(- - -|---)\s*/gm, ''); // Clean up leading/trailing separators if they become redundant
  
  content = content.trim();

  const newYaml = `---\ndate: ${date}\ntags: ${tags}\n---\n\n`;
  fs.writeFileSync(filePath, newYaml + content);
});
