module bartender

import term
import time
import io

pub struct Bar {
	BarBase
pub mut:
	runes BarRunes
	pre   AffixInput = '['
	post  AffixInput = fn (b Bar) (string, string) {
		return '] ${b.pct()}% (${b.eta(0)})', '] ${b.pct()}%'
	}
mut:
	runes_     BarRunes_
	indicator_ string
}

pub struct BarRunes {
	progress  rune = `#`
	indicator ?rune
	remaining rune = ` `
}

// Internally resolve to strings instead of runes for color support.
struct BarRunes_ {
	progress  string
	indicator string
	remaining string
}

struct BarReader {
	BarReaderBase
mut:
	bar Bar
}

fn (mut b Bar) setup() {
	b.state.pos = 0
	b.width_ = b.width
	b.iters = b.width
	b.runes_ = BarRunes_{
		progress: b.runes.progress.str()
		remaining: b.runes.remaining.str()
		indicator: b.runes.indicator or { b.runes.progress }.str()
	}
}

// Set bar values on progress
fn (mut b Bar) set_vals() {
	b.state.time.last_change = time.ticks()

	// Pre- and Postfix
	prefix, postfix := resolve_affixations(b)
	b.pre_ = prefix
	b.post_ = postfix

	// Width - adjust to potential term size change
	last_width := b.width_
	b.set_fit_width()
	if last_width != b.width_ {
		b.iters = b.width_
	}

	b.state.pos++
}

fn (b Bar) draw() {
	if b.state.pos == 1 && !b.multi {
		println('')
	}
	term.clear_previous_line()
	println(b.format())
}

fn (b Bar) format() string {
	left := b.pre_ + b.runes_.progress.repeat(b.state.pos - 1)
	indicator := if b.state.pos < b.width_ { b.runes_.indicator } else { b.runes_.progress }
	right := b.runes_.remaining.repeat(b.width_ - b.state.pos) + b.post_
	return left + indicator + right
}

fn (mut r BarReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}

	n := copy(mut buf, r.bytes[r.pos..get_buf_end(r)])
	r.pos += n

	if (f64(r.pos) / r.size * r.bar.width) > r.bar.pos() {
		r.bar.progress()
	}

	return n
}

fn (mut b Bar) colorize_uni(color Color) {
	b.runes_ = BarRunes_{
		progress: color.paint(b.runes_.progress, .fg)
		indicator: color.paint(b.runes_.indicator, .fg)
		remaining: color.paint(b.runes_.remaining, .fg)
	}
}

fn (mut b Bar) colorize_components(color BarColor) {
	b.runes_ = BarRunes_{
		progress: color.progress.paint_component(b.runes_.progress)
		indicator: color.indicator.paint_component(b.runes_.indicator)
		remaining: color.remaining.paint_component(b.runes_.remaining)
	}
}

fn (bars []&Bar) draw() bool {
	mut finished := true
	mut formatted := []string{}
	for b in bars {
		formatted << b.format()
		if b.state.pos > 0 && b.state.pos < b.width_ {
			finished = false
		}
	}
	println(formatted.join_lines())
	if !finished {
		term.cursor_up(bars.len)
	}
	return finished
}

fn (bars []&Bar) ensure_mutli() ! {
	mut not_multi := []int{}
	for i, bar in bars {
		if !bar.multi {
			not_multi << i
		}
	}
	if not_multi.len > 0 {
		return IError(BarError{
			kind: .missing_multi
			msg: '${not_multi}'
		})
	}
}
