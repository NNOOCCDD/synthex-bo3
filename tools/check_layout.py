"""Check that every button in the Lua layout (ui/synthex/synthex_spec.lua) reaches a script button.
Buttons send "b|tab|side|label"; the script looks the label up on that page (offmenu_core find_button).
Needs Python with lupa (pip install lupa) to run the Lua spec. Exit code 1 on any unmatched button."""
import glob, os, re, sys
from lupa import LuaRuntime

ROOT = os.path.join(os.path.dirname(__file__), "..", "mod", "synthex")

def lua_buttons():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("CoD = {} ; function require() end")
    lua.execute(open(os.path.join(ROOT, "ui", "synthex", "synthex_spec.lua")).read())
    everything = lua.eval("setmetatable( {}, { __index = function () return true end } )")
    out = {}
    global keys
    keys = {}
    for zm in (True, False):
        rows = []
        tabs = lua.eval("CoD.SynthexSpec.Build")(zm)
        for ti in range(1, len(tabs) + 1):
            t = tabs[ti]
            for si in range(1, len(t.sides) + 1):
                s = t.sides[si]
                cards = s.cards
                if cards is None and s.build is not None:
                    cards = s.build(lua.table(available=everything, players=lua.table(), machines=everything, pap=True, box=True, power=True))
                for ci in range(1, len(cards) + 1):
                    for ri in range(1, len(cards[ci].rows) + 1):
                        r = cards[ci].rows[ri]
                        if r.key and not r.lua and r.k in ("toggle", "slider", "choice"):
                            keys.setdefault("zm" if zm else "mp", set()).add(r.key)
                        if r.k != "button" or r.lua or (s.dynamic == "powerups" and r.id):
                            continue
                        home = r.home or s.home or (t.id + "/" + s.id)
                        rows.append((t.label + " > " + s.label, home.split("/")[1], r.label))
        out["zm" if zm else "mp"] = rows
    return out

def gsc_buttons(files):
    """side id -> set of button labels. Follows offmenu::side() calls, fill functions and builder helpers.
    A side or label that is a variable in the script counts as "*" (matches anything)."""
    by_side = {}
    # functions the script calls through a level hook while filling a page
    fill_side = {"player_extra": "players"}
    last_side = {}          # builder function -> last side it opens (so code after the call continues there)
    srcs = [open(f, errors="replace").read() for f in files]
    side_re = re.compile(r'offmenu::side\(\s*[^,]+,\s*("([^"]+)"|[\w\[\]\s]+)\s*(?:,\s*[^,)]+)?(?:,\s*&(\w+))?')
    for src in srcs:
        func = None
        for line in src.splitlines():
            fm = re.match(r"\s*function\s+(?:private\s+)?(\w+)", line)
            if fm:
                func = fm.group(1)
            m = side_re.search(line)
            if m:
                sid = m.group(2) or "*"
                if m.group(3):
                    fill_side[m.group(3)] = sid
                if func:
                    last_side[func] = sid
    for src in srcs:
        side = None
        for line in src.splitlines():
            fm = re.match(r"\s*function\s+(?:private\s+)?(\w+)", line)
            if fm:
                side = fill_side.get(fm.group(1))
            cm = re.search(r"(?:::|\s)(\w+)\(", line)
            for call in re.findall(r"(?:::)(\w+)\(", line):
                if call in last_side:
                    side = last_side[call]
            m = side_re.search(line)
            if m:
                side = m.group(2) or "*"
            bm = re.search(r'offmenu::button\(\s*("([^"]+)"|\w+)', line)
            if bm and side:
                by_side.setdefault(side, set()).add(bm.group(2) or "*")
    return by_side

def has(gsc, side, label):
    # exact page: the label, or a variable label registered on that page
    labels = gsc.get(side, set())
    if label in labels or "*" in labels:
        return True
    # pages whose id is a variable in the script (weapon categories, positions): literal labels only
    return label in gsc.get("*", set())

common = glob.glob(os.path.join(ROOT, "scripts", "shared", "offmenu", "*.gsc"))
modes = {"zm": common + glob.glob(os.path.join(ROOT, "scripts", "zm", "*.gsc")),
         "mp": common + glob.glob(os.path.join(ROOT, "scripts", "mp", "*.gsc"))}
bad = 0
lua = lua_buttons()
for mode, files in modes.items():
    gsc = gsc_buttons(files)
    for where, side, label in lua[mode]:
        if not has(gsc, side, label):
            print("%s: '%s' on %s -> no script button on page '%s'" % (mode, label, where, side))
            bad += 1
# toggles / sliders: the layout's keys must exist in the script, and no script option may vanish from the menu
for mode, files in modes.items():
    src = "\n".join(open(f, errors="replace").read() for f in files)
    gsc_keys = set(re.findall(r'offmenu::(?:toggle|slider|choice)\(\s*[^,]+,\s*"([^"]+)"(?!\s*\+)', src))
    # keys built as "prefix" + name in the script
    prefixes = tuple(set(re.findall(r'"((?:ov_s|att|perk)_)"\s*\+', src)) | {"perk_", "att_"})
    lua_keys = keys.get(mode, set())
    for k in sorted(lua_keys - gsc_keys):
        if not k.startswith(prefixes):
            print("%s: menu option '%s' has no script toggle/slider" % (mode, k))
            bad += 1
    for k in sorted(gsc_keys - lua_keys):
        print("%s: script option '%s' is not in the menu anywhere" % (mode, k))
        bad += 1
print("layout check:", "OK" if not bad else "%d problem(s)" % bad)
sys.exit(1 if bad else 0)
