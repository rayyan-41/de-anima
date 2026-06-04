import os
import re
import glob

tools_dir = r"E:\De Anima\.agents\tools"
for ps1_file in glob.glob(os.path.join(tools_dir, "*.ps1")):
    with open(ps1_file, "r", encoding="utf-8") as f:
        content = f.read()

    if "run_standardize.ps1" in ps1_file:
        continue

    original = content
    content = content.replace(r'[string]$VaultRoot = "E:\De Anima"', r'[string]$VaultRoot = ""')
    content = content.replace(r'[string]$TmpDir = "E:\De Anima\_tmp"', r'[string]$TmpDir = ""')
    content = content.replace(r'[string]$ToolsDir = "C:\Users\Pc\.antigravity\tools"', r'[string]$ToolsDir = ""')
    content = content.replace(r'"E:\De Anima"', '$VaultRoot')

    param_match = re.search(r'param\s*\([\s\S]*?\)\s*', content)
    if param_match:
        end_idx = param_match.end()
        inject = (
            "\n"
            "if (-not $VaultRoot) { $VaultRoot = (Resolve-Path \"$PSScriptRoot\\..\\..\").Path }\n"
            "if (-not $TmpDir) { $TmpDir = Join-Path $VaultRoot \"_tmp\" }\n"
            "if (-not $ToolsDir) { $ToolsDir = $PSScriptRoot }\n"
            "\n"
        )
        if "if (-not $VaultRoot)" not in content:
            content = content[:end_idx] + inject + content[end_idx:]
    else:
        if "if (-not $VaultRoot)" not in content:
            inject = (
                "$VaultRoot = (Resolve-Path \"$PSScriptRoot\\..\\..\").Path\n"
                "$TmpDir = Join-Path $VaultRoot \"_tmp\"\n"
                "$ToolsDir = $PSScriptRoot\n\n"
            )
            comment_match = re.search(r'^<#[\s\S]*?#>\s*', content)
            if comment_match:
                end_idx = comment_match.end()
                content = content[:end_idx] + inject + content[end_idx:]
            else:
                content = inject + content

    if content != original:
        with open(ps1_file, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Refactored {os.path.basename(ps1_file)}")
