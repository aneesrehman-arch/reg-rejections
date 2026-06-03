#!/usr/bin/env python3
import re, sys

BASE = "c:/Users/rehmaan/Desktop/Claude Projects/REG Rejections"

with open(f"{BASE}/index.html", encoding="utf-8") as f:
    html = f.read()

with open(f"{BASE}/eng_js_data_v7.txt", encoding="utf-8") as f:
    js_raw = f.read().rstrip()

# Remove bogus date-keyed ISA entries
js_raw = re.sub(r'"1/22/2026":\s*\[[^\]]*\],?\s*\n', '', js_raw)
js_raw = re.sub(r'"2/10/2026":\s*\[[^\]]*\],?\s*\n', '', js_raw)

# ── 1. Inject new JS data ──
start = html.index("const CX_DATA = {")
isa_start = html.index("const ISA_DATA = {", start)
end = html.index("};", isa_start + 20) + 2
html = html[:start] + js_raw + html[end:]
print("JS data injected")

ndash = "–"
up    = "↑"
down  = "↓"
flat  = "→"
mdash = "—"

def hc(n):
    if n == 0:       return f'<td class="num zero">{mdash}</td>'
    elif n < 10:     return f'<td class="num heat-1">{n}</td>'
    elif n < 20:     return f'<td class="num heat-2">{n}</td>'
    elif n < 30:     return f'<td class="num heat-3">{n}</td>'
    else:            return f'<td class="num heat-4">{n}</td>'

def trend(may, apr):
    if may > apr:    return f'<td class="num"><span class="trend-up">{up} Up</span></td>'
    elif may < apr:  return f'<td class="num"><span class="trend-down">{down} Down</span></td>'
    else:            return f'<td class="num"><span class="trend-flat">{flat} Flat</span></td>'

def mkrow(name, jan, feb, mar, apr, may, tot):
    return (
        f'        <tr>\n'
        f'          <td class="engineer">{name}</td>\n'
        f'          {hc(jan)}\n'
        f'          {hc(feb)}\n'
        f'          {hc(mar)}\n'
        f'          {hc(apr)}\n'
        f'          {hc(may)}\n'
        f'          <td class="total">{tot}</td>\n'
        f'          {trend(may, apr)}\n'
        f'          <td class="num"><span class="repeat-badge low">{mdash}</span></td>\n'
        f'        </tr>'
    )

# ── 2. CX tbody (USR-free counts) ──
cx_rows = [
    ("Raja Magunta",           4,  4, 17, 26,  8,  59),
    ("Tamara Gil",             0, 13,  8, 18,  5,  44),
    ("Allison Schmidt",        0,  5, 10,  7,  7,  29),
    ("Ashutosh Pandey",        5,  4, 18,  0,  0,  27),
    ("Shennay Hampton - TEK",  0,  2,  7,  9,  7,  25),
    ("Yousuf Moiz",            7,  2,  3,  2,  0,  14),
    ("Belem Rios",             3,  0,  1,  5,  3,  12),
    ("Asad Kamran",            3,  2,  2,  4,  1,  12),
    ("Roma Patel",             3,  2,  4,  2,  0,  11),
    ("Victor Durosomo",        3,  2,  2,  1,  0,   8),
    ("Priyatham Tamma",        3,  4,  0,  0,  0,   7),
    ("Kelly Quate",            2,  0,  2,  0,  1,   5),
    ("Maninderjit Hari",       0,  2,  0,  1,  1,   4),
    ("Mazhar Shahzad",         0,  0,  0,  1,  1,   2),
    ("Muhammad Siddiki",       0,  1,  0,  0,  0,   1),
]

cx_body = "\n"
for r in cx_rows:
    cx_body += mkrow(*r) + "\n"
cx_body += (
    f'        <tr class="grand-total-row">\n'
    f'          <td>Grand Total</td>\n'
    f'          <td class="num">33</td>\n'
    f'          <td class="num">43</td>\n'
    f'          <td class="num">74</td>\n'
    f'          <td class="num">76</td>\n'
    f'          <td class="num">34</td>\n'
    f'          <td class="total">260</td>\n'
    f'          <td class="num"><span class="trend-down">{down} Down</span></td>\n'
    f'          <td class="num">{mdash} repeat projects</td>\n'
    f'        </tr>\n'
)

cx_badge = html.index('<span class="badge cx">')
tbody_start = html.index("<tbody>", cx_badge) + 7
tbody_end   = html.index("</tbody>", cx_badge)
html = html[:tbody_start] + cx_body + "      " + html[tbody_end:]
print("CX tbody replaced")

# ── 3. ISA tbody (unchanged counts) ──
isa_rows = [
    ("Belem Rios",             5,  7,  5,  3,  6,  26),
    ("Mazhar Shahzad",        12,  4,  3,  0,  1,  20),
    ("Victor Durosomo",        3,  9,  2,  3,  0,  17),
    ("Yousuf Moiz",            5,  7,  0,  1,  2,  15),
    ("Asad Kamran",            6,  6,  1,  0,  0,  13),
    ("Roma Patel",             5,  6,  0,  0,  1,  12),
    ("Allison Schmidt",        0,  0,  1,  7,  3,  11),
    ("Tamara Gil",             0,  0,  0,  5,  3,   8),
    ("Shennay Hampton - TEK",  0,  0,  0,  5,  2,   7),
    ("Priyatham Tamma",        0,  5,  0,  0,  0,   5),
    ("Raja Magunta",           0,  0,  0,  0,  2,   2),
    ("Maninderjit Hari",       0,  2,  0,  0,  0,   2),
    ("Kelly Quate",            1,  0,  0,  0,  0,   1),
]

isa_body = "\n"
for r in isa_rows:
    isa_body += mkrow(*r) + "\n"
isa_body += (
    f'        <tr class="grand-total-row">\n'
    f'          <td>Grand Total</td>\n'
    f'          <td class="num">37</td>\n'
    f'          <td class="num">46</td>\n'
    f'          <td class="num">12</td>\n'
    f'          <td class="num">24</td>\n'
    f'          <td class="num">20</td>\n'
    f'          <td class="total">139</td>\n'
    f'          <td class="num"><span class="trend-down">{down} Down</span></td>\n'
    f'          <td class="num">{mdash} repeat projects</td>\n'
    f'        </tr>\n'
)

isa_badge = html.index('<span class="badge isa">CALL_SIGN')
isa_tbody_start = html.index("<tbody>", isa_badge) + 7
isa_tbody_end   = html.index("</tbody>", isa_badge)
html = html[:isa_tbody_start] + isa_body + "      " + html[isa_tbody_end:]
print("ISA tbody replaced")

# ── 4. Source line ──
html = re.sub(
    r'Source: May SERegulatoryTrackerALLPROJECTS[^<]*',
    f'Source: May SERegulatoryTrackerALLPROJECTS &nbsp;|&nbsp; May Total Rejection by Month &nbsp;|&nbsp; Jan {ndash} May 2026 &nbsp;|&nbsp; 399 total rejections (CX: 260, ISA: 139)',
    html
)
print("Source line updated")

# ── 5. CX callouts ──
cx_badge_pos = html.index('<span class="badge cx">')
cx_ul_start  = html.index('<ul class="callout-list">', cx_badge_pos) + len('<ul class="callout-list">')
cx_ul_end    = html.index('</ul>', cx_ul_start)
new_cx_cl = (
    f'\n'
    f'        <li><strong>Raja Magunta</strong> {ndash} 59 CIR rejections (Jan{ndash}May); peaked at 26 in April; highest volume</li>\n'
    f'        <li><strong>Tamara Gil</strong> {ndash} 44 CIR rejections; 13 in Feb, 18 in April</li>\n'
    f'        <li><strong>Allison Schmidt</strong> {ndash} 29 rejections; flat in May (7); consistent all months</li>\n'
    f'        <li><strong>Shennay Hampton {ndash} TEK</strong> {ndash} 25 total; escalated: 0{ndash}2{ndash}7{ndash}9{ndash}7</li>\n'
    f'        <li><strong>Ashutosh Pandey</strong> {ndash} 27 total; front-loaded Jan{ndash}Mar; dropped to 0 Apr{ndash}May; likely resolved or reassigned</li>\n'
    f'\n'
)
html = html[:cx_ul_start] + new_cx_cl + html[cx_ul_end:]
print("CX callouts updated")

# ── 6. ISA callouts ──
isa_badge_pos  = html.index('<span class="badge isa">CALL_SIGN')
isa_ul_start   = html.index('<ul class="callout-list">', isa_badge_pos) + len('<ul class="callout-list">')
isa_ul_end     = html.index('</ul>', isa_ul_start)
new_isa_cl = (
    f'\n'
    f'        <li><strong>Belem Rios</strong> {ndash} 26 ISA rejections (Jan{ndash}May); highest volume; steady throughout</li>\n'
    f'        <li><strong>Mazhar Shahzad</strong> {ndash} 20; front-loaded Jan (12), tapering after</li>\n'
    f'        <li><strong>Victor Durosomo</strong> {ndash} 17 total; front-loaded Feb (9), dropped to 0 in May</li>\n'
    f'        <li><strong>Allison Schmidt</strong> {ndash} escalating ISA: 0{ndash}0{ndash}1{ndash}7{ndash}3; 11 ISA on top of 29 CIR</li>\n'
    f'        <li><strong>Volume spread</strong> {ndash} Jan=37, Feb=46, Mar=12, Apr=24, May=20; Mar sharp dip then recovering</li>\n'
    f'\n'
)
html = html[:isa_ul_start] + new_isa_cl + html[isa_ul_end:]
print("ISA callouts updated")

# ── 7. Write ──
with open(f"{BASE}/index.html", "w", encoding="utf-8") as f:
    f.write(html)
with open(f"{BASE}/rejection_summary.html", "w", encoding="utf-8") as f:
    f.write(html)
print("Done.")
