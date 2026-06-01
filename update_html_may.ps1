Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
$up   = [char]0x2191  # up arrow
$down = [char]0x2193  # down arrow
$flat = [char]0x2192  # right arrow
$nbsp = [char]0x00A0  # non-breaking space (HTML entity &nbsp; as char)
$ndash = [char]0x2013 # en dash

function hc($n) {
    if ($n -eq 0)       { return '<td class="num zero">--</td>' }
    elseif ($n -lt 10)  { return "<td class=""num heat-1"">$n</td>" }
    elseif ($n -lt 20)  { return "<td class=""num heat-2"">$n</td>" }
    elseif ($n -lt 30)  { return "<td class=""num heat-3"">$n</td>" }
    else                { return "<td class=""num heat-4"">$n</td>" }
}

function trendCell($last, $prev) {
    if ($last -gt $prev)   { return "<td class=""num""><span class=""trend-up"">$up Up</span></td>" }
    elseif ($last -lt $prev) { return "<td class=""num""><span class=""trend-down"">$down Down</span></td>" }
    else                   { return "<td class=""num""><span class=""trend-flat"">$flat Flat</span></td>" }
}

function rep($n) {
    if ($n -eq 0) { return '<td class="num"><span class="repeat-badge low">--</span></td>' }
    elseif ($n -eq 1) { return "<td class=""num""><span class=""repeat-badge"">1 project</span></td>" }
    else              { return "<td class=""num""><span class=""repeat-badge"">$n projects</span></td>" }
}

function mkrow($name, $f, $m, $a, $may, $tot, $reps) {
    $tc = trendCell $may $a
    $row  = "        <tr>`n"
    $row += "          <td class=""engineer"">$name</td>`n"
    $row += "          " + (hc $f)   + "`n"
    $row += "          " + (hc $m)   + "`n"
    $row += "          " + (hc $a)   + "`n"
    $row += "          " + (hc $may) + "`n"
    $row += "          <td class=""total"">$tot</td>`n"
    $row += "          $tc`n"
    $row += "          " + (rep $reps) + "`n"
    $row += "        </tr>"
    return $row
}

Set-Location "c:\Users\rehmaan\Desktop\Claude Projects\REG Rejections"
$html = [System.IO.File]::ReadAllText('rejection_summary.html', [System.Text.Encoding]::UTF8)

# 1. Inject new JS data (clean up spurious 2/10/2026 ISA entry)
$jsRaw = [System.IO.File]::ReadAllText('eng_js_data_v7.txt', [System.Text.Encoding]::UTF8).TrimEnd()
$jsRaw = [regex]::Replace($jsRaw, '"2/10/2026":\s*\[[^\]]*\],?\s*\n', '')
$startPos = $html.IndexOf('const CX_DATA = {')
$isaStart = $html.IndexOf('const ISA_DATA = {', $startPos)
$endPos   = $html.IndexOf('};', $isaStart + 20) + 2
$html = $html.Substring(0, $startPos) + $jsRaw + $html.Substring($endPos)
Write-Host 'JS data injected'

# 2. Title
$html = $html.Replace('Atlantic South Regulatory Rejections Summary ' + $ndash + ' April 2026',
                      'Atlantic South Regulatory Rejections Summary ' + $ndash + ' May 2026')
# Also try without ndash in case it was typed as em-dash or simple dash
$html = $html.Replace('Summary &mdash; April 2026', 'Summary &mdash; May 2026')
$html = $html.Replace('Summary - April 2026',       'Summary - May 2026')
Write-Host 'Title updated'

# 3. Source line
$oldSrc = 'Source: April SERegulatoryTrackerALLPROJECTS &nbsp;|&nbsp; April NEW Total Rejection by Month &nbsp;|&nbsp; Jan ' + $ndash + ' Apr 2026 &nbsp;|&nbsp; 958 total rejections ' + [char]0x00B7 + ' 210 repeat projects'
$newSrc = 'Source: May SERegulatoryTrackerALLPROJECTS &nbsp;|&nbsp; May Total Rejection by Month &nbsp;|&nbsp; Feb ' + $ndash + ' May 2026 &nbsp;|&nbsp; 477 total rejections (CX: 361, ISA: 116)'
$html = $html.Replace($oldSrc, $newSrc)
Write-Host 'Source line updated'

# 4. Add month-may CSS
$html = $html.Replace('.month-apr { background: #fce7f3; color: #9d174d; }',
    '.month-apr { background: #fce7f3; color: #9d174d; }' + "`n    " + '.month-may { background: #ffedd5; color: #9a3412; }')
Write-Host 'CSS month-may added'

# 5. Update JS month class maps
$oldMC1 = "const monthClass = {January:'month-jan',February:'month-feb',March:'month-mar',April:'month-apr'};"
$newMC1 = "const monthClass = {January:'month-jan',February:'month-feb',March:'month-mar',April:'month-apr',May:'month-may'};"
$html = $html.Replace($oldMC1, $newMC1)

$oldMC2 = "const mClass = {January:'month-jan',February:'month-feb',March:'month-mar',April:'month-apr'};"
$newMC2 = "const mClass = {January:'month-jan',February:'month-feb',March:'month-mar',April:'month-apr',May:'month-may'};"
$html = $html.Replace($oldMC2, $newMC2)
Write-Host 'JS month classes updated'

# 6. CX column headers: Jan->Feb, Apr->May
$html = $html.Replace(
    "<th class=""num"">Jan</th>`n          <th class=""num"">Feb</th>`n          <th class=""num"">Mar</th>`n          <th class=""num"">Apr</th>",
    "<th class=""num"">Feb</th>`n          <th class=""num"">Mar</th>`n          <th class=""num"">Apr</th>`n          <th class=""num"">May</th>")
Write-Host 'Column headers updated'

# 7. Build CX rows
$cxRows = @(
    @('Raja Magunta',          6, 25, 39, 14, 84, 25),
    @('Tamara Gil',           24,  8, 29,  8, 69, 23),
    @('Allison Schmidt',      11, 16, 11, 13, 51, 21),
    @('Shennay Hampton - TEK', 2,  7, 15, 12, 36, 10),
    @('Ashutosh Pandey',       6, 24,  0,  0, 30,  6),
    @('Asad Kamran',           3,  5,  8,  1, 17,  5),
    @('Belem Rios',            0,  2,  8,  5, 15,  4),
    @('Yousuf Moiz',           8,  4,  2,  0, 14,  4),
    @('Roma Patel',            5,  4,  2,  0, 11,  3),
    @('Victor Durosomo',       3,  4,  1,  1,  9,  3),
    @('Maninderjit Hari',      3,  0,  3,  2,  8,  2),
    @('Priyatham Tamma',       7,  0,  0,  0,  7,  3),
    @('Kelly Quate',           0,  2,  2,  2,  6,  2),
    @('Mazhar Shahzad',        0,  0,  1,  2,  3,  1),
    @('Muhammad Siddiki',      1,  0,  0,  0,  1,  0)
)

$cxBody = ""
foreach ($d in $cxRows) { $cxBody += (mkrow $d[0] $d[1] $d[2] $d[3] $d[4] $d[5] $d[6]) + "`n" }
$cxBody += @"
        <tr class="grand-total-row">
          <td>Grand Total</td>
          <td class="num">79</td>
          <td class="num">101</td>
          <td class="num">121</td>
          <td class="num">60</td>
          <td class="total">361</td>
          <td class="num"><span class="trend-down">$down Down</span></td>
          <td class="num">84 repeat projects</td>
        </tr>
"@

# Replace CX tbody
$cxStart = $html.IndexOf('<span class="badge cx">')
$tbodyStart = $html.IndexOf('<tbody>', $cxStart) + 7
$tbodyEnd   = $html.IndexOf('</tbody>', $cxStart)
$html = $html.Substring(0, $tbodyStart) + "`n" + $cxBody + "      " + $html.Substring($tbodyEnd)
Write-Host 'CX tbody replaced'

# 8. CX Callouts
$cxCalloutStart = $html.IndexOf('<ul class="callout-list">', $html.IndexOf('<span class="badge cx">')) + 24
$cxCalloutEnd   = $html.IndexOf('</ul>', $cxCalloutStart)
$newCxCl = @"

        <li><strong>Raja Magunta</strong> $ndash 84 CIR rejections (Feb$ndash May); spiked to 39 in April; 25 repeat projects $ndash highest volume</li>
        <li><strong>Tamara Gil</strong> $ndash 69 CIR rejections; 29 in April and 24 in February; 23 repeat projects</li>
        <li><strong>Allison Schmidt</strong> $ndash 51 rejections; steady 11$ndash16/month all four months; 21 repeat projects</li>
        <li><strong>Shennay Hampton - TEK</strong> $ndash escalating: 2$ndash7$ndash15$ndash12; 10 repeat projects</li>
        <li><strong>Ashutosh Pandey</strong> $ndash 30 total but dropped to 0 in Apr$ndash May; likely resolved or reassigned</li>

"@
$html = $html.Substring(0, $cxCalloutStart) + $newCxCl + $html.Substring($cxCalloutEnd)
Write-Host 'CX callouts updated'

# 9. ISA rows
$isaRows = @(
    @('Asad Kamran',          6,  3,  4,  8, 21,  2),
    @('Belem Rios',           7,  5,  3,  6, 21,  5),
    @('Victor Durosomo',      9,  2,  3,  0, 14,  2),
    @('Allison Schmidt',      0,  1,  7,  3, 11,  2),
    @('Yousuf Moiz',          7,  0,  1,  2, 10,  1),
    @('Tamara Gil',           0,  0,  5,  3,  8,  2),
    @('Mazhar Shahzad',       4,  3,  0,  1,  8,  1),
    @('Roma Patel',           6,  0,  0,  1,  7,  0),
    @('Shennay Hampton - TEK', 0, 0,  5,  2,  7,  1),
    @('Priyatham Tamma',      5,  0,  0,  0,  5,  1),
    @('Maninderjit Hari',     2,  0,  0,  0,  2,  0),
    @('Raja Magunta',         0,  0,  0,  2,  2,  0)
)

$isaBody = ""
foreach ($d in $isaRows) { $isaBody += (mkrow $d[0] $d[1] $d[2] $d[3] $d[4] $d[5] $d[6]) + "`n" }
$isaBody += @"
        <tr class="grand-total-row">
          <td>Grand Total</td>
          <td class="num">46</td>
          <td class="num">14</td>
          <td class="num">28</td>
          <td class="num">28</td>
          <td class="total">116</td>
          <td class="num"><span class="trend-flat">$flat Flat</span></td>
          <td class="num">15 repeat projects</td>
        </tr>
"@

$isaStart2 = $html.IndexOf('<span class="badge isa">')
$isaTbodyStart = $html.IndexOf('<tbody>', $isaStart2) + 7
$isaTbodyEnd   = $html.IndexOf('</tbody>', $isaStart2)
$html = $html.Substring(0, $isaTbodyStart) + "`n" + $isaBody + "      " + $html.Substring($isaTbodyEnd)
Write-Host 'ISA tbody replaced'

# 10. ISA Callouts
$isaCalloutStart = $html.IndexOf('<ul class="callout-list">', $html.IndexOf('<span class="badge isa">')) + 24
$isaCalloutEnd   = $html.IndexOf('</ul>', $isaCalloutStart)
$newIsaCl = @"

        <li><strong>Asad Kamran + Belem Rios</strong> $ndash tied at 21 each; Asad trending up (May=8); Belem steady throughout</li>
        <li><strong>Victor Durosomo</strong> $ndash 14 total; front-loaded Feb (9), tapering to 0 in May</li>
        <li><strong>Allison Schmidt</strong> $ndash escalating ISA: 0$ndash1$ndash7$ndash3; 11 ISA on top of 51 CIR</li>
        <li><strong>Volume spread</strong> $ndash Feb=46, Mar=14, Apr=28, May=28; more even distribution than prior periods</li>

"@
$html = $html.Substring(0, $isaCalloutStart) + $newIsaCl + $html.Substring($isaCalloutEnd)
Write-Host 'ISA callouts updated'

# 11. Write
[System.IO.File]::WriteAllText('rejection_summary.html', $html, [System.Text.Encoding]::UTF8)
Write-Host 'Done. rejection_summary.html written.'
