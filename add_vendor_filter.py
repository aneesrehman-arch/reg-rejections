#!/usr/bin/env python3
import re

BASE = "c:/Users/rehmaan/Desktop/Claude Projects/REG Rejections"

with open(f"{BASE}/index.html", encoding="utf-8") as f:
    html = f.read()

# ── 1. Add CSS for vendor filter bar ──
css = """
    /* ── vendor filter ── */
    .vendor-filter {
      display: flex; align-items: center; gap: 8px;
      padding: 12px 20px; margin-bottom: 16px;
      background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 10px;
    }
    .vendor-filter span { font-size: 13px; color: #6b7280; font-weight: 500; margin-right: 4px; }
    .vf-btn {
      padding: 5px 16px; border-radius: 20px;
      border: 1.5px solid #d1d5db; background: #fff; color: #374151;
      font-size: 13px; cursor: pointer; font-weight: 500; transition: all 0.15s;
    }
    .vf-btn:hover { border-color: #9ca3af; background: #f3f4f6; }
    .vf-btn.active { background: #1f2937; color: #fff; border-color: #1f2937; }
    .vf-btn.tek-active  { background: #4f46e5; color: #fff; border-color: #4f46e5; }
    .vf-btn.circ-active { background: #0891b2; color: #fff; border-color: #0891b2; }
"""

html = html.replace(
    "    /* callouts */",
    css + "\n    /* callouts */"
)
print("CSS added")

# ── 2. Add vendor filter bar HTML inside tab-overview ──
filter_bar = """
  <!-- vendor filter -->
  <div class="vendor-filter">
    <span>Vendor:</span>
    <button class="vf-btn active"     onclick="filterVendor('all',    this)">All</button>
    <button class="vf-btn"            onclick="filterVendor('tek',    this)">TEKsystems</button>
    <button class="vf-btn"            onclick="filterVendor('circet', this)">Circet</button>
  </div>

"""

html = html.replace(
    '<!-- REG ENG CX -->',
    filter_bar + '<!-- REG ENG CX -->'
)
print("Filter bar HTML added")

# ── 3. Fix ISA colgroup: 4 -> 5 col-month ──
old_isa_col = (
    '        <col class="col-eng">\n'
    '        <col class="col-month"><col class="col-month"><col class="col-month"><col class="col-month">\n'
    '        <col class="col-total"><col class="col-trend"><col class="col-repeat">'
)
new_isa_col = (
    '        <col class="col-eng">\n'
    '        <col class="col-month"><col class="col-month"><col class="col-month"><col class="col-month"><col class="col-month">\n'
    '        <col class="col-total"><col class="col-trend"><col class="col-repeat">'
)
# Only replace the ISA one (second occurrence)
idx = html.index(old_isa_col, html.index('badge isa'))
html = html[:idx] + new_isa_col + html[idx + len(old_isa_col):]
print("ISA colgroup fixed")

# ── 4. Tag each <tr> in CX and ISA tbody with data-vendor ──
TEK = {"Shennay Hampton - TEK", "Allison Schmidt", "Tamara Gil"}

def tag_rows(html, badge_marker):
    badge_pos = html.index(badge_marker)
    tbody_start = html.index("<tbody>", badge_pos) + 7
    tbody_end   = html.index("</tbody>", badge_pos)
    body = html[tbody_start:tbody_end]

    def replace_row(m):
        tr_open = m.group(1)   # <tr> or <tr class="...">
        name_match = re.search(r'class="engineer">([^<]+)<', m.group(0))
        if not name_match:
            return m.group(0)  # grand-total-row or unexpected
        name = name_match.group(1).strip()
        vendor = "tek" if name in TEK else "circet"
        # Inject data-vendor into the opening <tr> tag
        if 'data-vendor' in tr_open:
            return m.group(0)  # already tagged
        new_open = tr_open.rstrip('>') + f' data-vendor="{vendor}">'
        return m.group(0).replace(tr_open, new_open, 1)

    tagged = re.sub(r'(<tr(?:\s[^>]*)?>)(.*?)</tr>', replace_row, body, flags=re.DOTALL)
    return html[:tbody_start] + tagged + html[tbody_end:]

html = tag_rows(html, '<span class="badge cx">')
print("CX rows tagged")
html = tag_rows(html, '<span class="badge isa">CALL_SIGN')
print("ISA rows tagged")

# ── 5. Add filterVendor JS function ──
filter_js = """
/* ── Vendor filter ── */
function filterVendor(v, btn) {
  document.querySelectorAll('.vf-btn').forEach(b => {
    b.classList.remove('active', 'tek-active', 'circ-active');
  });
  if (v === 'all')    btn.classList.add('active');
  if (v === 'tek')    btn.classList.add('tek-active');
  if (v === 'circet') btn.classList.add('circ-active');

  // Show/hide data rows in both overview tables
  document.querySelectorAll('#tab-overview tbody tr[data-vendor]').forEach(tr => {
    tr.style.display = (v === 'all' || tr.dataset.vendor === v) ? '' : 'none';
  });

  // Recompute grand totals for each overview table
  document.querySelectorAll('#tab-overview .section table').forEach(table => {
    const gtr = table.querySelector('.grand-total-row');
    if (!gtr) return;
    const visRows = [...table.querySelectorAll('tbody tr[data-vendor]')]
                    .filter(tr => tr.style.display !== 'none');
    // Month cells start at td[1]; total at td[6]; trend at td[7]
    const sums = [0, 0, 0, 0, 0];
    visRows.forEach(tr => {
      const tds = tr.querySelectorAll('td');
      for (let i = 0; i < 5; i++) {
        sums[i] += parseInt(tds[i + 1].textContent) || 0;
      }
    });
    const total = sums.reduce((a, b) => a + b, 0);
    const gtCells = gtr.querySelectorAll('td');
    for (let i = 0; i < 5; i++) gtCells[i + 1].textContent = sums[i];
    gtCells[6].textContent = total;
    const may = sums[4], apr = sums[3];
    const trendEl = gtCells[7];
    if (may > apr)      trendEl.innerHTML = '<span class="trend-up">\\u2191 Up</span>';
    else if (may < apr) trendEl.innerHTML = '<span class="trend-down">\\u2193 Down</span>';
    else                trendEl.innerHTML = '<span class="trend-flat">\\u2192 Flat</span>';
  });
}

"""

# Insert before initEngineers IIFE
html = html.replace(
    "/* ── Build engineer expand buttons",
    filter_js + "/* ── Build engineer expand buttons"
)
print("filterVendor JS added")

# ── 6. Write ──
with open(f"{BASE}/index.html", "w", encoding="utf-8") as f:
    f.write(html)
with open(f"{BASE}/rejection_summary.html", "w", encoding="utf-8") as f:
    f.write(html)
print("Done.")
