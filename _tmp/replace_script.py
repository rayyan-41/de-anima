import os
import glob

def replace_in_files(directories, old_text, new_text):
    for directory in directories:
        if not os.path.exists(directory):
            continue
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(('.md', '.yaml', '.json', '.ps1')):
                    filepath = os.path.join(root, file)
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            content = f.read()
                        
                        if old_text in content:
                            new_content = content.replace(old_text, new_text)
                            with open(filepath, 'w', encoding='utf-8') as f:
                                f.write(new_content)
                            print(f"Updated {filepath}")
                    except Exception as e:
                        print(f"Failed to process {filepath}: {e}")

if __name__ == "__main__":
    dirs = [
        r"E:\De Anima\.agents",
        r"E:\De Anima\.gemini",
        r"E:\De Anima\_tmp",
        r"E:\De Anima",
        r"C:\Users\Pc\.gemini\config\plugins\de_anima"
    ]
    replace_in_files(dirs, "gemini -y", "agy --dangerously-skip-permissions")
    print("Done")
