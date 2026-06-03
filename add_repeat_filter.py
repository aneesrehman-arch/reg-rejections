#!/usr/bin/env python3

BASE = "c:/Users/rehmaan/Desktop/Claude Projects/REG Rejections"

with open(f"{BASE}/index.html", encoding="utf-8") as f:
    html = f.read()

# ── 1. Add filter bar to Repeat Rejections tab HTML ──
repeat_filter_bar = """  <!-- vendor filter -->
  <div class="vendor-filter">
    <span>Vendor:</span>
    <button class="vf-btn active"     onclick="filterRepeatVendor('all',    this)">All</button>
    <button class="vf-btn"            onclick="filterRepeatVendor('tek',    this)">TEKsystems</button>
    <button class="vf-btn"            onclick="filterRepeatVendor('circet', this)">Circet</button>
  </div>

  """

html = html.replace(
    '<div id="tab-repeats" class="tab-panel">\n  <div class="section">',
    '<div id="tab-repeats" class="tab-panel">\n' + repeat_filter_bar + '<div class="section">'
)
print("Repeat tab filter bar added")

# ── 2. Tag rows with data-vendor when built in JS ──
# Add vendor computation right after "sortedGroups.forEach(([eng, projects]) => {"
old_foreach = "sortedGroups.forEach(([eng, projects]) => {\n  const tbody = eng.includes('(ISA)') ? tbodyIsa : tbodyCx;\n  // Engineer group header row\n  const groupTr = document.createElement('tr');\n  groupTr.className = 'eng-group-row';"

new_foreach = """sortedGroups.forEach(([eng, projects]) => {
  const tbody = eng.includes('(ISA)') ? tbodyIsa : tbodyCx;
  const _tekEngs = new Set(['Shennay Hampton - TEK', 'Allison Schmidt', 'Tamara Gil']);
  const _vendor = _tekEngs.has(eng.replace(' (ISA)', '')) ? 'tek' : 'circet';
  // Engineer group header row
  const groupTr = document.createElement('tr');
  groupTr.className = 'eng-group-row';
  groupTr.dataset.vendor = _vendor;"""

html = html.replace(old_foreach, new_foreach)
print("Vendor computation added to sortedGroups loop")

# ── 3. Tag proj-header row ──
old_tr = "    const tr = document.createElement('tr');\n    tr.className = 'proj-header';"
new_tr = "    const tr = document.createElement('tr');\n    tr.className = 'proj-header';\n    tr.dataset.vendor = _vendor;"
html = html.replace(old_tr, new_tr)
print("proj-header vendor tag added")

# ── 4. Tag detailTr ──
old_detail = "    const detailTr = document.createElement('tr');\n    detailTr.className = 'proj-detail-row';"
new_detail = "    const detailTr = document.createElement('tr');\n    detailTr.className = 'proj-detail-row';\n    detailTr.dataset.vendor = _vendor;"
html = html.replace(old_detail, new_detail)
print("proj-detail-row vendor tag added")

# ── 5. Add filterRepeatVendor JS function ──
filter_fn = """
/* ── Repeat tab vendor filter ── */
function filterRepeatVendor(v, btn) {
  document.querySelectorAll('#tab-repeats .vf-btn').forEach(b => {
    b.classList.remove('active', 'tek-active', 'circ-active');
  });
  if (v === 'all')    btn.classList.add('active');
  if (v === 'tek')    btn.classList.add('tek-active');
  if (v === 'circet') btn.classList.add('circ-active');

  ['repeat-tbody-cx', 'repeat-tbody-isa'].forEach(id => {
    const tbody = document.getElementById(id);
    if (!tbody) return;
    tbody.querySelectorAll('tr[data-vendor]').forEach(tr => {
      const show = v === 'all' || tr.dataset.vendor === v;
      tr.style.display = show ? '' : 'none';
      // Collapse hidden detail rows
      if (!show) {
        tr.classList.remove('expanded', 'open');
      }
    });

    // Update badge count for visible eng-group-rows
    const visibleProjects = [...tbody.querySelectorAll('tr.proj-header[data-vendor]')]
      .filter(tr => tr.style.display !== 'none').length;
    const badgeId = id === 'repeat-tbody-cx' ? 'badge-repeat-cx' : 'badge-repeat-isa';
    const badge = document.getElementById(badgeId);
    if (badge) badge.textContent = visibleProjects + ' project' + (visibleProjects !== 1 ? 's' : '');
  });
}

"""

html = html.replace(
    "/* ── Vendor filter ── */\nfunction filterVendor",
    filter_fn + "/* ── Vendor filter ── */\nfunction filterVendor"
)
print("filterRepeatVendor JS added")

# ── 6. Write ──
with open(f"{BASE}/index.html", "w", encoding="utf-8") as f:
    f.write(html)
with open(f"{BASE}/rejection_summary.html", "w", encoding="utf-8") as f:
    f.write(html)
print("Done.")
