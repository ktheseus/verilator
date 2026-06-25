#!/usr/bin/env bash
# run_edge_tests.sh — Phase 2 edge case tests for patch 7fb3e5d
# Tests verify graceful handling of known unsupported patterns
set -uo pipefail

PASS=0; FAIL=0
BDIR=/tmp/vlt_edge_tests
mkdir -p "$BDIR"

log() { printf "  %-12s %s\n" "[$1]" "$2"; }

# expect_coverign: compile must succeed OR emit COVERIGN — must NOT crash internally
run_expect_coverign() {
  local name="$1" sv="$2" top="$3"
  local out="$BDIR/t_${name}"
  rm -rf "$out"; mkdir -p "$out"

  # Run verilator — allow exit code 1 (COVERIGN causes warning-as-error in strict mode)
  verilator --binary --coverage --timing \
    -Wno-WIDTHTRUNC -Wno-IMPLICITSTATIC -Wno-DECLFILENAME \
    --top-module "$top" \
    --Mdir "$out/obj" -o "$out/sim" -j 0 \
    "$sv" >"$out/build.log" 2>&1 || true  # allow failure

  # Must NOT be an internal compiler error
  if grep -q "Internal Error\|Aborting\|UASSERT\|Segmentation fault" "$out/build.log"; then
    log "FAIL" "$name — INTERNAL CRASH (must never happen)"
    grep -E "Internal Error|Aborting|UASSERT" "$out/build.log" | head -3 | sed 's/^/             /'
    ((FAIL++)); return
  fi

  # Should emit COVERIGN (either warning or error)
  if grep -q "COVERIGN" "$out/build.log"; then
    log "PASS" "$name — COVERIGN emitted gracefully (no crash)"
    grep "COVERIGN" "$out/build.log" | head -1 | sed 's/^/             /'
    ((PASS++))
  else
    # No COVERIGN and no crash — check if it compiled+ran cleanly
    if [ -x "$out/sim" ] && "$out/sim" 2>&1 | grep -q "^PASS:"; then
      log "PASS" "$name — compiled+ran cleanly (better than expected)"
      ((PASS++))
    else
      log "FAIL" "$name — expected COVERIGN but got neither COVERIGN nor clean run"
      tail -5 "$out/build.log" | sed 's/^/             /'
      ((FAIL++))
    fi
  fi
}

# expect_clean: compile + run must succeed with PASS output, no COVERIGN
run_expect_clean() {
  local name="$1" sv="$2" top="$3"
  local out="$BDIR/t_${name}"
  rm -rf "$out"; mkdir -p "$out"

  if ! verilator --binary --coverage --timing \
       -Wno-WIDTHTRUNC -Wno-IMPLICITSTATIC -Wno-DECLFILENAME \
       --top-module "$top" \
       --Mdir "$out/obj" -o "$out/sim" -j 0 \
       "$sv" >"$out/build.log" 2>&1; then
    log "FAIL" "$name — build error"
    grep "%Error" "$out/build.log" | head -3 | sed 's/^/             /'
    ((FAIL++)); return
  fi

  if grep -q "COVERIGN" "$out/build.log"; then
    log "FAIL" "$name — unexpected COVERIGN"
    grep "COVERIGN" "$out/build.log" | head -2 | sed 's/^/             /'
    ((FAIL++)); return
  fi

  local sim_out
  sim_out=$("$out/sim" 2>&1)
  if echo "$sim_out" | grep -q "^PASS:"; then
    log "PASS" "$name — $(echo "$sim_out" | grep '^PASS:' | head -1)"
    ((PASS++))
  else
    log "FAIL" "$name — PASS string not found"
    echo "$sim_out" | grep -vE "^(-| V)" | head -3 | sed 's/^/             /'
    ((FAIL++))
  fi
}

echo "================================================================"
echo "  Verilator Patch Edge Case Tests (Phase 2)"
echo "  $(verilator --version | head -1)"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================"

BASE="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "--- Edge Case A: generic LHS in covergroup new() ---"
echo "    Pattern: cg_ops = new() where vlEnclosing is injected for any AstNodeExpr LHS"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean edgeA_membersel_lhs \
  "$BASE/patch_edge_cases/t_edgeA_membersel_lhs.sv" \
  t_edgeA_membersel_lhs

echo ""
echo "--- Edge Case C: covergroup class-member VarRefs via vlEnclosing ---"
echo "    Pattern: covergroup inside class with coverpoints on class members"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean edgeC_clocking_member \
  "$BASE/patch_edge_cases/t_edgeC_clocking_member.sv" \
  t_edgeC_clocking_member

echo ""
echo "--- Value range bins: {[lo:hi]} in covergroup bins ---"
echo "    Pattern: bins b = {[8'h00:8'h7F]} — previously COVERIGN"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean bins_value_range \
  "$BASE/patch_edge_cases/t_bins_value_range.sv" \
  t_bins_value_range

echo ""
echo "--- Explicit bins array size: bins b[N] = {values} ---"
echo "    Pattern: bins states[4] = {IDLE,ACTIVE,ERROR,RESET} — previously COVERIGN"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean bins_explicit_size \
  "$BASE/patch_edge_cases/t_bins_explicit_size.sv" \
  t_bins_explicit_size

echo ""
echo "================================================================"
echo "  PASS=$PASS  FAIL=$FAIL"
echo "================================================================"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
