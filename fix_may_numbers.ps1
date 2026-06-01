Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$up    = [char]0x2191
$down  = [char]0x2193
$flat  = [char]0x2192
$ndash = [char]0x2013

function hc($n) {
    if ($n -eq 0)      { return '<td class="num zero">—</td>' }
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

function rep($n) {
    if ($n -eq 0) { return '<td class="num"><span class="repeat-badge low">—</span></td>' }
    elseif ($n -eq 1) { return "<td class=""num""><span class=""repeat-badge"">1 project</span></td>" }
    else              { return "<td class=""num""><span class=""repeat-badge"">$n projects</span></td>" }
}

function mkrow($name, $feb, $mar, $apr, $may, $tot, $reps) {
    $tc = trendCell $may $apr
    $row  = "        <tr>`n"
    $row += "          <td class=""engineer"">$name</td>`n"
    $row += "          " + (hc $feb) + "`n"
    $row += "          " + (hc $mar) + "`n"
    $row += "          " + (hc $apr) + "`n"
    $row += "          " + (hc $may) + "`n"
    $row += "          <td class=""total"">$tot</td>`n"
    $row += "          $tc`n"
    $row += "          " + (rep $reps) + "`n"
    $row += "        </tr>"
    return $row
}

Set-Location "c:\Users\rehmaan\Desktop\Claude Projects\REG Rejections"
$html = [System.IO.File]::ReadAllText('rejection_summary.html', [System.Text.Encoding]::UTF8)

# ── CX rows ──
# Feb/Mar/Apr frozen from April report; May from new CSV; Reps from May CSV
$cxRows = @(
    @('Raja Magunta',           3,  9, 21, 14, 47, 25),
    @('Tamara Gil',            13,  8, 15,  8, 44, 24),
    @('Allison Schmidt',        5,  9,  8, 13, 35, 22),
    @('Shennay Hampton - TEK',  2,  7,  6, 12, 27, 10),
    @('Ashutosh Pandey',        4, 20,  1,  0, 25,  6),
    @('Asad Kamran',            2,  3,  3,  1,  9,  5),
    @('Maninderjit Hari',       3,  1,  3,  2,  9,  2),
    @('Mazhar Shahzad',         2,  0,  5,  2,  9,  2),
    @('Belem Rios',             0,  1,  2,  5,  8,  5),
    @('Roma Patel',             2,  4,  2,  0,  8,  3),
    @('Yousuf Moiz',            2,  4,  1,  1,  8,  5),
    @('Kelly Quate',            0,  2,  2,  2,  6,  2),
    @('Priyatham Tamma',        5,  0,  0,  0,  5,  3),
    @('Victor Durosomo',        0,  2,  1,  1,  4,  3),
    @('Muhammad Siddiki',       1,  0,  0,  0,  1,  0)
)

$cxBody = ""
foreach ($d in $cxRows) { $cxBody += (mkrow $d[0] $d[1] $d[2] $d[3] $d[4] $d[5] $d[6]) + "`n" }
$cxBody += @"
        <tr class="grand-total-row">
          <td>Grand Total</td>
          <td class="num">44</td>
          <td class="num">70</td>
          <td class="num">70</td>
          <td class="num">61</td>
          <td class="total">245</td>
          <td class="num"><span class="trend-down">$down Down</span></td>
          <td class="num">117 repeat projects</td>
        </tr>
"@

$cxStart     = $html.IndexOf('<span class="badge cx">')
$tbodyStart  = $html.IndexOf('<tbody>', $cxStart) + 7
$tbodyEnd    = $html.IndexOf('</tbody>', $cxStart)
$html = $html.Substring(0, $tbodyStart) + "`n" + $cxBody + "      " + $html.Substring($tbodyEnd)
Write-Host 'CX tbody replaced'

# ── ISA rows ──
# Feb/Mar/Apr: frozen from April for engineers who were in April ISA;
# new engineers (Asad Kamran, Belem Rios, Victor Durosomo, Mazhar Shahzad, Raja Magunta) use May CSV
$isaRows = @(
    @('Asad Kamran',            6,  3,  4,  8, 21,  2),
    @('Belem Rios',             7,  5,  3,  6, 21,  5),
    @('Victor Durosomo',        9,  2,  3,  0, 14,  2),
    @('Allison Schmidt',        0,  3,  5,  3, 11,  2),
    @('Mazhar Shahzad',         5,  3,  0,  1,  9,  1),
    @('Yousuf Moiz',            5,  0,  0,  2,  7,  1),
    @('Roma Patel',             5,  0,  0,  1,  6,  0),
    @('Shennay Hampton - TEK',  0,  0,  4,  2,  6,  1),
    @('Tamara Gil',             0,  0,  2,  3,  5,  2),
    @('Priyatham Tamma',        4,  0,  0,  0,  4,  1),
    @('Raja Magunta',           0,  0,  0,  2,  2,  0),
    @('Maninderjit Hari',       1,  0,  0,  0,  1,  0)
)

$isaBody = ""
foreach ($d in $isaRows) { $isaBody += (mkrow $d[0] $d[1] $d[2] $d[3] $d[4] $d[5] $d[6]) + "`n" }
$isaBody += @"
        <tr class="grand-total-row">
          <td>Grand Total</td>
          <td class="num">42</td>
          <td class="num">16</td>
          <td class="num">21</td>
          <td class="num">28</td>
          <td class="total">107</td>
          <td class="num"><span class="trend-up">$up Up</span></td>
          <td class="num">17 repeat projects</td>
        </tr>
"@

$isaStart2     = $html.IndexOf('<span class="badge isa">')
$isaTbodyStart = $html.IndexOf('<tbody>', $isaStart2) + 7
$isaTbodyEnd   = $html.IndexOf('</tbody>', $isaStart2)
$html = $html.Substring(0, $isaTbodyStart) + "`n" + $isaBody + "      " + $html.Substring($isaTbodyEnd)
Write-Host 'ISA tbody replaced'

# ── Source line ──
$oldSrc = 'Source: May SERegulatoryTrackerALLPROJECTS &nbsp;|&nbsp; May Total Rejection by Month &nbsp;|&nbsp; Feb ' + $ndash + ' May 2026 &nbsp;|&nbsp; 477 total rejections (CX: 361, ISA: 116)'
$newSrc = 'Source: May SERegulatoryTrackerALLPROJECTS &nbsp;|&nbsp; May Total Rejection by Month &nbsp;|&nbsp; Feb ' + $ndash + ' May 2026 &nbsp;|&nbsp; 352 total rejections (CX: 245, ISA: 107)'
$html = $html.Replace($oldSrc, $newSrc)
Write-Host 'Source line updated'

# ── CX callouts ──
$cxCalloutStart = $html.IndexOf('<ul class="callout-list">', $html.IndexOf('<span class="badge cx">')) + 24
$cxCalloutEnd   = $html.IndexOf('</ul>', $cxCalloutStart)
$newCxCl = @"

        <li><strong>Raja Magunta</strong> $ndash 47 CIR rejections (Feb$ndash May); peaked at 21 in April; 25 repeat projects $ndash highest volume</li>
        <li><strong>Tamara Gil</strong> $ndash 44 CIR rejections; 13 in Feb, 15 in April; 24 repeat projects</li>
        <li><strong>Allison Schmidt</strong> $ndash 35 rejections; escalating in May (13); 22 repeat projects</li>
        <li><strong>Shennay Hampton - TEK</strong> $ndash escalating: 2$ndash7$ndash6$ndash12; 10 repeat projects</li>
        <li><strong>Ashutosh Pandey</strong> $ndash 25 total; dropped to 0 in Apr$ndash May; likely resolved or reassigned</li>

"@
$html = $html.Substring(0, $cxCalloutStart) + $newCxCl + $html.Substring($cxCalloutEnd)
Write-Host 'CX callouts updated'

# ── ISA callouts ──
$isaCalloutStart = $html.IndexOf('<ul class="callout-list">', $html.IndexOf('<span class="badge isa">')) + 24
$isaCalloutEnd   = $html.IndexOf('</ul>', $isaCalloutStart)
$newIsaCl = @"

        <li><strong>Asad Kamran + Belem Rios</strong> $ndash tied at 21 each; Asad trending up (May=8); Belem steady throughout</li>
        <li><strong>Victor Durosomo</strong> $ndash 14 total; front-loaded Feb (9), dropped to 0 in May</li>
        <li><strong>Allison Schmidt</strong> $ndash escalating ISA: 0$ndash3$ndash5$ndash3; 11 ISA on top of 35 CIR</li>
        <li><strong>Volume spread</strong> $ndash Feb=42, Mar=16, Apr=21, May=28; May rebounding after March dip</li>

"@
$html = $html.Substring(0, $isaCalloutStart) + $newIsaCl + $html.Substring($isaCalloutEnd)
Write-Host 'ISA callouts updated'

[System.IO.File]::WriteAllText('rejection_summary.html', $html, [System.Text.Encoding]::UTF8)
Write-Host 'Done.'
