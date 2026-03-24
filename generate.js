const { execSync } = require('child_process');
const fs = require('fs');

const headings = [
  "1. Linguistic Definition, Spiritual Significance, and the Concept of Witr in Islamic Tradition",
  "2. The Legal Status (Hukm) of Witr: Sunnah Mu'akkadah vs. Wajib (Detailed breakdown of textual evidences)",
  "3. Detailed Methodology of the Hanafi School: Three Rak'ahs, Connection, and the Wajib Qunut",
  "4. Detailed Methodology of the Maliki School: The Separation (Fasl) of Shaf' and Witr, and the Amal of Madinah",
  "5. Detailed Methodology of the Shafi'i and Hanbali Schools: Flexibility, Textual Primacy, and Qunut Variations",
  "6. Timing of Witr: Optimal Hours, Ramadan Congregations, and Rulings on Qada (Making up Missed Witr)"
];

const promptBase = "You are acting as Al-Ghazali. Write an exhaustive, 800-1000 word section for an Islamic Fiqh note about 'Salat al-Witr'. Do not include generic introductions or conclusions outside the scope of this heading. Provide extreme depth, classical references (e.g., Al-Muwatta, Al-Hidayah, Al-Umm, Al-Mughni), and academic rigor. Output ONLY the markdown content for this heading: ";

let finalContent = '---\ndate: 2026-03-24\ntags: [islam, fiqh, ibadat, hanafi, maliki, shafii, hanbali]\naliases: ["Salat al-Witr", "The Witr Prayer", "Fiqh of Witr"]\n---\n\n# FIQH - The Prayer of Witr: Rulings, Methodologies, and Variations Across the Four Madhabs\n\n';

for (let i = 0; i < headings.length; i++) {
  console.log('Generating chunk ' + (i + 1) + '...');
  try {
    const cmd = `gemini -y -p "${promptBase} \\"${headings[i]}\\""`;
    const output = execSync(cmd, { encoding: 'utf-8', stdio: ['ignore', 'pipe', 'ignore'] });
    
    // Clean up CLI messages
    let lines = output.split('\n');
    let cleanLines = lines.filter(line => 
      !line.includes('YOLO mode is enabled') && 
      !line.includes('Loaded cached credentials') &&
      !line.includes('Loading extension') &&
      !line.includes('MCP context') &&
      !line.includes('Server ') &&
      !line.includes('Registering notification') &&
      !line.includes('Attempt')
    );
    
    finalContent += cleanLines.join('\n') + '\n\n- - -\n\n';
  } catch (e) {
    console.error('Error generating chunk ' + (i+1));
  }
}

fs.writeFileSync('E:\\De Anima\\Islam\\Fiqh\\Ibadat\\FIQH - The Prayer of Witr.md', finalContent);
console.log('Successfully generated complete note.');