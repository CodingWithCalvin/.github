#
# Setup script for new CodingWithCalvin repositories
# Run after creating a repo from a template
#
# Usage: .\setup-repo.ps1 <repo-name>
# Example: .\setup-repo.ps1 VS-MyNewExtension
#

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$RepoName
)

$ErrorActionPreference = "Stop"

$Org = "CodingWithCalvin"
$FullRepo = "$Org/$RepoName"

Write-Host "Setting up repository: $FullRepo" -ForegroundColor Cyan
Write-Host ""

# Check if repo exists
$repoCheck = gh repo view $FullRepo 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Repository $FullRepo not found" -ForegroundColor Red
    exit 1
}

Write-Host "1. Configuring repository settings..." -ForegroundColor Yellow
gh api "repos/$FullRepo" -X PATCH `
    -F has_issues=true `
    -F has_projects=false `
    -F has_wiki=false `
    -F has_discussions=true `
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
Write-Host "   - Merge commits: disabled" -ForegroundColor Green
Write-Host "   - Rebase merge: disabled" -ForegroundColor Green
Write-Host "   - Squash merge: enabled" -ForegroundColor Green
Write-Host "   - Delete branch on merge: enabled" -ForegroundColor Green
Write-Host "   - Suggest updating PR branches: enabled" -ForegroundColor Green
Write-Host ""

Write-Host "2. Creating branch ruleset..." -ForegroundColor Yellow

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
Write-Host ""

Write-Host "Done! Repository $FullRepo is configured." -ForegroundColor Cyan
Write-Host ""
Write-Host "View settings: https://github.com/$FullRepo/settings"
Write-Host "View ruleset: https://github.com/$FullRepo/settings/rules"
