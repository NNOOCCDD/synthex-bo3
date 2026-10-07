"""Static check the linker doesn't do: every local function a GSC/CSC file calls or points to (&fn) must be
defined in that file. A missing one only shows up in game as 'Unresolved external' and stops the mod loading."""
import glob, os, re, sys

ROOT = os.path.join(os.path.dirname(__file__), "..", "mod", "synthex", "scripts")
KEYWORDS = {"if", "while", "for", "foreach", "switch", "return", "function", "wait", "waittill", "notify", "endon", "thread",
            "isdefined", "array", "int", "float", "abs", "spawnstruct"}
bad = 0
for path in glob.glob(os.path.join(ROOT, "**", "*.gs[ch]"), recursive=True) + glob.glob(os.path.join(ROOT, "**", "*.csc"), recursive=True):
    src = open(path, errors="replace").read()
    code = re.sub(r"//[^\n]*|/\*.*?\*/", "", src, flags=re.S)
    code = re.sub(r'"(\\.|[^"\\])*"', '""', code)
    defined = set(m.lower() for m in re.findall(r"^\s*function\s+(?:private\s+|autoexec\s+)*(\w+)\s*\(", code, re.M))
    pointers = set(m.lower() for m in re.findall(r"&(\w+)\b(?!\s*::)", code))
    missing = sorted(p for p in pointers if p not in defined and not p.startswith('"'))
    if "/scripts/shared/" in path.replace("\\", "/") and path.endswith("music_shared.csc"):
        continue  # stock file
    for m in missing:
        print("%s: &%s is not defined in this file" % (os.path.relpath(path), m))
        bad += 1
sys.exit(1 if bad else 0)
