#!/usr/bin/env bash
# Objective, CJK-safe scorer for the su-dongpo eval.
# Usage: done_when.sh <essay.md>
# Prints one JSON object; exits 0 iff every done-when check passes.
# Machine criteria here MUST stay in sync with goal.md.
set -euo pipefail

essay="${1:?essay markdown file required}"
[ -f "$essay" ] || { printf '{"error":"no essay file: %s"}\n' "$essay"; exit 1; }

perl -CSDA -e '
  use utf8;                          # CJK literals in this program are UTF-8
  my $f = $ARGV[0];
  open my $fh, "<:encoding(UTF-8)", $f or die "open: $!";
  local $/; my $text = <$fh>; close $fh;

  my @parts = split /^##\s+/m, $text;
  shift @parts;                      # drop title/preamble before first "## "
  my $n = scalar @parts;

  my $MINLEN = 220;
  my $thesis = qr/旷达|超然|豁达|随遇而安|从容|乐观/;
  my $min_ok = 1; my $tie = 0;
  for my $p (@parts) {
    my $body = $p; $body =~ s/^[^\n]*\n//;     # strip the heading line
    $min_ok = 0 if length($body) < $MINLEN;
    $tie++ if $p =~ $thesis;
  }
  my $ratio = $n ? $tie / $n : 0;

  my @cov = ("乌台诗案","黄州","赤壁","定风波","惠州","儋州");
  my $hits = 0; for my $c (@cov) { $hits++ if index($text, $c) >= 0; }

  my $tangent = ($text =~ /^##\s+.*(苏辙|王安石变法|御史台制度)/m) ? 1 : 0;

  my $REQ = 5; my $TIE_MIN = 0.8; my $COV_MIN = 0.8;
  my $passed = ($n >= $REQ && $min_ok && $ratio >= $TIE_MIN
                && ($hits/scalar(@cov)) >= $COV_MIN && !$tangent) ? "true" : "false";

  printf "{\"chapters\":%d,\"min_len_ok\":%s,\"thesis_tie_ratio\":%.2f,\"coverage_hits\":%d,\"coverage_total\":%d,\"tangent_section\":%s,\"done_when_passed\":%s}\n",
    $n, ($min_ok?"true":"false"), $ratio, $hits, scalar(@cov), ($tangent?"true":"false"), $passed;
  exit($passed eq "true" ? 0 : 1);
' "$essay"
