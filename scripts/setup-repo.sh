#!/bin/bash
#
# Setup script for new CodingWithCalvin repositories
# Run after creating a repo from a template
#
# Usage: ./setup-repo.sh <repo-name>
# Example: ./setup-repo.sh VS-MyNewExtension
#

set -e

ORG="CodingWithCalvin"

if [ -z "$1" ]; then
  echo "Usage: $0 <repo-name>"
  echo "Example: $0 VS-MyNewExtension"
  exit 1
fi

REPO="$1"
FULL_REPO="$ORG/$REPO"

echo "Setting up repository: $FULL_REPO"
echo ""

# Check if repo exists
if ! gh repo view "$FULL_REPO" > /dev/null 2>&1; then
  echo "Error: Repository $FULL_REPO not found"
  exit 1
fi

echo "1. Configuring repository settings..."
gh api "repos/$FULL_REPO" -X PATCH \
  -F has_issues=true \
  -F has_projects=false \
  -F has_wiki=false \
  -F has_discussions=true \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  -F allow_auto_merge=false \
  -F web_commit_signoff_required=false \
  --silent

echo "   - Issues: enabled"
echo "   - Projects: disabled"
echo "   - Wiki: disabled"
echo "   - Discussions: enabled"
echo "   - Merge commits: disabled"
echo "   - Rebase merge: disabled"
echo "   - Squash merge: enabled"
echo "   - Delete branch on merge: enabled"
echo ""

echo "2. Creating branch ruleset..."
gh api "repos/$FULL_REPO/rulesets" -X POST --input - --silent << 'EOF'
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
EOF

echo "   - Bypass: Organization Admins"
echo "   - Prevent deletion: enabled"
echo "   - Prevent force push: enabled"
echo "   - Require PR: enabled"
echo "   - Required approvals: 1"
echo "   - Dismiss stale reviews: enabled"
echo "   - Allowed merge: squash only"
echo ""

echo "Done! Repository $FULL_REPO is configured."
echo ""
echo "View settings: https://github.com/$FULL_REPO/settings"
echo "View ruleset: https://github.com/$FULL_REPO/settings/rules"
