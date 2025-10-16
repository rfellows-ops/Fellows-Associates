# Wiki Setup and Usage Guide

## Understanding the Two Wiki Systems

This repository uses **two separate documentation systems**:

### 1. Repository Markdown (`/Markdown/Home.md`)
- **Location**: Regular files in this repository under `/Markdown/`
- **URL**: https://github.com/rfellows-ops/Fellows-Associates/blob/main/Markdown/Home.md
- **Purpose**: Internal documentation and navigation within the repository
- **Update Script**: `Update-WikiHome.ps1`

### 2. GitHub Wiki (Separate Repository)
- **Location**: Separate git repository (`Fellows-Associates.wiki`)
- **URL**: https://github.com/rfellows-ops/Fellows-Associates/wiki
- **Purpose**: Public-facing wiki accessible to visitors
- **Update Script**: `Update-GitHubWiki.ps1`

## Quick Start

### Option 1: Update Repository Markdown Only

```powershell
.\Update-WikiHome.ps1
```

This updates `/Markdown/Home.md` with relative links to documentation files in the repository.

### Option 2: Update GitHub Wiki (Recommended)

```powershell
# First time: Clone the wiki repository
cd d:/Code/GitHub  # or wherever your repos are
git clone https://github.com/rfellows-ops/Fellows-Associates.wiki.git

# Update the wiki
cd Fellows-Associates
.\Update-GitHubWiki.ps1 -AutoCommit
```

This updates the public GitHub Wiki with links to documentation in the main repository.

## Complete Workflow

### Adding New Documentation

1. **Create your documentation file** in the main repository:
   ```powershell
   # Example: Add a new DigitalOcean guide
   New-Item -Path "DO/HowTo/Networking/configure-firewall.md" -ItemType File

   # Edit the file
   code "DO/HowTo/Networking/configure-firewall.md"
   ```

2. **Add a clear H1 header** at the top:
   ```markdown
   # How to Configure DigitalOcean Firewall

   This guide shows you how to set up and configure firewall rules for your droplets.
   ```

3. **Update the GitHub Wiki**:
   ```powershell
   .\Update-GitHubWiki.ps1 -AutoCommit
   ```

4. **Commit your documentation**:
   ```bash
   git add .
   git commit -m "Add firewall configuration guide"
   git push
   ```

5. **View the results**:
   - Main repo: https://github.com/rfellows-ops/Fellows-Associates
   - Wiki: https://github.com/rfellows-ops/Fellows-Associates/wiki

## Script Comparison

| Feature | Update-WikiHome.ps1 | Update-GitHubWiki.ps1 |
|---------|-------------------|---------------------|
| **Updates** | `/Markdown/Home.md` | GitHub Wiki `Home.md` |
| **Link Type** | Relative paths | Absolute GitHub URLs |
| **Requires Wiki Clone** | No | Yes |
| **Auto-Commit** | No | Yes (with `-AutoCommit`) |
| **Use Case** | Internal navigation | Public documentation |

## Commands Reference

### Update GitHub Wiki (Recommended)

```powershell
# Preview changes
.\Update-GitHubWiki.ps1 -DryRun

# Update wiki (manual commit)
.\Update-GitHubWiki.ps1

# Update wiki and auto-commit/push
.\Update-GitHubWiki.ps1 -AutoCommit

# Specify custom wiki location
.\Update-GitHubWiki.ps1 -WikiRoot "C:\Custom\Path\Fellows-Associates.wiki"
```

### Update Repository Markdown

```powershell
# Preview changes
.\Update-WikiHome.ps1 -DryRun

# Update Markdown/Home.md
.\Update-WikiHome.ps1
```

## Troubleshooting

### "Wiki repository not found"

**Solution**: Clone the wiki repository first:

```bash
cd d:/Code/GitHub  # Parent directory of your main repo
git clone https://github.com/rfellows-ops/Fellows-Associates.wiki.git
```

The script will auto-detect the wiki if it's in the parent directory of your main repository.

### Manual Wiki Management

If you prefer to manage the wiki manually:

```bash
cd d:/Code/GitHub/Fellows-Associates.wiki
git pull  # Get latest changes
# Edit Home.md manually
git add Home.md
git commit -m "Update wiki home"
git push
```

### Checking Wiki Status

```powershell
cd d:/Code/GitHub/Fellows-Associates.wiki
git status
git log --oneline -5  # See recent changes
```

## Best Practices

1. **Always update the GitHub Wiki** after adding documentation - it's the public-facing version
2. **Use the `-AutoCommit` flag** for convenience
3. **Run `-DryRun` first** to preview changes
4. **Keep the wiki repo cloned** in the same parent directory as your main repo
5. **Commit both repositories** together for consistency

## Additional Resources

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [Markdown Guide](https://www.markdownguide.org/)
- See [README.md](README.md) for detailed script documentation
