#!/usr/bin/perl
use strict;
use warnings;

# ---------------------------------------------------------------------------
# Fast single-line CSV parser (for tracker - no multiline fields)
# ---------------------------------------------------------------------------
sub parse_simple_line {
    my ($line) = @_;
    $line =~ s/\r?\n$//;
    my @fields;
    while (length($line) > 0) {
        if (substr($line, 0, 1) eq '"') {
            # Quoted field
            my $end = 1;
            my $len = length($line);
            my $field = '';
            while ($end < $len) {
                my $ch = substr($line, $end, 1);
                if ($ch eq '"') {
                    if ($end + 1 < $len && substr($line, $end+1, 1) eq '"') {
                        $field .= '"'; $end += 2;
                    } else {
                        $end++; last;
                    }
                } else {
                    $field .= $ch; $end++;
                }
            }
            push @fields, $field;
            $line = substr($line, $end);
            $line =~ s/^,//;
        } else {
            if ($line =~ s/^([^,]*),?//) {
                push @fields, $1;
            } else {
                push @fields, $line; last;
            }
        }
    }
    return @fields;
}

# ---------------------------------------------------------------------------
# Multi-line RFC4180 CSV parser (line-by-line, tracks quote parity)
# Fast: avoids slurping large files into memory for char-by-char scan
# ---------------------------------------------------------------------------
sub read_multiline_csv {
    my ($filename) = @_;
    open(my $fh, "<:encoding(UTF-8)", $filename) or die "Cannot open $filename: $!";

    my @headers;
    my @rows;
    my $buffer = '';
    my $open_quotes = 0;
    my $first = 1;

    while (my $line = <$fh>) {
        $line =~ s/\r?\n$//;
        # Strip BOM from first line
        if ($first) { $line =~ s/^\x{FEFF}//; $first = 0; }

        $buffer = length($buffer) ? ($buffer . "\n" . $line) : $line;

        # Count unescaped quotes to determine if record is complete
        my $q = $line;
        $q =~ s/""/\x00/g;   # neutralize escaped quotes
        $open_quotes += ($q =~ tr/"//);

        if ($open_quotes % 2 == 0) {
            if (!@headers) {
                @headers = parse_simple_line($buffer);
            } else {
                push @rows, [parse_simple_line($buffer)];
            }
            $buffer = '';
            $open_quotes = 0;
        }
    }
    close $fh;
    if (length($buffer)) {
        push @rows, [parse_simple_line($buffer)];
    }

    return (\@headers, \@rows);
}

# ---------------------------------------------------------------------------
# JS string escaping
# ---------------------------------------------------------------------------
sub js_escape {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\r?\n/ /g;
    $s =~ s/\r/ /g;
    $s =~ s/  +/ /g;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

# ---------------------------------------------------------------------------
# Date parsing for sorting: M/D/YYYY -> sortable YYYYMMDD
# ---------------------------------------------------------------------------
sub date_sort_key {
    my ($dt) = @_;
    if ($dt =~ m{^(\d+)/(\d+)/(\d+)$}) {
        return sprintf("%04d%02d%02d", $3, $1, $2);
    }
    return "00000000";
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
my $BASE = "C:/Users/rehmaan/Desktop/Claude Projects/REG Rejections";

# ---------------------------------------------------------------------------
# Step 1: Load tracker using fast line-by-line parse
# ---------------------------------------------------------------------------
print STDERR "Loading tracker CSV...\n";
open(my $tfh, "<:raw:encoding(latin1)", "$BASE/May SERegulatoryTrackerALLPROJECTS1776971657342.csv")
    or die "Cannot open tracker: $!";

my $thead = <$tfh>;
$thead =~ s/^\x{FEFF}//;
my @tcols = parse_simple_line($thead);

my ($fuze_idx, $cx_idx, $isa_idx) = (-1, -1, -1);
for my $i (0..$#tcols) {
    $fuze_idx = $i if $tcols[$i] eq "FUZE Project ID";
    $cx_idx   = $i if $tcols[$i] eq "REG ENG CX";
    $isa_idx  = $i if $tcols[$i] eq "REG ENG ISA";
}
die "fuze_idx=$fuze_idx cx_idx=$cx_idx isa_idx=$isa_idx - column not found" if $fuze_idx < 0 || $cx_idx < 0 || $isa_idx < 0;
print STDERR "  fuze=$fuze_idx cx=$cx_idx isa=$isa_idx\n";

my $max_col = $isa_idx > $cx_idx ? $isa_idx : $cx_idx;
$max_col = $fuze_idx if $fuze_idx > $max_col;

my %tracker;
my $trow_cnt = 0;
while (my $line = <$tfh>) {
    $line =~ s/\r?\n$//;
    my @f = split /,/, $line, $max_col + 2;
    my $pid = $f[$fuze_idx] // "";
    $pid =~ s/^\s+|\s+$//g;
    next unless $pid;
    my $cx  = $f[$cx_idx]  // ""; $cx  =~ s/^\s+|\s+$//g;
    my $isa = $f[$isa_idx] // ""; $isa =~ s/^\s+|\s+$//g;
    $tracker{$pid} = {cx => $cx, isa => $isa};
    $trow_cnt++;
}
close $tfh;
print STDERR "  Tracker rows: $trow_cnt, unique projects: " . scalar(keys %tracker) . "\n";

# ---------------------------------------------------------------------------
# Step 2: Load rejection CSV with multi-line aware parser
# ---------------------------------------------------------------------------
print STDERR "Loading rejection CSV (multi-line)...\n";
my ($rcols, $rrows) = read_multiline_csv("$BASE/May Total Rejection by month Tabular_Full Data_data.csv");

my ($r_pid, $r_month, $r_dt, $r_ws, $r_comment, $r_reason) = (-1) x 6;
for my $i (0..$#$rcols) {
    $r_pid     = $i if $rcols->[$i] eq "Site Projects ID";
    $r_month   = $i if $rcols->[$i] eq "Month ";
    $r_dt      = $i if $rcols->[$i] eq "Date Rejected";
    $r_ws      = $i if $rcols->[$i] eq "Workstep Name";
    $r_comment = $i if $rcols->[$i] eq "Comment Text";
    $r_reason  = $i if $rcols->[$i] eq "Reject Reason";
}
print STDERR "  pid=$r_pid month=$r_month dt=$r_dt ws=$r_ws comment=$r_comment reason=$r_reason\n";
print STDERR "  Total rejection records: " . scalar(@$rrows) . "\n";

# Show some sample workstep values
my %ws_sample;
for my $row (@$rrows) {
    my $ws = $row->[$r_ws] // "";
    $ws =~ s/^\s+|\s+$//g;
    $ws_sample{$ws}++ if $ws;
}
print STDERR "  Workstep values:\n";
for my $ws (sort keys %ws_sample) {
    print STDERR "    $ws_sample{$ws}x [$ws]\n";
}

# ---------------------------------------------------------------------------
# Step 3: Process
# ---------------------------------------------------------------------------
my %known_cx = map { $_ => 1 } (
    "Tamara Gil", "Raja Magunta", "Ashutosh Pandey", "Asad Kamran",
    "Allison Schmidt", "Yousuf Moiz", "Roma Patel", "Belem Rios",
    "Shennay Hampton - TEK", "Shennay Hampton", "Priyatham Tamma", "Victor Durosomo",
    "Mazhar Shahzad", "Muhammad Siddiki", "Maninderjit Hari",
    "Kelly Quate", "Leona McDaniel", "Donya Shea", "Judy Middleton",
    "Muhammad Aamir", "Anees Rehman", "Jamison Tyler", "Grace Garcia",
    "Erica Johnson", "Meredith Gray", "Kayla Terry",
    "Srinivasan Annamalai", "Keisha Williams"
);

my %cx_ws_set  = ("CONSTRUCTION_INITIAL_REVIEW" => 1);
my %isa_ws_set = ("CALL_SIGN" => 1);

my %keep_months = map { $_ => 1 } ("January", "February", "March", "April", "May");

my %CX_DATA;
my %ISA_DATA;
my ($cnt_matched, $cnt_skip_ws, $cnt_skip_tracker, $cnt_skip_cx_eng, $cnt_skip_month) = (0, 0, 0, 0, 0);

for my $row (@$rrows) {
    my $ws = $row->[$r_ws] // "";
    $ws =~ s/^\s+|\s+$//g;

    unless ($cx_ws_set{$ws} || $isa_ws_set{$ws}) {
        $cnt_skip_ws++;
        next;
    }

    my $month_raw = $row->[$r_month] // "";
    $month_raw =~ s/^\s+|\s+$//g;
    unless ($keep_months{$month_raw}) {
        $cnt_skip_month++;
        next;
    }

    my $pid = $row->[$r_pid] // "";
    $pid =~ s/^\s+|\s+$//g;

    unless (exists $tracker{$pid}) {
        $cnt_skip_tracker++;
        next;
    }

    $cnt_matched++;

    my $month   = $row->[$r_month]   // ""; $month   =~ s/^\s+|\s+$//g;
    my $dt      = $row->[$r_dt]      // ""; $dt      =~ s/^\s+|\s+$//g;
    my $comment = $row->[$r_comment] // ""; $comment =~ s/^\s+|\s+$//g;
    my $reason  = $row->[$r_reason]  // ""; $reason  =~ s/^\s+|\s+$//g;

    # Strip date-time portion
    $dt =~ s/\s+\d+:\d+.*$//;

    # Strip "REJECTED REASON : " prefix
    $comment =~ s/^REJECTED REASON\s*:\s*//;

    # Use comment if non-empty, else reason
    my $c = (length($comment) > 0) ? $comment : $reason;

    # Workstep abbreviation
    my $ws_abbr = ($ws eq "CONSTRUCTION_INITIAL_REVIEW") ? "CIR"
                : ($ws eq "ASR")                          ? "ASR"
                : ($ws eq "CALL_SIGN")                    ? "CS"
                : $ws;

    my $entry = {id => $pid, m => $month, dt => $dt, ws => $ws_abbr, c => $c};

    if ($cx_ws_set{$ws}) {
        my $eng = $tracker{$pid}{cx};
        if ($eng && $known_cx{$eng}) {
            push @{$CX_DATA{$eng}}, $entry;
        } else {
            $cnt_skip_cx_eng++;
        }
    }
    if ($isa_ws_set{$ws}) {
        my $eng = $tracker{$pid}{isa};
        if ($eng) {
            push @{$ISA_DATA{$eng}}, $entry;
        }
    }
}

print STDERR "Processing results:\n";
print STDERR "  Matched: $cnt_matched\n";
print STDERR "  Skipped (wrong WS): $cnt_skip_ws\n";
print STDERR "  Skipped (outside Feb-May window): $cnt_skip_month\n";
print STDERR "  Skipped (no tracker entry): $cnt_skip_tracker\n";
print STDERR "  Skipped CX (eng not in known list): $cnt_skip_cx_eng\n";

# ---------------------------------------------------------------------------
# Deduplicate and sort
# ---------------------------------------------------------------------------
sub dedup_and_sort {
    my ($hash_ref) = @_;
    for my $eng (keys %$hash_ref) {
        my %seen;
        my @deduped;
        for my $e (@{$hash_ref->{$eng}}) {
            my $key = join("|", $e->{id}, $e->{dt}, $e->{ws}, $e->{c});
            unless ($seen{$key}++) {
                push @deduped, $e;
            }
        }
        @deduped = sort { date_sort_key($a->{dt}) cmp date_sort_key($b->{dt}) } @deduped;
        $hash_ref->{$eng} = \@deduped;
    }
}

dedup_and_sort(\%CX_DATA);
dedup_and_sort(\%ISA_DATA);

print STDERR "\nCX engineers:\n";
for my $eng (sort keys %CX_DATA) {
    print STDERR "  $eng: " . scalar(@{$CX_DATA{$eng}}) . " entries\n";
}
print STDERR "\nISA engineers:\n";
for my $eng (sort keys %ISA_DATA) {
    print STDERR "  $eng: " . scalar(@{$ISA_DATA{$eng}}) . " entries\n";
}

# ---------------------------------------------------------------------------
# Generate JS output
# ---------------------------------------------------------------------------
sub render_data_obj {
    my ($var_name, $hash_ref) = @_;
    my $out = "const $var_name = {\n";
    my @engs = sort keys %$hash_ref;
    for my $i (0..$#engs) {
        my $eng  = $engs[$i];
        my $entries = $hash_ref->{$eng};
        $out .= "  \"" . js_escape($eng) . "\": [\n";
        for my $j (0..$#$entries) {
            my $e = $entries->[$j];
            my $comma = ($j < $#$entries) ? "," : "";
            $out .= "    {id:\"" . js_escape($e->{id}) . "\", m:\"" . js_escape($e->{m}) .
                    "\", dt:\"" . js_escape($e->{dt}) . "\", ws:\"" . js_escape($e->{ws}) .
                    "\", c:\"" . js_escape($e->{c}) . "\"}$comma\n";
        }
        my $eng_comma = ($i < $#engs) ? "," : "";
        $out .= "  ]$eng_comma\n";
    }
    $out .= "};\n";
    return $out;
}

my $output = render_data_obj("CX_DATA",  \%CX_DATA);
$output   .= "\n";
$output   .= render_data_obj("ISA_DATA", \%ISA_DATA);

my $outfile = "$BASE/eng_js_data_v7.txt";
open(my $ofh, ">:encoding(UTF-8)", $outfile) or die "Cannot write $outfile: $!";
print $ofh $output;
close $ofh;

print STDERR "\nWrote: $outfile\n";
print STDERR "Done.\n";
