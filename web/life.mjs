function word_to_u32(w) {
  let x = 0;
  for (let i = 0; w.$ === "WCon"; i++) {
    x |= Number(w.head) << i;
    w = w.tail;
  }
  return x >>> 0;
}

function u32_to_word(x) {
  let w = {$: "WNil"};
  for (let i = 31; i >= 0; i--) {
    w = {$: "WCon", head: ((x >>> i) & 1) === 1, tail: w};
  }
  return w;
}

function cmp_new(a, b) {
  return {$: a < b ? "LT" : a === b ? "EQ" : "GT"};
}

function tup_new(a, b) {
  return {$: "Tuple", fst: a, snd: b};
}

function nat_divmod(a, b) {
  return tup_new(b && Math.trunc(a / b), b ? a % b : a);
}

function nat_chk(n) {
  if (n > 281474976710655) {
    throw "bend: a Nat past the largest immediate 2^48-1";
  }
  return n;
}

function nat_in(n) {
  if (!Number.isInteger(n) || n < 0 || n > 2 ** 53) {
    throw "bend: expected a Nat host number: an integer from 0 to 2^53";
  }
  return n;
}

function f32_show(x) {
  let s = "nan";
  for (let p = 1; x === x && p <= 9 && f32_round(s) !== x; p += 1) {
    s = String(Number(x.toExponential(p - 1)));
  }
  return (Object.is(x, -0) ? "-0" : s).replace("Infinity", "inf");
}

function f32_bits(x) {
  return new Uint32Array(new Float32Array([x]).buffer)[0];
}

function f32_from_bits(u) {
  return new Float32Array(new Uint32Array([u]).buffer)[0];
}

function f32_read(s) {
  const re = /^[\t\n\v\f\r ]*[+-]?((\d+(?:\.\d*)?|\.\d+)(e[+-]?\d+)?|inf(inity)?|nan)$/i;
  return re.test(s) ? {$: "Some", value: f32_round(
    s.replace(/inf\w*/i, "Infinity"))} : {$: "None"};
}

const f32_round = function f32_round(s) {
  const d = Number(s), a = Math.abs(d), f = Math.fround(a), g = 2 * a - Math.min(f, 340282366920938500000000000000000000000);
  if (g === f || Math.fround(g) !== g || g === 1 / 0)
    return Math.sign(d) * f;
  let k = 0;
  while (a * 2 ** k % 1 !== 0)
    k += 1;
  const [, i, r, e] = /(\d*)\.?(\d*)(?:e([+-]?\d+))?$/i.exec(s), n = Number(e ?? 0) - r.length, x = BigInt(i + r) * 2n ** BigInt(k) * 10n ** BigInt(Math.max(n, 0)), y = BigInt(a * 2 ** k) * 10n ** BigInt(Math.max(-n, 0));
  return Math.sign(d) * (x === y || x > y !== g > f ? f : g);
};

const char_new = function char_new(c) {
  return c < 55296 ? String.fromCharCode(c) : c >= 57344 && c <= 1114111 ? String.fromCodePoint(c) : String.fromCharCode(56320, c >>> 22, c >>> 11 & 2047, c & 2047);
};

function char_len(s, at = 0) {
  const c = s.codePointAt(at);
  return c === 0xDC00 ? 4 : c > 0xFFFF ? 2 : 1;
}

function char_code(s) {
  return s.length < 4 ? s.codePointAt(0)
    : (s.charCodeAt(1) << 22 | s.charCodeAt(2) << 11 | s.charCodeAt(3)) >>> 0;
}

function string_contains(s, p) {
  // A match starts at a Char, not inside a packed U32 code.
  for (let at = 0; at <= s.length; at += char_len(s, at)) {
    if (s.startsWith(p, at)) {
      return true;
    }
  }
  return false;
}

function str_out(s) {
  return s.replace(/\uDC00[^]{3}/gu, "\uFFFD");
}

function str_in(s) {
  return s.replace(/\p{Cs}/gu, "\uFFFD");
}

// Array
// =====

function array_new(d, v, lgs) {
  if (d > 31 - lgs) {
    throw "bend: an array past the deepest block class 31 (depth + log2 words per cell)";
  }
  return Array(2 ** d).fill(v);
}

function array_node(a, b) {
  if (a.length !== b.length) {
    throw "bend: runtime fail-stop";
  }
  return a.concat(b);
}

function array_swap(a, i, v) {
  const old = a[i &= a.length - 1];
  a[i] = v;
  return tup_new(a, old);
}

// Run
// ===

function run_tail(f, x) {
  return {$: "$JMP", f: f.j?.f === f ? f.j : f, x};
}

function run_clo(j) {
  const f = (x) => run_loop(j(x));
  f.j = j;
  j.f = f;
  return f;
}

function run_loop(r) {
  while (r !== null && typeof r === "object" && r.$ === "$JMP") {
    r = r.f(r.x);
  }
  return r;
}

function run_lib(f, n) {
  return (...a) => a.length < n ? run_lib((...b) => f(...a, ...b), n - a.length)
    : run_loop(f(...a));
}

// Effect
// ======

const $0eff = Object.create(null);
const io_file_append = new Set();

function io_eff(k, run) {
  if (arguments.length > 2) {
    throw new Error("bend: " + k + " takes no need: an effect that waits parks itself");
  }
  if (k in $0eff) {
    throw new Error("bend: two effects register " + k);
  }
  $0eff[k] = run;
}
// Program
// =======

function $next_cell(_alive_0, _neighbors_0) {
  if (_neighbors_0 == 0) {
    return false;
  } else if (_neighbors_0 == 1) {
    return false;
  } else if (_neighbors_0 == 2) {
    return _alive_0;
  } else if (_neighbors_0 == 3) {
    return true;
  } else {
    return false;
  }
}

function $first_or(_n_0, _row_0, _east_0) {
  if (_n_0 == 0) {
    return _east_0;
  } else {
    const _b_0 = _row_0["head"];
    return _b_0;
  }
}

function $count_three(_w_0, _c_0, _e_0) {
  const _x_0 = $$Bool_to_u32(_w_0);
  const _x_1 = $$Bool_to_u32(_c_0);
  const _x_2 = ((_x_0 + _x_1) >>> 0);
  const _x_3 = $$Bool_to_u32(_e_0);
  return ((_x_2 + _x_3) >>> 0);
}

function $scan(_n_0, _top_0, _mid_0, _bot_0, _tw_0, _mw_0, _bw_0, _te_0, _me_0, _be_0) {
  if (_n_0 == 0) {
    return {$: "WNil"};
  } else {
    const _k_0 = (_n_0 - 1);
    const _tc_0 = _top_0["head"];
    const _tr_0 = _top_0["tail"];
    const _mc_0 = _mid_0["head"];
    const _mr_0 = _mid_0["tail"];
    const _bc_0 = _bot_0["head"];
    const _br_0 = _bot_0["tail"];
    const _above_0 = $$count_three(_tw_0, _tc_0, $$first_or(_k_0, _tr_0, _te_0));
    const _x_0 = $$Bool_to_u32(_mw_0);
    const _x_1 = $$Bool_to_u32($$first_or(_k_0, _mr_0, _me_0));
    const _beside_0 = ((_x_0 + _x_1) >>> 0);
    const _below_0 = $$count_three(_bw_0, _bc_0, $$first_or(_k_0, _br_0, _be_0));
    const _x_2 = ((_above_0 + _beside_0) >>> 0);
    const _x_3 = ((_x_2 + _below_0) >>> 0);
    const _alive_0 = $$next_cell(_mc_0, (_x_3 ));
    return {$: "WCon", "head": _alive_0, "tail": $$scan(_k_0, _tr_0, _mr_0, _br_0, _tc_0, _mc_0, _bc_0, _te_0, _me_0, _be_0)};
  }
}

function $decode_edge_bits(_w_0) {
  const _west_0 = _w_0["head"];
  const _t_0 = _w_0["tail"];
  const _east_0 = _t_0["head"];
  return {$: "edges", "west": _west_0, "east": _east_0};
}

function $decode_edge(_w_0) {
  const _bits_0 = u32_to_word(_w_0);
  return $decode_edge_bits(_bits_0);
}

function $scan_word(_top_0, _mid_0, _bot_0, _te_0, _me_0, _be_0) {
  const _tw_0 = _te_0["west"];
  const _tr_0 = _te_0["east"];
  const _mw_0 = _me_0["west"];
  const _mr_0 = _me_0["east"];
  const _bw_0 = _be_0["west"];
  const _br_0 = _be_0["east"];
  return word_to_u32($$scan(32, _top_0, _mid_0, _bot_0, _tw_0, _mw_0, _bw_0, _tr_0, _mr_0, _br_0));
}

function $next_word(_top_0, _mid_0, _bot_0, _te_0, _me_0, _be_0) {
  const _t_0 = u32_to_word(_top_0);
  const _m_0 = u32_to_word(_mid_0);
  const _b_0 = u32_to_word(_bot_0);
  return $scan_word(_t_0, _m_0, _b_0, $$decode_edge(_te_0), $$decode_edge(_me_0), $$decode_edge(_be_0));
}

function $next_row(_top_0, _mid_0, _bottom_0) {
  return $next_word(_top_0, _mid_0, _bottom_0, 0, 0, 0);
}

function $last_bit($0, $1) {
  for (;;) {
    {
      const _n_0 = $0;
      const _word_0 = $1;
      if (_n_0 == 0) {
        const _b_0 = _word_0["head"];
        return _b_0;
      } else {
        const _k_0 = (_n_0 - 1);
        const _tail_0 = _word_0["tail"];
        $0 = _k_0;
        $1 = _tail_0;
        continue;
      }
    }
  }
}

function $neighbor_edge(_left_0, _right_0) {
  const _l_0 = u32_to_word(_left_0);
  const _r_0 = u32_to_word(_right_0);
  return {$: "edges", "west": $$last_bit(31, _l_0), "east": $$first_or(32, _r_0, false)};
}

function $next_neighborhood(_tl_0, _tc_0, _tr_0, _ml_0, _mc_0, _mr_0, _bl_0, _bc_0, _br_0) {
  const _t_0 = u32_to_word(_tc_0);
  const _m_0 = u32_to_word(_mc_0);
  const _b_0 = u32_to_word(_bc_0);
  return $scan_word(_t_0, _m_0, _b_0, $$neighbor_edge(_tl_0, _tr_0), $$neighbor_edge(_ml_0, _mr_0), $$neighbor_edge(_bl_0, _br_0));
}

function $clip(_distance_0, _candidate_0) {
  if (_distance_0 == 0) {
    return 0;
  } else {
    return _candidate_0;
  }
}

function $next_bounded(_left_0, _right_0, _up_0, _down_0, _tl_0, _tc_0, _tr_0, _ml_0, _mc_0, _mr_0, _bl_0, _bc_0, _br_0) {
  return $next_neighborhood($$clip(_up_0, $$clip(_left_0, _tl_0)), $$clip(_up_0, _tc_0), $$clip(_up_0, $$clip(_right_0, _tr_0)), $$clip(_left_0, _ml_0), _mc_0, $$clip(_right_0, _mr_0), $$clip(_down_0, $$clip(_left_0, _bl_0)), $$clip(_down_0, _bc_0), $$clip(_down_0, $$clip(_right_0, _br_0)));
}

function $wrap_before(_before_0, _after_0) {
  if (_before_0 == 0) {
    return _after_0;
  } else {
    const _i_0 = (_before_0 - 1);
    return _i_0;
  }
}

function $wrap_after(_before_0, _after_0) {
  if (_after_0 == 0) {
    return 0;
  } else {
    return nat_chk(_before_0 + 1);
  }
}

function $Bool_to_u32(_b_0) {
  if (!_b_0) {
    return 0;
  } else {
    return 1;
  }
}

const $$Bool_to_u32 = $Bool_to_u32;
const $$first_or = $first_or;
const $$count_three = $count_three;
const $$next_cell = $next_cell;
const $$scan = $scan;
const $$decode_edge = $decode_edge;
const $$last_bit = $last_bit;
const $$neighbor_edge = $neighbor_edge;
const $$clip = $clip;export default {
  "next_cell": run_lib((a0,a1) => run_loop($next_cell(a0,nat_in(a1))), 2),
  "first_or": run_lib((a0,a1,a2) => run_loop($first_or(nat_in(a0),a1,a2)), 3),
  "count_three": run_lib((a0,a1,a2) => run_loop($count_three(a0,a1,a2)), 3),
  "scan": run_lib((a0,a1,a2,a3,a4,a5,a6,a7,a8,a9) => run_loop($scan(nat_in(a0),a1,a2,a3,a4,a5,a6,a7,a8,a9)), 10),
  "decode_edge_bits": run_lib((a0) => run_loop($decode_edge_bits(a0)), 1),
  "decode_edge": run_lib((a0) => run_loop($decode_edge(a0)), 1),
  "scan_word": run_lib((a0,a1,a2,a3,a4,a5) => run_loop($scan_word(a0,a1,a2,a3,a4,a5)), 6),
  "next_word": run_lib((a0,a1,a2,a3,a4,a5) => run_loop($next_word(a0,a1,a2,a3,a4,a5)), 6),
  "next_row": run_lib((a0,a1,a2) => run_loop($next_row(a0,a1,a2)), 3),
  "last_bit": run_lib((a0,a1) => run_loop($last_bit(nat_in(a0),a1)), 2),
  "neighbor_edge": run_lib((a0,a1) => run_loop($neighbor_edge(a0,a1)), 2),
  "next_neighborhood": run_lib((a0,a1,a2,a3,a4,a5,a6,a7,a8) => run_loop($next_neighborhood(a0,a1,a2,a3,a4,a5,a6,a7,a8)), 9),
  "clip": run_lib((a0,a1) => run_loop($clip(nat_in(a0),a1)), 2),
  "next_bounded": run_lib((a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12) => run_loop($next_bounded(nat_in(a0),nat_in(a1),nat_in(a2),nat_in(a3),a4,a5,a6,a7,a8,a9,a10,a11,a12)), 13),
  "wrap_before": run_lib((a0,a1) => run_loop($wrap_before(nat_in(a0),nat_in(a1))), 2),
  "wrap_after": run_lib((a0,a1) => run_loop($wrap_after(nat_in(a0),nat_in(a1))), 2),
};
