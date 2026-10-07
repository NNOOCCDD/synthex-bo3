"""Regenerate the zombie-cham materials: 7 colours for every style (7 x 7 = 49 materials).
Keep the total small: the client maps duplicate-render materials into a limited table - with 217 materials most styles
stopped drawing (2026-10-07), 49 worked. Rainbow cycles through these 7 colours.
Rewrites the sx_cham_* / i_sx_* entries in mod/synthex/gdts/synthex.gdt and the cham block in the zm/mp zone files.
Material names (zone): mc/sx_cham_<style>_<colour>  colours: pink red green cyan gold white purple h00..h23
styles: z (solid, depth tested)  w (through walls)  rim  glitch  clone (hex shimmer)  flow  hacked"""
import os, re, subprocess

ROOT = os.path.join(os.path.dirname(__file__), "..", "mod", "synthex")
# index order = menu order; rainbow goes red -> orange -> yellow -> green -> cyan -> blue -> pink
COLOURS = [("pink", (1, 0.31, 0.65)), ("red", (1, 0.1, 0.1)), ("orange", (1, 0.5, 0.05)), ("yellow", (1, 0.92, 0.15)),
           ("green", (0.25, 1, 0.35)), ("cyan", (0.15, 0.9, 1)), ("blue", (0.2, 0.35, 1))]
STYLES = ["z", "w", "rim", "glitch", "clone", "flow", "hacked"]

def image(name, src, sem):
    return ('\t"%s" ( "image.gdf" )\n\t{\n\t\t"type" "image"\n\t\t"baseImage" "mods\\\\synthex\\\\images\\\\%s.tif"\n'
            '\t\t"semantic" "%s"\n\t\t"compressionMethod" "uncompressed"\n\t\t"streamable" "0"\n\t}\n') % (name, src, sem)

def material(name, typ, kv):
    body = "".join('\t\t"%s" "%s"\n' % (k, v) for k, v in kv)
    return ('\t"%s" ( "material.gdf" )\n\t{\n\t\t"materialCategory" "Specialty"\n\t\t"materialType" "%s"\n'
            '\t\t"surfaceType" "<none>"\n%s\t}\n') % (name, typ, body)

def style_material(style, cname, rgb):
    r, g, b = rgb
    col = "%s %s %s 1" % (r, g, b)
    tint = [("cg02_x", r), ("cg02_y", g), ("cg02_z", b), ("cg02_w", 1)]
    name = "sx_cham_%s_%s" % (style, cname)
    if style == "z":
        return material(name, "hud_outline_model_z", tint)
    if style == "w":
        return material(name, "hud_outline_model", tint)
    if style == "rim":
        return material(name, "sonar_rim", tint + [("cg00_x", "2.5")])
    if style in ("glitch", "clone"):
        tex = "i_sx_scan" if style == "glitch" else "i_sx_hex"
        scroll = [("gUVScroll02_Angle", "0"), ("gUVScroll03_Angle", "0.6")] if style == "glitch" else [("gUVScroll02_Angle", "0.15"), ("gUVScroll03_Angle", "0.25")]
        return material(name, "lit_emissive_" + style, [
            ("ignoreScriptVectors", "1"), ("colorMap", tex), ("colorMap00", tex), ("flickerLookupMap", "i_sx_lookup"),
            ("colorTint", "1 1 1 1"), ("colorTint1", col), ("scaleRGB", "6"), ("emissiveFalloff", "1"),
            ("cg00_x", "1"), ("cg00_y", "0"), ("cg01_x", "1"), ("cg00_z", "0.4"), ("cg00_w", "16"),
            ("uvMotionToggle1", "1"), ("detailScaleX", "3"), ("detailScaleY", "3")] + scroll)
    if style == "flow":
        # this techset ignores the tint, so its texture is pre-coloured
        return material(name, "emissive_passthrough_flow", [
            ("colorMap00", "i_sx_hex_" + cname), ("colorMap01", "i_sx_plasma"), ("colorMap02", "i_sx_flow"), ("colorMap04", "i_sx_noise"),
            ("colorTint1", col), ("scaleRGB", "5"), ("cg04_x", "4"), ("cg04_y", "0.3"),
            ("cg05_x", "0.002"), ("cg05_y", "0.003"), ("cg05_z", "0.1"), ("cg05_w", "1")])
    return material(name, "hacked", [("colorMap00", "i_sx_hex"), ("colorTint", col), ("uScale", "3"), ("vScale", "3"), ("scaleRGB", "4")])

def tinted(cname, rgb):
    """images/sx_hex_<colour>.tif = the hex grid multiplied by the colour (needs ImageMagick)"""
    img = os.path.join(ROOT, "images")
    col = "rgb(%d,%d,%d)" % tuple(int(c * 255) for c in rgb)
    subprocess.check_call(["magick", os.path.join(img, "sx_hex.tif"), "(", "-size", "256x256", "xc:" + col, ")",
                           "-compose", "multiply", "-composite", "-depth", "8", "-type", "TrueColorAlpha", "-compress", "None",
                           os.path.join(img, "sx_hex_%s.tif" % cname)])

def main():
    p = os.path.join(ROOT, "gdts", "synthex.gdt")
    gdt = open(p).read()
    # drop previously generated entries
    gdt = re.sub(r'\t"(sx_cham_[a-z0-9_]+|i_sx_[a-z_]+)" \( "[a-z]+\.gdf" \)\n\t\{\n(?:\t\t[^\n]*\n)*?\t\}\n', "", gdt)
    gdt = gdt.rstrip()
    assert gdt.endswith("}")
    ent = (image("i_sx_hex", "sx_hex", "diffuseMap") + image("i_sx_scan", "sx_scan", "diffuseMap") + image("i_sx_plasma", "sx_plasma", "diffuseMap")
           + image("i_sx_flow", "sx_flow", "2d") + image("i_sx_noise", "sx_plasma", "multipleMask") + image("i_sx_lookup", "sx_lookup", "revealMap"))
    for cname, (r, g, b) in COLOURS:
        tinted(cname, (r, g, b))
        ent += image("i_sx_hex_" + cname, "sx_hex_" + cname, "diffuseMap")
    names = []
    for style in STYLES:
        for cname, rgb in COLOURS:
            ent += style_material(style, cname, rgb)
            names.append("mc/sx_cham_%s_%s" % (style, cname))
    open(p, "w").write(gdt[:-1] + ent + "}\n")

    block = "// zombie chams (generated by tools/gen_chams.py)\n" + "".join("material,%s\n" % n for n in names) + "\n"
    for z in ("zm_mod.zone", "mp_mod.zone"):
        zp = os.path.join(ROOT, "zone_source", z)
        s = open(zp).read()
        s = re.sub(r"// zombie chams[^\n]*\n(?:material,mc/sx_cham_[^\n]*\n)*\n?", "", s)
        s = s.replace("// SYNTHEX.VIP Lua menu", block + "// SYNTHEX.VIP Lua menu", 1)
        open(zp, "w").write(s)
    print(len(names), "materials")

main()
