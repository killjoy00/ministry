#!/usr/bin/env python3
"""Lightweight local source check when Godot is unavailable. Not an engine test."""
from pathlib import Path
import configparser
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
needed = [
    'project.godot','scenes/main.tscn','scripts/main.gd',
    'scripts/simulation/case_simulation.gd','scripts/scenarios/fowl_election.gd',
    'tests/smoke.gd', 'docs/GAME_DESIGN.md','docs/TEST_PLAN.md',
    'export_presets.cfg','.github/workflows/ci.yml',
    '.github/workflows/builds.yml', 'AGENTS.md'
]
for item in needed:
    assert (root / item).exists(), f'Missing {item}'

for p in root.rglob('*.gd'):
    code = p.read_text()
    assert '\t' in code, f'{p} expected tabs for GDScript indentation'
    opened = []
    pairs = {')': '(', ']': '[', '}': '{'}
    string = None
    comment = False
    escape = False
    for char in code:
        if char == '\n':
            comment = False
        if comment:
            continue
        if string:
            if escape:
                escape = False
            elif char == '\\':
                escape = True
            elif char == string:
                string = None
            continue
        if char == '#':
            comment = True
        elif char in ('"', "'"):
            string = char
        elif char in '([{':
            opened.append(char)
        elif char in ')]}':
            assert opened and opened.pop() == pairs[char], f'Unbalanced delimiters {p}'
    assert not opened and not string, f'Unclosed delimiter/string {p}'

preset = configparser.ConfigParser()
preset.read(root / 'export_presets.cfg')
assert preset['preset.0']['name'] == '"Linux"'
assert preset['preset.1']['name'] == '"Windows Desktop"'

result = subprocess.run([sys.executable, str(root / 'tests/validate_catalog.py')],
                        capture_output=True, text=True, check=True)
print(result.stdout.strip())
print(f'Project structure PASS: {len(needed)} core files, GDScript delimiters, Linux/Windows preset shape.')
print('Godot runtime compilation and platform playtests remain REQUIRED.')
