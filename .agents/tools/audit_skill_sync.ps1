param(
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Read-ContentSafe {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        Add-Failure "Missing file: $Path"
        return ""
    }
    return Get-Content -Path $Path -Raw
}

$domainAgents = @(
    'agents\avicenna.md',
    'agents\michelangelo.md',
    'agents\machiavelli.md',
    'agents\ghazali.md',
    'agents\haytham.md',
    'agents\tolstoy.md'
)

$requiredSkillFiles = @(
    'skills\yolo_generation_protocol\SKILL.md',
    'skills\obsidian_yaml_enforcer\SKILL.md',
    'skills\obsidian_wikilink_engine\SKILL.md'
)

$requiredAgentRefs = @{
    'agents\avicenna.md'    = @('skills\\yolo_generation_protocol\\SKILL.md', 'skills\\obsidian_yaml_enforcer\\SKILL.md')
    'agents\michelangelo.md' = @('skills\\yolo_generation_protocol\\SKILL.md', 'skills\\obsidian_yaml_enforcer\\SKILL.md')
    'agents\machiavelli.md'  = @('skills\\yolo_generation_protocol\\SKILL.md', 'skills\\obsidian_yaml_enforcer\\SKILL.md')
    'agents\ghazali.md'      = @('skills\\yolo_generation_protocol\\SKILL.md', 'skills\\obsidian_yaml_enforcer\\SKILL.md')
    'agents\haytham.md'      = @('skills\\yolo_generation_protocol\\SKILL.md', 'skills\\obsidian_yaml_enforcer\\SKILL.md')
    'agents\tolstoy.md'      = @('skills\\yolo_generation_protocol\\SKILL.md', 'skills\\obsidian_yaml_enforcer\\SKILL.md')
}

$bannedPatterns = @(
    @{ Name = 'legacy DATE header'; Pattern = '(?mi)^\s*DATE:\s*YYYY-MM-DD\s*$' },
    @{ Name = 'legacy TAGS # header'; Pattern = '(?mi)^\s*TAGS:\s*#' },
    @{ Name = 'embedded YOLO sleep 15'; Pattern = 'Start-Sleep\s+-Seconds\s+15' },
    @{ Name = 'embedded YOLO sleep 30'; Pattern = 'Start-Sleep\s+-Seconds\s+30' },
    @{ Name = 'embedded YOLO prompt block'; Pattern = 'gemini\s+-y\s+-p\s+"Write\s+a\s+detailed' },
    @{ Name = 'old non-centralized heading'; Pattern = 'SECTION-BY-SECTION EXECUTION PROTOCOL\s+—\s+MANDATORY' }
)

# 1) Ensure required skill files exist
foreach ($skillFile in $requiredSkillFiles) {
    if (-not (Test-Path $skillFile)) {
        Add-Failure "Required skill missing: $skillFile"
    }
}

# 2) Ensure domain agents reference required centralized skills and do not contain duplicated protocol logic
foreach ($agent in $domainAgents) {
    $content = Read-ContentSafe -Path $agent
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    foreach ($requiredPattern in $requiredAgentRefs[$agent]) {
        if ($content -notmatch $requiredPattern) {
            Add-Failure "$agent is missing required skill reference pattern: $requiredPattern"
        }
    }

    foreach ($rule in $bannedPatterns) {
        if ($content -match $rule.Pattern) {
            Add-Failure "$agent contains forbidden pattern: $($rule.Name)"
        }
    }
}

# 3) Verify that all skill path references in active architecture docs resolve to existing files
$activeDocs = @(
    'GEMINI.md',
    'VAULT_CONTEXT_GEMINI .md',
    'agents\tagger.md',
    'agents\weaver.md',
    'agents\linker.md',
    'agents\technician.md'
) + $domainAgents

$skillRefRegex = 'c:\\Users\\Pc\\.gemini\\skills\\([^\\]+)\\SKILL\.md'

foreach ($doc in $activeDocs) {
    $content = Read-ContentSafe -Path $doc
    if ([string]::IsNullOrWhiteSpace($content)) { continue }

    $matches = [regex]::Matches($content, $skillRefRegex)
    foreach ($m in $matches) {
        $skillName = $m.Groups[1].Value
        $expectedPath = Join-Path 'skills' "$skillName\SKILL.md"
        if (-not (Test-Path $expectedPath)) {
            Add-Failure "$doc references missing skill file: $expectedPath"
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host 'SKILL SYNC AUDIT: FAIL' -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host 'SKILL SYNC AUDIT: PASS' -ForegroundColor Green
if ($VerboseOutput) {
    Write-Host "Checked domain agents: $($domainAgents.Count)"
    Write-Host "Checked active docs: $($activeDocs.Count)"
    Write-Host "Verified skills: $($requiredSkillFiles.Count)"
}
exit 0
