# Quick Start Guide - Wiki Home Automation

## For Windows Users

### Method 1: Double-Click (Easiest)

Simply double-click `Update-Wiki.bat` in the repository root.

### Method 2: PowerShell

```powershell
.\Update-WikiHome.ps1
```

## For Mac/Linux Users

### Option 1: PowerShell Core

```bash
pwsh Update-WikiHome.ps1
```

### Option 2: Make it executable (one-time setup)

```bash
chmod +x Update-WikiHome.ps1
./Update-WikiHome.ps1
```

## Common Commands

| Command | Description |
|---------|-------------|
| `.\Update-WikiHome.ps1` | Update Home.md with all documentation links |
| `.\Update-WikiHome.ps1 -DryRun` | Preview changes without modifying files |
| `.\Update-WikiHome.ps1 -Verbose` | Show detailed output |

## Workflow

1. **Create** a new markdown file anywhere in the repo
2. **Add** a clear `# Title` at the top
3. **Run** `Update-Wiki.bat` or `.\Update-WikiHome.ps1`
4. **Commit** your changes

That's it! Your new documentation is now linked in `Markdown/Home.md`

## Troubleshooting

**"Cannot be loaded because running scripts is disabled"**
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**"pwsh is not recognized"**
- Install PowerShell Core from: https://github.com/PowerShell/PowerShell
- Or use Windows PowerShell: `powershell -File Update-WikiHome.ps1`

**"Permission denied" (Mac/Linux)**
```bash
chmod +x Update-WikiHome.ps1
```

## Questions?

See the full [README.md](README.md) for detailed documentation.
