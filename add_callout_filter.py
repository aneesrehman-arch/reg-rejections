#!/usr/bin/env python3

BASE = "c:/Users/rehmaan/Desktop/Claude Projects/REG Rejections"

with open(f"{BASE}/index.html", encoding="utf-8") as f:
    html = f.read()

TEK_NAMES = {"Tamara Gil", "Allison Schmidt", "Shennay Hampton – TEK"}

# Tag each callout <li> by replacing '<li><strong>Name</strong>' with
# '<li data-vendor="tek/circet"><strong>Name</strong>'
# Only within the overview tab
overview_end = html.index('</div><!-- /tab-overview -->')

# Build replacements: scan for all <li><strong>...</strong> in overview
import re
overview = html[:overview_end]

def tag_li_full(m):
    name = m.group(1).strip()
    if name == "Volume spread":   # summary bullet – always visible
        return m.group(0)
    vendor = "tek" if name in TEK_NAMES else "circet"
    return f'<li data-vendor="{vendor}"><strong>{name}</strong>'

tagged = re.sub(r'<li><strong>([^<]+)</strong>', tag_li_full, overview)
html = tagged + html[overview_end:]
print("Callout <li> vendor tags applied")

# Check what got tagged
for m in re.finditer(r'<li data-vendor="(\w+)"><strong>([^<]+)</strong>', html[:overview_end]):
    print(f"  {m.group(1):8s}  {m.group(2)}")

# ── Update filterVendor — add callout filtering if not already there ──
if 'callout-list li[data-vendor]' not in html:
    old = "  // Recompute grand totals for each overview table"
    new = (
        "  // Show/hide callout bullets\n"
        "  document.querySelectorAll('#tab-overview .callout-list li[data-vendor]').forEach(li => {\n"
        "    li.style.display = (v === 'all' || li.dataset.vendor === v) ? '' : 'none';\n"
        "  });\n\n"
        "  // Recompute grand totals for each overview table"
    )
    html = html.replace(old, new)
    print("filterVendor updated for callouts")
else:
    print("filterVendor callout filter already present")

with open(f"{BASE}/index.html", "w", encoding="utf-8") as f:
    f.write(html)
with open(f"{BASE}/rejection_summary.html", "w", encoding="utf-8") as f:
    f.write(html)
print("Done.")
