#!/usr/bin/env bash
# run_patch_tests.sh — Internal regression for Verilator patches 7fb3e5d
# Each SV file must define exactly one _tb module as the testbench top.
set -uo pipefail

PASS=0; FAIL=0
BDIR=/tmp/vlt_patch_tests
mkdir -p "$BDIR"

log() { printf "  %-10s %s\n" "[$1]" "$2"; }

# $1=name  $2=sv_file  $3=top_module
run_test() {
  local name="$1" sv="$2" top="$3"
  local out="$BDIR/t_${name}"
  rm -rf "$out"; mkdir -p "$out"

  if ! verilator --binary --coverage --timing \
       -Wno-WIDTHTRUNC -Wno-IMPLICITSTATIC -Wno-DECLFILENAME \
       --top-module "$top" \
       --Mdir "$out/obj" -o "$out/sim" -j 0 \
       "$sv" >"$out/build.log" 2>&1; then
    if grep -q "COVERIGN" "$out/build.log"; then
      log "FAIL" "$name — unexpected COVERIGN"
      grep "COVERIGN" "$out/build.log" | head -2 | sed 's/^/           /'
    else
      log "FAIL" "$name — build error"
      grep -E "(%Error|error:)" "$out/build.log" | head -3 | sed 's/^/           /'
    fi
    ((FAIL++)); return
  fi

  if grep -q "COVERIGN" "$out/build.log"; then
    log "FAIL" "$name — unexpected COVERIGN"
    grep "COVERIGN" "$out/build.log" | head -2 | sed 's/^/           /'
    ((FAIL++)); return
  fi

  local sim_out
  if ! sim_out=$("$out/sim" 2>&1); then
    log "FAIL" "$name — runtime crash"
    echo "$sim_out" | grep -vE "^(-| V)" | head -4 | sed 's/^/           /'
    ((FAIL++)); return
  fi

  if echo "$sim_out" | grep -q "^PASS:"; then
    log "PASS" "$name — $(echo "$sim_out" | grep "^PASS:" | head -1)"
    ((PASS++))
  else
    log "FAIL" "$name — PASS string not found"
    echo "$sim_out" | grep -vE "^(-| V)" | head -3 | sed 's/^/           /'
    ((FAIL++))
  fi
}

echo "================================================================"
echo "  Verilator Patch Internal Regression"
echo "  $(verilator --version | head -1)"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "================================================================"

BASE="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "--- Patch 1: V3FsmDetect (FSM + --coverage crash fix) ---"
run_test fsm_simple  "$BASE/patch_fsm/t_fsm_cov_simple.sv"  t_fsm_cov_simple_tb
run_test fsm_async   "$BASE/patch_fsm/t_fsm_cov_async.sv"   t_fsm_cov_async_tb
run_test fsm_moore   "$BASE/patch_fsm/t_fsm_cov_moore.sv"   t_fsm_cov_moore_tb

echo ""
echo "--- Patch 2: V3Covergroup (class-embedded coverpoint fix) ---"
run_test cg_simple   "$BASE/patch_class_cg/t_cg_simple.sv"   t_cg_simple_tb
run_test cg_cross    "$BASE/patch_class_cg/t_cg_cross.sv"    t_cg_cross_tb
run_test cg_multi    "$BASE/patch_class_cg/t_cg_multi.sv"    t_cg_multi_tb
run_test cg_inherit  "$BASE/patch_class_cg/t_cg_inherit.sv"  t_cg_inherit_tb

echo ""
echo "--- Coverage output verification ---"
run_test cov_data    "$BASE/patch_coverage/t_cov_data.sv"    t_cov_data_tb

echo ""
echo "================================================================"
echo "  PASS=$PASS  FAIL=$FAIL"
echo "================================================================"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
