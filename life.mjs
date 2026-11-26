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

function $bit(_row_0, _mask_0) {
  const _x_0 = ((_row_0 & _mask_0) >>> 0);
  return $Bool_to_u32((_x_0 !== 0));
}

function $lanes_for(_word_0, _edge_0) {
  const _x_0 = ((_word_0 << 1) >>> 0);
  const _x_1 = ((_edge_0 & 1) >>> 0);
  const _west_0 = ((_x_0 | _x_1) >>> 0);
  const _x_2 = ((_edge_0 >>> 1) >>> 0);
  const _x_3 = ((_x_2 & 1) >>> 0);
  const _x_4 = ((_word_0 >>> 1) >>> 0);
  const _x_5 = (31 >= 32 ? 0 : (_x_3 << 31) >>> 0);
  const _east_0 = ((_x_4 | _x_5) >>> 0);
  return {$: "lanes", "west": _west_0, "center": _word_0, "east": _east_0};
}

function $full_count(_row_0, _mask_0) {
  const _w_0 = _row_0["west"];
  const _c_0 = _row_0["center"];
  const _e_0 = _row_0["east"];
  const _x_0 = $$bit(_w_0, _mask_0);
  const _x_1 = $$bit(_c_0, _mask_0);
  const _x_2 = ((_x_0 + _x_1) >>> 0);
  const _x_3 = $$bit(_e_0, _mask_0);
  return ((_x_2 + _x_3) >>> 0);
}

function $scan_word($0, $1, $2, $3, $4, $5) {
  for (;;) {
    {
      const _fuel_0 = $0;
      const _top_0 = $1;
      const _mid_0 = $2;
      const _bottom_0 = $3;
      const _mask_0 = $4;
      const _acc_0 = $5;
      if (_fuel_0 == 0) {
        return _acc_0;
      } else {
        const _rest_0 = (_fuel_0 - 1);
        const _w_0 = _mid_0["west"];
        const _c_0 = _mid_0["center"];
        const _e_0 = _mid_0["east"];
        const _x_0 = $$bit(_w_0, _mask_0);
        const _x_1 = $$bit(_e_0, _mask_0);
        const _x_2 = $$full_count(_top_0, _mask_0);
        const _x_3 = ((_x_0 + _x_1) >>> 0);
        const _x_4 = ((_x_2 + _x_3) >>> 0);
        const _x_5 = $$full_count(_bottom_0, _mask_0);
        const _n_0 = ((_x_4 + _x_5) >>> 0);
        const _x_6 = $$bit(_c_0, _mask_0);
        const _old_0 = (_x_6 !== 0);
        const _x_7 = $$Bool_to_u32($$next_cell(_old_0, (_n_0 )));
        const _born_0 = (Math.imul(_x_7, _mask_0) >>> 0);
        $0 = _rest_0;
        $1 = _top_0;
        $2 = {$: "lanes", "west": _w_0, "center": _c_0, "east": _e_0};
        $3 = _bottom_0;
        $4 = ((_mask_0 << 1) >>> 0);
        $5 = ((_acc_0 | _born_0) >>> 0);
        continue;
      }
    }
  }
}

function $next_word(_top_0, _mid_0, _bottom_0, _top_edge_0, _mid_edge_0, _bottom_edge_0) {
  return $scan_word(32, $$lanes_for(_top_0, _top_edge_0), $$lanes_for(_mid_0, _mid_edge_0), $$lanes_for(_bottom_0, _bottom_edge_0), 1, 0);
}

function $next_row(_top_0, _mid_0, _bottom_0) {
  return $next_word(_top_0, _mid_0, _bottom_0, 0, 0, 0);
}

function $Bool_to_u32(_b_0) {
  if (!_b_0) {
    return 0;
  } else {
    return 1;
  }
}

const $$bit = $bit;
const $$full_count = $full_count;
const $$next_cell = $next_cell;
const $$Bool_to_u32 = $Bool_to_u32;
const $$lanes_for = $lanes_for;export default {
  "next_cell": run_lib((a0,a1) => run_loop($next_cell(a0,nat_in(a1))), 2),
  "bit": run_lib((a0,a1) => run_loop($bit(a0,a1)), 2),
  "lanes_for": run_lib((a0,a1) => run_loop($lanes_for(a0,a1)), 2),
  "full_count": run_lib((a0,a1) => run_loop($full_count(a0,a1)), 2),
  "scan_word": run_lib((a0,a1,a2,a3,a4,a5) => run_loop($scan_word(nat_in(a0),a1,a2,a3,a4,a5)), 6),
  "next_word": run_lib((a0,a1,a2,a3,a4,a5) => run_loop($next_word(a0,a1,a2,a3,a4,a5)), 6),
  "next_row": run_lib((a0,a1,a2) => run_loop($next_row(a0,a1,a2)), 3),
};
