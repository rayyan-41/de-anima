import json
import os
import glob

agents_dir = r'C:\Users\Pc\.gemini\antigravity-cli\plugins\de_anima\agents'
agents = []

for filepath in glob.glob(os.path.join(agents_dir, '*', 'agent.json')):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
        
    name = data.get('name', 'Unknown')
    desc = data.get('description', 'No desc')
    
    prompt = ''
    try:
        sys_inst = data.get('config', {}).get('systemInstructions', [])
        if sys_inst and isinstance(sys_inst, list):
            prompt = sys_inst[0].get('text', '')
    except Exception as e:
        prompt = str(e)
        
    agents.append(f"AGENT: {name}\nDESCRIPTION: {desc}\nPROMPT LENGTH: {len(prompt)} chars\n")

with open(r'E:\De Anima\_tmp\agents_review.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(agents))
