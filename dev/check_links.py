"""Generic Markdown checks for the MKB deliverable: relative links + anchors, front matter parse, line counts."""
import re, sys, os, unicodedata
from pathlib import Path
import yaml

ROOT = Path(sys.argv[1])
LINK = re.compile(r'(?<!\!)\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
FENCE = re.compile(r'^\s*(```|~~~)')

def strip_code(text):
    out, infence = [], False
    for line in text.splitlines():
        if FENCE.match(line):
            infence = not infence
            out.append('')
            continue
        out.append('' if infence else re.sub(r'`[^`]*`', '', line))
    return out

def slug(h):
    h = h.strip().lower()
    h = re.sub(r'[^\w\- ]', '', h, flags=re.UNICODE)
    return h.replace(' ', '-')

def anchors(path):
    res, infence = set(), False
    for line in path.read_text(encoding='utf-8').splitlines():
        if FENCE.match(line):
            infence = not infence
            continue
        if infence:
            continue
        m = re.match(r'^(#{1,6})\s+(.*?)\s*#*\s*$', line)
        if m:
            s = slug(m.group(2))
            base, n = s, 1
            while s in res:
                s = f'{base}-{n}'; n += 1
            res.add(s)
    return res

errors, stats = [], []
for md in sorted(ROOT.rglob('*.md')):
    if '.git' in md.parts:
        continue
    text = md.read_text(encoding='utf-8')
    rel = md.relative_to(ROOT)
    stats.append((len(text.splitlines()), str(rel)))
    if text.startswith('---'):
        parts = text.split('\n---', 1)
        if len(parts) < 2:
            errors.append(f'{rel}: unterminated front matter')
        else:
            try:
                yaml.safe_load(parts[0][3:])
            except Exception as e:
                errors.append(f'{rel}: bad YAML front matter: {e}')
    for i, line in enumerate(strip_code(text), 1):
        for m in LINK.finditer(line):
            target = m.group(2)
            if re.match(r'^[a-z]+:', target) or target.startswith('mailto:'):
                continue
            path, _, frag = target.partition('#')
            dest = md if path == '' else (md.parent / path)
            if path and not dest.exists():
                errors.append(f'{rel}:{i}: broken link -> {target}')
                continue
            if frag and dest.is_file() and dest.suffix == '.md':
                if frag.lower() not in anchors(dest):
                    errors.append(f'{rel}:{i}: missing anchor #{frag} in {path or rel}')

print(f'files: {len(stats)}')
for n, f in sorted(stats, reverse=True)[:15]:
    print(f'  {n:5d}  {f}')
print(f'errors: {len(errors)}')
for e in errors:
    print('  ' + e)
sys.exit(1 if errors else 0)
