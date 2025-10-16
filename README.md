# Fellows & Associates Documentation Repository

This repository contains documentation and guides for various applications and services maintained by Fellows & Associates.

## Repository Structure

```
Fellows-Associates/
├── DO/                      # DigitalOcean guides and tutorials
│   └── HowTo/              # How-to guides for DigitalOcean
│       └── rsa_id/         # SSH key management
├── Markdown/               # Main documentation
│   ├── Home.md            # Wiki home page (auto-generated)
│   └── [Application Docs] # Application-specific documentation
└── Update-WikiHome.ps1     # Automation script for updating Home.md
```

## Automated Wiki Home Updates

This repository includes a PowerShell script that automatically generates the `Markdown/Home.md` file by scanning for all markdown files in the repository.

### Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell Core 7+ (Windows/Mac/Linux)
- Git repository access

### Usage

#### Basic Usage

Simply run the script from the repository root:

```powershell
.\Update-WikiHome.ps1
```

This will:
1. Scan the repository for all markdown files
2. Organize them by category (Applications, DigitalOcean, etc.)
3. Generate a new `Markdown/Home.md` with links to all documentation
4. Display a summary of linked files

#### Dry Run Mode

To see what changes would be made without modifying any files:

```powershell
.\Update-WikiHome.ps1 -DryRun
```

#### Custom Repository Path

If running from a different location:

```powershell
.\Update-WikiHome.ps1 -RepoRoot "C:\Path\To\Fellows-Associates"
```

### Features

- **Automatic Discovery**: Finds all `.md` files in the repository
- **Smart Categorization**: Organizes files by directory structure
- **Title Extraction**: Reads H1 headers from markdown files for link text
- **Description Detection**: Attempts to extract brief descriptions
- **Relative Path Handling**: Generates correct relative links
- **Safe Operations**: Excludes `Home.md`, `README.md`, and `.git` folder
- **Timestamp Tracking**: Adds last updated timestamp to generated file
- **Color-Coded Output**: Easy-to-read console output with emoji indicators

### Adding New Documentation

1. **Create your markdown file** in the appropriate directory:
   - `DO/` for DigitalOcean guides
   - `Markdown/[AppName]/` for application documentation

2. **Include a clear H1 header** at the top of your file:
   ```markdown
   # Your Document Title
   ```

3. **Optionally add a description** on the second or third line:
   ```markdown
   # Your Document Title

   This guide explains how to configure XYZ feature.
   ```

4. **Run the update script**:
   ```powershell
   .\Update-WikiHome.ps1
   ```

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Add new documentation and update wiki home"
   git push
   ```

### Example Workflow

```powershell
# 1. Create a new documentation file
New-Item -Path "DO/HowTo/Backup/droplet-backup-guide.md" -ItemType File -Force

# 2. Edit the file with your content
code "DO/HowTo/Backup/droplet-backup-guide.md"

# 3. Preview what the script will do
.\Update-WikiHome.ps1 -DryRun

# 4. Update the wiki home
.\Update-WikiHome.ps1

# 5. Review the changes
git diff Markdown/Home.md

# 6. Commit everything
git add .
git commit -m "Add droplet backup guide"
git push
```

## Contributing

When adding new documentation:

1. Use clear, descriptive filenames
2. Include a descriptive H1 header
3. Follow markdown best practices
4. Run `Update-WikiHome.ps1` before committing
5. Test all links in the generated `Home.md`

## Support

For issues or questions, please open an issue on the [GitHub repository](https://github.com/rfellows-ops/Fellows-Associates).

## License

Documentation in this repository is intended for internal use by Fellows & Associates.
