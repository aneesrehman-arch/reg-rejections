Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$up    = [char]0x2191
$down  = [char]0x2193
$flat  = [char]0x2192
$ndash = [char]0x2013
$mdash = [char]0x2014

function hc($n) {
    if ($n -eq 0)      { return "<td class=""num zero"">$mdash</td>" }
    elseif ($n -lt 10) { return "<td class=""num heat-1"">$n</td>" }
    elseif ($n -lt 20) { return "<td class=""num heat-2"">$n</td>" }
    elseif ($n -lt 30) { return "<td class=""num heat-3"">$n</td>" }
    else               { return "<td class=""num heat-4"">$n</td>" }
}

function trendCell($may, $apr) {
    if ($may -gt $apr)     { return "<td class=""num""><span class=""trend-up"">$up Up</span></td>" }
    elseif ($may -lt $apr) { return "<td class=""num""><span class=""trend-down"">$down Down</span></td>" }
    else                   { return "<td class=""num""><span class=""trend-flat"">$flat Flat</span></td>" }
}

# $jan $feb $mar $apr $may $tot (trend = may vs apr)
function mkrow($name, $jan, $feb, $mar, $apr, $may, $tot) {
    $tc = trendCell $may $apr
    $row  = "        <tr>`n"
    $row += "          <td class=""engineer"">$name</td>`n"
    $row += "          " + (hc $jan) + "`n"
    $row += "          " + (hc $feb) + "`n"
    $row += "          " + (hc $mar) + "`n"
    $row += "          " + (hc $apr) + "`n"
    $row += "          " + (hc $may) + "`n"
    $row += "          <td class=""total"">$tot</td>`n"
    $row += "          $tc`n"
    $row += "          <td class=""num""><span class=""repeat-badge low"">$mdash</span></td>`n"
    $row += "        </tr>"
    return $row
}

Set-Location "c:\Users\rehmaan\Desktop\Claude Projects\REG Rejections"
$html = [System.IO.File]::ReadAllText('index.html', [System.Text.Encoding]::UTF8)

# ── 1. Inject new JS data (CIR-only, Jan-May) ──
$jsRaw = [System.IO.File]::ReadAllText('eng_js_data_v7.txt', [System.Text.Encoding]::UTF8).TrimEnd()
$jsRaw = [regex]::Replace($jsRaw, '"1/22/2026":\s*\[[^\]]*\],?\s*\n', '')
$jsRaw = [regex]::Replace($jsRaw, '"2/10/2026":\s*\[[^\]]*\],?\s*\n', '')
$startPos = $html.IndexOf('const CX_DATA = {')
$isaStart = $html.IndexOf('const ISA_DATA = {', $startPos)
$endPos   = $html.IndexOf('};', $isaStart + 20) + 2
$html = $html.Substring(0, $startPos) + $jsRaw + $html.Substring($endPos)
Write-Host 'JS data injected'

# ── 2. CX colgroup: 4 col-month -> 5 col-month (first occurrence) ──
$oldCols = '<col class="col-month"><col class="col-month"><col class="col-month"><col class="col-month">'
$newCols = '<col class="col-month"><col class="col-month"><col class="col-month"><col class="col-month"><col class="col-month">'
$idx1 = $html.IndexOf($oldCols)
if ($idx1 -ge 0) {
    $html = $html.Substring(0, $idx1) + $newCols + $html.Substring($idx1 + $oldCols.Length)
    Write-Host 'CX colgroup updated'
} else { Write-Host 'WARNING: CX colgroup not found' }
$idx2 = $html.IndexOf($oldCols)
if ($idx2 -ge 0) {
    $html = $html.Substring(0, $idx2) + $newCols + $html.Substring($idx2 + $oldCols.Length)
    Write-Host 'ISA colgroup updated'
} else { Write-Host 'WARNING: ISA colgroup not found' }

# ── 3. Column headers Feb-May -> Jan-May (replace both tables) ──
$oldHead = "<th class=""num"">Feb</th>`n          <th class=""num"">Mar</th>`n          <th class=""num"">Apr</th>`n          <th class=""num"">May</th>"
$newHead = "<th class=""num"">Jan</th>`n          <th class=""num"">Feb</th>`n          <th class=""num"">Mar</th>`n          <th class=""num"">Apr</th>`n          <th class=""num"">May</th>"
$html = $html.Replace($oldHead, $newHead)
Write-Host 'Column headers updated'

# ── 4. CX tbody ──
$cxRows = @(
    @('Raja Magunta',           7,  4, 25, 39, 14,  89),
    @('Tamara Gil',             0, 24,  8, 29,  8,  69),
    @('Allison Schmidt',        0, 11, 16, 11, 12,  50),
    @('Ashutosh Pandey',        8,  6, 24,  0,  0,  38),
    @('Shennay Hampton - TEK',  0,  2,  7, 15, 12,  36),
    @('Asad Kamran',            6,  3,  5,  8,  1,  23),
    @('Yousuf Moiz',           10,  5,  4,  2,  0,  21),
    @('Belem Rios',             6,  0,  2,  8,  5,  21),
    @('Roma Patel',             4,  5,  4,  2,  0,  15),
    @('Victor Durosomo',        5,  3,  4,  1,  0,  13),
    @('Priyatham Tamma',        4,  7,  0,  0,  0,  11),
    @('Maninderjit Hari',       0,  3,  0,  2,  2,   7),
    @('Kelly Quate',            2,  0,  2,  0,  2,   6),
    @('Mazhar Shahzad',         0,  0,  0,  1,  2,   3),
    @('Muhammad Siddiki',       0,  1,  0,  0,  0,   1)
)

$cxBody = ""
foreach ($d in $cxRows) { $cxBody += (mkrow $d[0] $d[1] $d[2] $d[3] $d[4] $d[5] $d[6]) + "`n" }
$cxBody += "        <tr class=""grand-total-row"">`n"
$cxBody += "          <td>Grand Total</td>`n"
$cxBody += "          <td class=""num"">52</td>`n"
$cxBody += "          <td class=""num"">74</td>`n"
$cxBody += "          <td class=""num"">101</td>`n"
$cxBody += "          <td class=""num"">118</td>`n"
$cxBody += "          <td class=""num"">58</td>`n"
$cxBody += "          <td class=""total"">403</td>`n"
$cxBody += "          <td class=""num""><span class=""trend-down"">$down Down</span></td>`n"
$cxBody += "          <td class=""num"">$mdash repeat projects</td>`n"
$cxBody += "        </tr>`n"

$cxStart    = $html.IndexOf('<span class="badge cx">')
$tbodyStart = $html.IndexOf('<tbody>', $cxStart) + 7
$tbodyEnd   = $html.IndexOf('</tbody>', $cxStart)
$html = $html.Substring(0, $tbodyStart) + "`n" + $cxBody + "      " + $html.Substring($tbodyEnd)
Write-Host 'CX tbody replaced'

# ── 5. ISA tbody ──
$isaRows = @(
    @('Belem Rios',             5,  7,  5,  3,  6,  26),
    @('Mazhar Shahzad',        12,  4,  3,  0,  1,  20),
    @('Victor Durosomo',        3,  9,  2,  3,  0,  17),
    @('Yousuf Moiz',            5,  7,  0,  1,  2,  15),
    @('Asad Kamran',            6,  6,  1,  0,  0,  13),
    @('Roma Patel',             5,  6,  0,  0,  1,  12),
    @('Allison Schmidt',        0,  0,  1,  7,  3,  11),
    @('Tamara Gil',             0,  0,  0,  5,  3,   8),
    @('Shennay Hampton - TEK',  0,  0,  0,  5,  2,   7),
    @('Priyatham Tamma',        0,  5,  0,  0,  0,   5),
    @('Raja Magunta',           0,  0,  0,  0,  2,   2),
    @('Maninderjit Hari',       0,  2,  0,  0,  0,   2),
    @('Kelly Quate',            1,  0,  0,  0,  0,   1)
)

$isaBody = ""
foreach ($d in $isaRows) { $isaBody += (mkrow $d[0] $d[1] $d[2] $d[3] $d[4] $d[5] $d[6]) + "`n" }
$isaBody += "        <tr class=""grand-total-row"">`n"
$isaBody += "          <td>Grand Total</td>`n"
$isaBody += "          <td class=""num"">37</td>`n"
$isaBody += "          <td class=""num"">46</td>`n"
$isaBody += "          <td class=""num"">12</td>`n"
$isaBody += "          <td class=""num"">24</td>`n"
$isaBody += "          <td class=""num"">20</td>`n"
$isaBody += "          <td class=""total"">139</td>`n"
$isaBody += "          <td class=""num""><span class=""trend-down"">$down Down</span></td>`n"
$isaBody += "          <td class=""num"">$mdash repeat projects</td>`n"
$isaBody += "        </tr>`n"

$isaStart2     = $html.IndexOf('<span class="badge isa">')
$isaTbodyStart = $html.IndexOf('<tbody>', $isaStart2) + 7
$isaTbodyEnd   = $html.IndexOf('</tbody>', $isaStart2)
$html = $html.Substring(0, $isaTbodyStart) + "`n" + $isaBody + "      " + $html.Substring($isaTbodyEnd)
Write-Host 'ISA tbody replaced'

# ── 6. Source line ──
$html = [regex]::Replace($html,
    'Source: May SERegulatoryTrackerALLPROJECTS[^<]*',
    "Source: May SERegulatoryTrackerALLPROJECTS &nbsp;|&nbsp; May Total Rejection by Month &nbsp;|&nbsp; Jan $ndash May 2026 &nbsp;|&nbsp; 542 total rejections (CX: 403, ISA: 139)")
Write-Host 'Source line updated'

# ── 7. CX callouts ──
$cxCalloutStart = $html.IndexOf('<ul class="callout-list">', $html.IndexOf('<span class="badge cx">')) + 24
$cxCalloutEnd   = $html.IndexOf('</ul>', $cxCalloutStart)
$newCxCl  = "`n"
$newCxCl += "        <li><strong>Raja Magunta</strong> $ndash 89 CIR rejections (Jan$ndash May); peaked at 39 in April; highest volume</li>`n"
$newCxCl += "        <li><strong>Tamara Gil</strong> $ndash 69 CIR rejections; 24 in Jan, 29 in April</li>`n"
$newCxCl += "        <li><strong>Allison Schmidt</strong> $ndash 50 rejections; trending up in May (12); consistent across all months</li>`n"
$newCxCl += "        <li><strong>Shennay Hampton $ndash TEK</strong> $ndash escalating: 0$ndash2$ndash7$ndash15$ndash12; peaked in April</li>`n"
$newCxCl += "        <li><strong>Ashutosh Pandey</strong> $ndash 38 total; front-loaded Jan$ndash Mar; dropped to 0 Apr$ndash May; likely resolved or reassigned</li>`n"
$newCxCl += "`n"
$html = $html.Substring(0, $cxCalloutStart) + $newCxCl + $html.Substring($cxCalloutEnd)
Write-Host 'CX callouts updated'

# ── 8. ISA callouts ──
$isaCalloutStart = $html.IndexOf('<ul class="callout-list">', $html.IndexOf('<span class="badge isa">')) + 24
$isaCalloutEnd   = $html.IndexOf('</ul>', $isaCalloutStart)
$newIsaCl  = "`n"
$newIsaCl += "        <li><strong>Belem Rios</strong> $ndash 26 ISA rejections (Jan$ndash May); highest volume; steady throughout</li>`n"
$newIsaCl += "        <li><strong>Mazhar Shahzad</strong> $ndash 20; front-loaded Jan (12), tapering after</li>`n"
$newIsaCl += "        <li><strong>Victor Durosomo</strong> $ndash 17 total; front-loaded Feb (9), dropped to 0 in May</li>`n"
$newIsaCl += "        <li><strong>Allison Schmidt</strong> $ndash escalating ISA: 0$ndash0$ndash1$ndash7$ndash3; 11 ISA on top of 50 CIR</li>`n"
$newIsaCl += "        <li><strong>Volume spread</strong> $ndash Jan=37, Feb=46, Mar=12, Apr=24, May=20; Mar sharp dip then recovering</li>`n"
$newIsaCl += "`n"
$html = $html.Substring(0, $isaCalloutStart) + $newIsaCl + $html.Substring($isaCalloutEnd)
Write-Host 'ISA callouts updated'

# ── 9. Write ──
[System.IO.File]::WriteAllText('index.html', $html, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText('rejection_summary.html', $html, [System.Text.Encoding]::UTF8)
Write-Host 'Done.'
