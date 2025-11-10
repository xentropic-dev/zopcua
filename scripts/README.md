# Scripts

Utility scripts for maintaining the zopcua project.

## update_roadmap.py

Automatically calculates and updates completion percentages in `docs/ROADMAP.md` and `README.md`.

### Usage

```bash
python3 scripts/update_roadmap.py
```

### What it does

1. **Parses the roadmap** - Reads `docs/ROADMAP.md` and counts all items
2. **Calculates percentages** - Based on checkmark status:
   - ✅ Complete: 1.0 (100%)
   - 🟡 Partial: 0.5 (50%)
   - 🔴 Minimal: 0.1 (10%)
   - ❌ Missing: 0.0 (0%)
3. **Updates ROADMAP.md** - Modifies the roadmap file in-place:
   - Overall progress in header
   - Section progress lines
   - Subsection percentages
   - Category summary table
4. **Updates README.md** - Updates the progress bar and percentages:
   - Feature parity percentage
   - Visual progress bar
   - Contributing section percentage

### When to run

Run this script whenever you:
- Add new items to the roadmap
- Change item status (❌ → 🔴 → 🟡 → ✅)
- Want to verify current completion percentages

### Roadmap Format Requirements

The script expects this format:

```markdown
## X. Section Name

**Progress: XX%**

### X.Y Subsection Name (XX% emoji)
- ✅ Item description
- ❌ Item description
- 🟡 Item description
- 🔴 Item description
```

**Important:**
- Keep section numbering (1., 2., 3., etc.)
- Keep subsection numbering (1.1, 1.2, etc.)
- Use exactly one of: ✅ 🟡 🔴 ❌ at the start of each item line
- Progress line must be exactly `**Progress: XX%**` (no extra text)

### Output

The script prints a summary of all calculated percentages and then updates the roadmap file.

Example output:
```
Calculating completion percentages...

Results:
----------------------------------------------------------------------
OVERALL                                   25.2% (169/670)
----------------------------------------------------------------------
Client Core                               10.2% (22/216)
Configuration                             20.7% (12/58)
Data Types                                48.8% (42/86)
...

Updating ROADMAP.md...
✅ Done! ROADMAP.md has been updated with calculated percentages.
```
