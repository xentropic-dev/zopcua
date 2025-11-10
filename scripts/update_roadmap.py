#!/usr/bin/env python3
"""
Calculate and update completion percentages in ROADMAP.md.

This script parses the roadmap, counts completed items (✅, 🟡, 🔴, ❌),
and updates all percentage values automatically.

Usage:
    python3 scripts/update_roadmap.py
"""

import re
from pathlib import Path
from typing import Dict, Tuple

def parse_subsection(lines: list[str], start_idx: int) -> Tuple[int, int, int]:
    """
    Parse a subsection (### heading) and count completed vs total items.
    Returns (completed_count, total_count, next_subsection_idx)

    Scoring:
    - ✅ Complete: 1.0
    - 🟡 Partial: 0.5
    - 🔴 Minimal: 0.1
    - ❌ Missing: 0.0
    """
    completed = 0
    total = 0
    i = start_idx + 1  # Skip the ### line itself

    while i < len(lines):
        line = lines[i].strip()

        # Stop at next subsection or main section
        if (line.startswith('###') or line.startswith('##')) and i > start_idx:
            break

        # Count items
        if line.startswith('- ✅'):
            completed += 1
            total += 1
        elif line.startswith('- ❌'):
            total += 1
        elif line.startswith('- 🟡'):
            completed += 0.5
            total += 1
        elif line.startswith('- 🔴'):
            completed += 0.1
            total += 1

        i += 1

    return completed, total, i

def calculate_percentages(filepath: str) -> Dict[str, Tuple[float, int, int]]:
    """
    Calculate completion percentages for each section in the roadmap.
    Returns dict of section_name -> (percentage, completed, total)
    """
    with open(filepath, 'r') as f:
        lines = f.readlines()

    results = {}
    i = 0
    current_section = None

    while i < len(lines):
        line = lines[i].strip()

        # Main sections (## heading)
        if line.startswith('## ') and not line.startswith('###'):
            # Extract section name (e.g., "## 1. Server Core Functionality")
            section_match = re.match(r'^##\s+\d+\.\s+(.+)$', line)
            if section_match:
                current_section = section_match.group(1)

                # Find all subsections and calculate
                section_completed = 0
                section_total = 0
                j = i + 1

                while j < len(lines):
                    subline = lines[j].strip()

                    # Stop at next main section
                    if subline.startswith('## ') and not subline.startswith('###'):
                        break

                    # Process subsection
                    if subline.startswith('### '):
                        subsection_match = re.match(r'^###\s+\d+\.\d+\s+(.+?)\s+\((\d+)%', subline)
                        if subsection_match:
                            subsection_name = subsection_match.group(1)
                            completed, total, j = parse_subsection(lines, j)
                            section_completed += completed
                            section_total += total

                            # Store subsection result
                            full_name = f"{current_section} > {subsection_name}"
                            if total > 0:
                                results[full_name] = (completed / total * 100, int(completed), total)
                        else:
                            j += 1
                    else:
                        j += 1

                # Store main section result
                if section_total > 0:
                    results[current_section] = (section_completed / section_total * 100, int(section_completed), section_total)

                i = j
                continue

        i += 1

    # Calculate category summaries
    categories = {
        'Server Core': [],
        'Client Core': [],
        'Data Types': [],
        'Configuration': [],
        'Error Handling': [],
        'Testing': [],
        'Documentation': []
    }

    for key, (pct, comp, tot) in results.items():
        for cat in categories.keys():
            if key.startswith(cat):
                categories[cat].append((comp, tot))

    # Calculate category percentages
    for cat, items in categories.items():
        if items:
            total_completed = sum(c for c, _ in items)
            total_items = sum(t for _, t in items)
            if total_items > 0:
                results[f"CATEGORY: {cat}"] = (total_completed / total_items * 100, int(total_completed), total_items)

    # Calculate overall percentage
    all_completed = sum(comp for key, (_, comp, _) in results.items() if not key.startswith('CATEGORY:'))
    all_total = sum(tot for key, (_, _, tot) in results.items() if not key.startswith('CATEGORY:'))
    if all_total > 0:
        results['OVERALL'] = (all_completed / all_total * 100, int(all_completed), all_total)

    return results

def update_roadmap(filepath: str, percentages: Dict[str, Tuple[float, int, int]]):
    """Update the ROADMAP.md file with calculated percentages."""
    with open(filepath, 'r') as f:
        content = f.read()

    # Update overall percentage in header
    if 'OVERALL' in percentages:
        pct, comp, tot = percentages['OVERALL']
        # Match: **Overall Progress: XX%**
        content = re.sub(
            r'\*\*Overall Progress:\s*\d+%\*\*',
            f'**Overall Progress: {pct:.0f}%**',
            content
        )

    # Update section percentages (## X. Section Name followed by **Progress: XX%**)
    for section, (pct, comp, tot) in percentages.items():
        if section.startswith('CATEGORY:') or section.startswith('OVERALL') or '>' in section:
            continue

        # Update main section progress line
        # Pattern: ## X. Section Name\n\n**Progress: XX%**
        pattern = rf'(##\s+\d+\.\s+{re.escape(section)})\s*\n\n\*\*Progress:\s*\d+%\*\*'
        replacement = rf'\1\n\n**Progress: {pct:.0f}%**'
        content = re.sub(pattern, replacement, content)

    # Update subsection percentages (### X.Y Subsection (XX% emoji))
    for section, (pct, comp, tot) in percentages.items():
        if '>' not in section:
            continue

        parts = section.split(' > ')
        if len(parts) == 2:
            subsection = parts[1]

            # Determine emoji based on percentage
            if pct == 100:
                emoji = '✅'
            elif pct >= 70:
                emoji = '🟡'
            elif pct >= 30:
                emoji = '🟡'
            elif pct > 0:
                emoji = '🔴'
            else:
                emoji = '❌'

            # Match pattern like "### 1.1 Server Lifecycle (100% ✅)"
            pattern = rf'(###\s+\d+\.\d+\s+{re.escape(subsection)})\s+\(\d+%\s*[✅🟡🔴❌]+\)'
            replacement = rf'\1 ({pct:.0f}% {emoji})'
            content = re.sub(pattern, replacement, content)

    # Update category summary table
    if 'CATEGORY: Server Core' in percentages:
        # Build new table
        table_lines = [
            '| Category | Progress | Status |',
            '|----------|----------|--------|'
        ]

        for cat in ['Server Core', 'Client Core', 'Data Types', 'Configuration', 'Error Handling', 'Testing', 'Documentation']:
            key = f'CATEGORY: {cat}'
            if key in percentages:
                pct, comp, tot = percentages[key]
                if pct == 100:
                    status = '✅ Complete'
                elif pct >= 70:
                    status = '✅ Good'
                elif pct >= 40:
                    status = '🟡 Partial'
                elif pct > 0:
                    status = '🔴 Minimal'
                else:
                    status = '❌ Missing'
                table_lines.append(f'| {cat} | {pct:.0f}% | {status} |')

        # Add overall
        if 'OVERALL' in percentages:
            pct, comp, tot = percentages['OVERALL']
            if pct >= 70:
                status = '✅ Good'
            elif pct >= 40:
                status = '🟡 Partial'
            elif pct > 0:
                status = '🔴 Early'
            else:
                status = '❌ Missing'
            table_lines.append(f'| **Overall** | **{pct:.0f}%** | {status} |')

        # Replace table
        table_pattern = r'\| Category \| Progress \| Status \|.*?\n\n'
        table_replacement = '\n'.join(table_lines) + '\n\n'
        content = re.sub(table_pattern, table_replacement, content, flags=re.DOTALL)

    # Write back
    with open(filepath, 'w') as f:
        f.write(content)

def update_readme(readme_path: str, percentage: float):
    """Update the progress bar and percentage in README.md"""
    with open(readme_path, 'r') as f:
        content = f.read()

    # Calculate progress bar (20 blocks total)
    filled = int(percentage / 5)  # Each block represents 5%
    empty = 20 - filled
    progress_bar = '█' * filled + '░' * empty

    # Update feature parity line
    content = re.sub(
        r'\*\*Feature Parity:\*\* \d+% complete',
        f'**Feature Parity:** {percentage:.0f}% complete',
        content
    )

    # Update progress bar
    pattern = r'```\nProgress: \[.*?\] \d+%\n```'
    replacement = f'```\nProgress: [{progress_bar}] {percentage:.0f}%\n```'
    content = re.sub(pattern, replacement, content)

    # Update other percentage references
    content = re.sub(
        r'The library is at \d+% parity',
        f'The library is at {percentage:.0f}% parity',
        content
    )

    with open(readme_path, 'w') as f:
        f.write(content)

def main():
    # Get paths relative to script location
    script_dir = Path(__file__).parent
    roadmap_path = script_dir.parent / 'docs' / 'ROADMAP.md'
    readme_path = script_dir.parent / 'README.md'

    if not roadmap_path.exists():
        print(f"Error: ROADMAP.md not found at {roadmap_path}")
        return 1

    print("Calculating completion percentages...")
    percentages = calculate_percentages(str(roadmap_path))

    print("\nResults:")
    print("-" * 70)

    # Print overall first
    overall_pct = 0
    if 'OVERALL' in percentages:
        pct, comp, tot = percentages['OVERALL']
        overall_pct = pct
        print(f"{'OVERALL':40s} {pct:5.1f}% ({comp}/{tot})")
        print("-" * 70)

    # Print categories
    for key in sorted(percentages.keys()):
        if key.startswith('CATEGORY:'):
            pct, comp, tot = percentages[key]
            cat_name = key.replace('CATEGORY: ', '')
            print(f"{cat_name:40s} {pct:5.1f}% ({comp}/{tot})")

    print("\nUpdating ROADMAP.md...")
    update_roadmap(str(roadmap_path), percentages)

    if readme_path.exists():
        print("Updating README.md...")
        update_readme(str(readme_path), overall_pct)

    print("✅ Done! Documentation has been updated with calculated percentages.")
    return 0

if __name__ == '__main__':
    exit(main())
