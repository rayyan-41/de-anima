import os
import json

agent_dir = r'E:/De Anima/.agents/agents'
for file in os.listdir(agent_dir):
    if file.endswith('.md'):
        filepath = os.path.join(agent_dir, file)
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            content = f.read().strip()
        
        if content.startswith('---'):
            parts = content.split('---', 2)
            if len(parts) == 3:
                frontmatter_text = parts[1].strip()
                body = parts[2].strip()
                
                # Parse simple frontmatter
                name = file.replace('.md', '')
                description = ''
                for line in frontmatter_text.splitlines():
                    if line.strip().startswith('name:'):
                        name = line.split('name:', 1)[1].strip().strip('\"\'')
                    elif line.strip().startswith('description:'):
                        description = line.split('description:', 1)[1].strip().strip('\"\'')
                
                # Write manually formatted yaml
                new_filepath = os.path.join(agent_dir, file.replace('.md', '.yaml'))
                with open(new_filepath, 'w', encoding='utf-8') as f:
                    f.write(f'name: "{name}"\n')
                    f.write(f'description: {json.dumps(description)}\n')
                    f.write('enable_write_tools: true\n')
                    f.write('enable_mcp_tools: true\n')
                    f.write('system_prompt: |-\n')
                    for line in body.splitlines():
                        f.write(f'  {line}\n')
                
                print(f'Converted {file} to {file.replace(".md", ".yaml")}')
