// Source: https://github.com/tobealive/bartender
// License: MIT

// This lib.v file contains general code for the BarBase as well as all public functions.
// Associated structs and private sub-functions are located in the corresponding files.
module bartender

import term
import time
import io

struct BarBase {
pub mut:
	width u16 = 60
	// Number of iterations. NOTE: Solution is up for improvement.
	// Resolves to `width_` for `Bar` and `smooth_runes.len * width_` for `SmoothBar`.
	iters int = 60
mut:
	state State
	// Private params. Based on public equivalents. Assigned on `<bar>.setup()` or on `<bar>.progress()`.
	// Might get mutated by state or terminal size changes.
	width_ u16
	pre_   string
	post_  string
}

struct BarReaderBase {
	bytes []u8
	size  int
mut:
	pos int
}

struct State {
mut:
	pos     u16
	percent u8
	time    struct {
	mut:
		start       i64
		last_change i64
	}
}

pub struct Affix {
pub mut:
	pending  string
	finished string
}

enum AffixState {
	pending
	finished
}

type BarType = Bar | SmoothBar
type BarReaderType = BarReader | SmoothBarReader

type AffixInput = Affix
	| fn (b Bar) (string, string)
	| fn (b SmoothBar) (string, string)
	| string

const (
	buf_max_len   = 1024
	spinner_runes = ['⡀', '⠄', '⠂', '⠁', '⠈', '⠐', '⠠', '⢀']!
)

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
	if b.state.time.start == 0 {
		if b.runes_[0].len == 0 {
			b.setup()
		}
		b.state.time = struct {time.ticks(), 0}
		term.hide_cursor()
	}
	if b.state.pos >= b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}

	b.set_vals()
	b.draw()
}

pub fn (mut b Bar) colorize(color BarColorType) {
	b.setup()

	if color is BarColor {
		b.colorize_components(color)
	} else {
		b.colorize_uni(color as Color)
	}
}

pub fn (b Bar) pct() u16 {
	if b.width_ == 0 {
		return 0
	}
	return (b.state.pos + 1) * 100 / b.width_
}

// Return the Estimated Time of Arrival (ETA) in the format <n.n>s.
// The accuracy of the ETA calculation improves as the process progresses.
// The display of the time can be postponed until the progress bar reaches 0-100% completion.
// A spinner will be shown until the specified delay is reached.
pub fn (b Bar) eta(delay u8) string {
	if delay > 100 {
		panic(IError(BarError{ kind: .delay_exceeded }))
	}
	next_pos := b.state.pos + 1
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time until now to move up one position * remaining positions.
	return '${f64(b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos) / 1000:.1f}s'
}

pub fn (b Bar) spinner() string {
	if b.state.pos + 1 >= b.width_ {
		return ''
	}
	return bartender.spinner_runes[(b.state.pos - 1) % bartender.spinner_runes.len]
}

pub fn (mut b Bar) reset() {
	b.setup()
}

// <== }

// { == SmoothBar ==> =========================================================

pub fn (mut b SmoothBar) progress() {
	if b.state.time.start == 0 {
		if b.runes.s.len == 0 {
			b.setup()
		}
		b.state.time = struct {time.ticks(), 0}
		term.hide_cursor()
	}
	if b.state.pos > b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}

	b.set_vals()

	// Draw
	term.erase_line('0')
	match b.theme_ {
		.push, .pull {
			b.draw_push_pull()
		}
		.merge {
			b.draw_merge()
		}
		.expand {
			b.draw_expand()
		}
		.split {
			b.draw_split()
		}
	}
}

pub fn (mut b SmoothBar) colorize(color Color) {
	b.setup()

	mut painted_runes := SmoothRunes{}

	for r in b.runes.f {
		painted_runes.f << color.paint(r, .fg)
	}
	for mut r in b.runes.s {
		painted_runes.s << color.paint(r, .fg)
	}
	if b.runes.sm.len > 0 {
		for mut r in b.runes.sm {
			painted_runes.sm << color.paint(r, .fg)
		}
	}

	b.runes = painted_runes
}

pub fn (b SmoothBar) pct() u16 {
	if b.width_ == 0 {
		return 0
	}
	return b.next_pos() * 100 / b.width_
}

// Return the Estimated Time of Arrival (ETA) in the format <n.n>s.
// The accuracy of the ETA calculation improves as the process progresses.
// The display of the time can be postponed until the progress bar reaches 0-100% completion.
// A spinner will be shown until the specified delay is reached.
pub fn (b SmoothBar) eta(delay u8) string {
	if delay > 100 {
		panic(IError(BarError{ kind: .delay_exceeded }))
	}
	next_pos := b.next_pos()
	if b.width_ == b.state.pos {
		return ''
	}
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time until now to move up one position * remaining positions.
	return '${f64(b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos) / 1000:.1f}s'
}

pub fn (b SmoothBar) spinner() string {
	next_pos := b.next_pos()
	if b.width_ == next_pos {
		return ''
	}
	return bartender.spinner_runes[(b.rune_i) % bartender.spinner_runes.len]
}

pub fn (mut b SmoothBar) reset() {
	b.setup()
}

// <== }

// { == Reader ==> ============================================================

pub fn bar_reader(b BarType, bytes []u8) &io.BufferedReader {
	return match b {
		Bar {
			io.new_buffered_reader(
				reader: BarReader{
					bytes: bytes
					size: bytes.len
					bar: b
				}
			)
		}
		SmoothBar {
			io.new_buffered_reader(
				reader: SmoothBarReader{
					bytes: bytes
					size: bytes.len
					bar: b
				}
			)
		}
	}
}

fn get_buf_end(r BarReaderType) int {
	return if r.pos + bartender.buf_max_len >= r.size {
		r.size
	} else {
		r.pos + bartender.buf_max_len
	}
}

// <== }

// { == Misc ==> ==============================================================

pub fn (b BarBase) pos() u16 {
	return b.state.pos
}

fn (mut b BarBase) set_fit_width() {
	term_width, _ := term.get_terminal_size()
	affix_width := utf8_str_visible_length(term.strip_ansi(b.pre_)) +
		utf8_str_visible_length(term.strip_ansi(b.post_))

	if term_width > b.width_ + affix_width {
		return
	}

	new_width := u16(term_width - affix_width) - 3
	diff := b.width_ - new_width

	if diff > b.state.pos {
		b.state.pos = 0
	} else {
		b.state.pos -= diff
	}

	b.width_ = new_width
}

fn (a AffixInput) resolve_affix(b BarType, state AffixState) string {
	return match a {
		fn (SmoothBar) (string, string) {
			pending, finished := a(b as SmoothBar)
			match state {
				.pending { pending }
				.finished { finished }
			}
		}
		fn (Bar) (string, string) {
			pending, finished := a(b as Bar)
			match state {
				.pending { pending }
				.finished { finished }
			}
		}
		Affix {
			match state {
				.pending { a.pending }
				.finished { a.finished }
			}
		}
		string {
			a
		}
	}
}

fn resolve_affixations(b BarType) (string, string) {
	next_pos := match b {
		Bar { b.state.pos + 1 }
		SmoothBar { b.next_pos() }
	}
	prefix := if next_pos >= b.width_ {
		b.pre.resolve_affix(b, .finished)
	} else {
		b.pre.resolve_affix(b, .pending)
	}
	postfix := if next_pos >= b.width_ {
		b.post.resolve_affix(b, .finished)
	} else {
		b.post.resolve_affix(b, .pending)
	}

	return prefix, postfix
}

// <== }
