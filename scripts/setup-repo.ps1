#
# Setup script for CodingWithCalvin repositories
# Configures repository settings and branch rulesets
#
# Usage:
#   .\setup-repo.ps1 <repo-name>     # Configure a single repo
#   .\setup-repo.ps1 -All            # Configure all repos in the org
#
# Examples:
#   .\setup-repo.ps1 VS-MyNewExtension
#   .\setup-repo.ps1 -All
#

param(
    [Parameter(Position=0)]
    [string]$RepoName,

    [Parameter()]
    [switch]$All
)

$ErrorActionPreference = "Stop"
$Org = "CodingWithCalvin"

function Setup-Repository {
    param(
        [string]$FullRepo
    )

    Write-Host "Setting up repository: $FullRepo" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "1. Configuring repository settings..." -ForegroundColor Yellow
    gh api "repos/$FullRepo" -X PATCH `
        -F has_issues=true `
        -F has_projects=false `
        -F has_wiki=false `
        -F has_discussions=true `
        -F has_sponsorships=true `
        -F allow_squash_merge=true `
        -F allow_merge_commit=false `
        -F allow_rebase_merge=false `
        -F delete_branch_on_merge=true `
        -F allow_update_branch=true `
        -F allow_auto_merge=false `
        -F web_commit_signoff_required=false `
        --silent

    Write-Host "   - Issues: enabled" -ForegroundColor Green
    Write-Host "   - Projects: disabled" -ForegroundColor Green
    Write-Host "   - Wiki: disabled" -ForegroundColor Green
    Write-Host "   - Discussions: enabled" -ForegroundColor Green
    Write-Host "   - Sponsorships: enabled" -ForegroundColor Green
    Write-Host "   - Merge commits: disabled" -ForegroundColor Green
    Write-Host "   - Rebase merge: disabled" -ForegroundColor Green
    Write-Host "   - Squash merge: enabled" -ForegroundColor Green
    Write-Host "   - Delete branch on merge: enabled" -ForegroundColor Green
    Write-Host "   - Suggest updating PR branches: enabled" -ForegroundColor Green
    Write-Host ""

    Write-Host "2. Creating branch ruleset..." -ForegroundColor Yellow

    # Check if ruleset already exists
    $existingRulesets = gh api "repos/$FullRepo/rulesets" 2>$null | ConvertFrom-Json
    $existingRuleset = $existingRulesets | Where-Object { $_.name -eq "PRs to Main" }

    if ($existingRuleset) {
        Write-Host "   - Ruleset 'PRs to Main' already exists, skipping..." -ForegroundColor Yellow
    } else {
        $rulesetJson = @'
{
  "name": "PRs to Main",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    {
      "actor_type": "OrganizationAdmin",
      "bypass_mode": "always"
    }
  ],
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH"],
      "exclude": []
    }
  },
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["squash"]
      }
    }
  ]
}
'@

        $rulesetJson | gh api "repos/$FullRepo/rulesets" -X POST --input - --silent

        Write-Host "   - Bypass: Organization Admins" -ForegroundColor Green
        Write-Host "   - Prevent deletion: enabled" -ForegroundColor Green
        Write-Host "   - Prevent force push: enabled" -ForegroundColor Green
        Write-Host "   - Require PR: enabled" -ForegroundColor Green
        Write-Host "   - Required approvals: 1" -ForegroundColor Green
        Write-Host "   - Dismiss stale reviews: enabled" -ForegroundColor Green
        Write-Host "   - Allowed merge: squash only" -ForegroundColor Green
    }
    Write-Host ""

    Write-Host "Done! Repository $FullRepo is configured." -ForegroundColor Cyan
    Write-Host ""
}

# Main logic
if ($All) {
    Write-Host "Fetching all repositories in $Org..." -ForegroundColor Cyan
    Write-Host ""

    $repos = gh repo list $Org --limit 500 --no-archived --json name --jq '.[].name' | Sort-Object

    if (-not $repos) {
        Write-Host "Error: No repositories found or unable to fetch repos" -ForegroundColor Red
        exit 1
    }

    $repoList = $repos -split "`n" | Where-Object { $_ -ne "" }
    $total = $repoList.Count
    $current = 0

    Write-Host "Found $total repositories" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    foreach ($repo in $repoList) {
        $current++
        Write-Host "[$current/$total] " -NoNewline -ForegroundColor Magenta
        Setup-Repository -FullRepo "$Org/$repo"
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "All $total repositories have been configured!" -ForegroundColor Green
} elseif ($RepoName) {
    $FullRepo = "$Org/$RepoName"

    # Check if repo exists
    $repoCheck = gh repo view $FullRepo 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Repository $FullRepo not found" -ForegroundColor Red
        exit 1
    }

    Setup-Repository -FullRepo $FullRepo

    Write-Host "View settings: https://github.com/$FullRepo/settings"
    Write-Host "View ruleset: https://github.com/$FullRepo/settings/rules"
} else {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\setup-repo.ps1 <repo-name>     # Configure a single repo"
    Write-Host "  .\setup-repo.ps1 -All            # Configure all repos in the org"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup-repo.ps1 VS-MyNewExtension"
    Write-Host "  .\setup-repo.ps1 -All"
    exit 1
}
