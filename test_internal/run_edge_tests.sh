#!/usr/bin/env bash
# run_edge_tests.sh — Phase 2 edge case tests for patch 7fb3e5d
# Tests verify graceful handling of known unsupported patterns
# Usage: VERILATOR_BIN=./bin/verilator zsh test_internal/run_edge_tests.sh
set -uo pipefail

PASS=0; FAIL=0
BDIR=/tmp/vlt_edge_tests
mkdir -p "$BDIR"

VERILATOR_BIN="${VERILATOR_BIN:-$(cd "$(dirname "$0")/.." && echo "$PWD/bin/verilator")}"
log() { printf "  %-12s %s\n" "[$1]" "$2"; }

# expect_coverign: compile must succeed OR emit COVERIGN — must NOT crash internally
run_expect_coverign() {
  local name="$1" sv="$2" top="$3"
  local out="$BDIR/t_${name}"
  rm -rf "$out"; mkdir -p "$out"

  # Run verilator — allow exit code 1 (COVERIGN causes warning-as-error in strict mode)
  "$VERILATOR_BIN" --binary --coverage --timing \
    -Wno-WIDTHTRUNC -Wno-IMPLICITSTATIC -Wno-DECLFILENAME \
    --top-module "$top" \
    --Mdir "$out/obj" -o "$out/sim" \
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

  if ! "$VERILATOR_BIN" --binary --coverage --timing \
       -Wno-WIDTHTRUNC -Wno-IMPLICITSTATIC -Wno-DECLFILENAME \
       --top-module "$top" \
       --Mdir "$out/obj" -o "$out/sim" \
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
echo "--- bins with(expr) filter — IEEE 1800-2012 §19.7.1 ---"
echo "    Pattern: bins even = {[0:15]} with (item % 2 == 0)"
echo "    Expected: CLEAN compile + run (PASS output; COVERIGN suppressed by lint_off)"
run_expect_clean bins_with_expr \
  "$BASE/patch_edge_cases/t_bins_with_expr.sv" \
  t_bins_with_expr

echo ""
echo "--- Transition repetition operators [*N], [->N], [=N] ---"
echo "    Pattern: bins t = (a [* 3]) — previously BBCOVERIGN"
echo "    Expected: CLEAN compile + run (PASS output; COVERIGN suppressed by lint_off)"
run_expect_clean bins_trans_rep \
  "$BASE/patch_edge_cases/t_bins_trans_rep.sv" \
  t_bins_trans_rep

echo ""
echo "--- Explicit cross bins & repetition ranges ---"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean new_features \
  "$BASE/patch_edge_cases/t_new_features.sv" \
  t_new_features

echo ""
echo "--- Edge Case B: external covergroup new() construction ---"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean edgeB_external \
  "$BASE/patch_edge_cases/t_edgeB_external.sv" \
  t_edgeB_external

echo ""
echo "--- Struct member coverpoint crossing & query APIs ---"
echo "    Expected: CLEAN compile + run (PASS output, no COVERIGN)"
run_expect_clean struct_cross \
  "$BASE/patch_edge_cases/t_struct_cross.sv" \
  t_struct_cross

echo ""
echo "================================================================"
echo "  PASS=$PASS  FAIL=$FAIL"
echo "================================================================"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
