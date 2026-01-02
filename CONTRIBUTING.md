# Contributing to Coding With Calvin Projects

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to projects in the Coding With Calvin organization.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/REPO_NAME.git
   cd REPO_NAME
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/CodingWithCalvin/REPO_NAME.git
   ```
4. Follow any project-specific setup instructions in the repository's README

## Code Style and Conventions

- Follow standard coding conventions for the language used in the project
- Use meaningful variable and method names
- Keep methods focused and concise
- Check the project's README or CLAUDE.md for any project-specific guidelines

## Branch Naming Conventions

Use the format: `type/short-description`

Examples:
- `feat/settings-dialog`
- `fix/crash-on-startup`
- `docs/update-readme`

## Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/). Format:

```
type(scope): description
```

### Commit Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance tasks |
| `ci` | CI/CD changes |

### Examples

```
feat(ui): add dark mode toggle
fix(api): handle null response gracefully
docs(readme): update installation instructions
```

## Submitting Pull Requests

### Before You Start

1. Check existing issues and PRs to avoid duplicate work
2. For significant changes, open an issue first to discuss your approach
3. Create a new branch from an updated `main` branch

### Pull Request Process

1. Update your fork:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. Create a feature branch:
   ```bash
   git checkout -b feat/your-feature-name
   ```

3. Make your changes and commit using conventional commit format

4. Push to your fork:
   ```bash
   git push origin feat/your-feature-name
   ```

5. Open a pull request against `main`

### Pull Request Guidelines

- Use conventional commit format for the PR title (e.g., `feat(scope): description`)
- Provide a clear description of the changes
- Reference any related issues (e.g., "Closes #123")
- Ensure the build passes
- Keep PRs focused - one feature or fix per PR

## Testing Requirements

- Ensure the project builds without errors
- Test your changes before submitting
- Follow any project-specific testing guidelines in the README

## Getting Help

- Open an issue for bugs or feature requests
- Use discussions for questions and general help

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
