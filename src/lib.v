// Source: https://github.com/tobealive/bartender
// License: MIT

// The lib.v file contains all public functions. Associated public structs
// and private sub-functions are located in the corresponding files.
module bartender

import term
import time

struct BarBase {
mut:
	state  State
	// Private params suffixed with `_`. Based on public equivalents and assigned on `<bar>.setup()`.
	// `width_` is used as a reference for rendering operatiosn and might get mutated by terminal size.
	width_ u16
pub mut:
	width u16       = 60
	// Number of iterations. NOTE: Solution is up for improvement.
	// Resolves to `width_` for `Bar` and `smooth_runes.len * width_` for `SmoothBar`.
	iters int = 60
	pre   AffixType = Affix{
		pending: ''
		finished: ''
	}
	post AffixType = Affix{
		pending: ''
		finished: ''
	}
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

type AffixType = Affix | string

const spinner_runes = ['⡀', '⠄', '⠂', '⠁', '⠈', '⠐', '⠠', '⢀']!

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
	if b.state.time.start == 0 {
		if b.runes_[0].len == 0 {
			b.setup()
		}
		b.state.time = struct {time.ticks(), time.ticks()}
		term.hide_cursor()
	}
	if b.state.pos >= b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}
	if b.state.time.start != 0 {
		b.state.time.last_change = time.ticks()

		// Adjust width on potential term size change.
		last_width := b.width_
		b.set_fit_width()
		if last_width != b.width_ {
			b.iters = b.width_
		}
	}
	b.state.pos += 1

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

pub fn (b Bar) eta() f64 {
	next_pos := b.state.pos + 1
	return (b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos)
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
		b.state.time = struct {time.ticks(), time.ticks()}
		term.hide_cursor()
	}
	if b.state.pos > b.width_ {
		panic(IError(BarError{ kind: .finished }))
	}
	if b.state.time.start != 0 {
		b.state.time.last_change = time.ticks()

		// Adjust width on potential term size change.
		last_width := b.width
		b.set_fit_width()
		if last_width != b.width_ {
			b.iters = b.width_ * b.runes.s.len
			if b.theme_ != .push && b.theme_ != .pull {
				b.iters /= 2
			}
		}
	}

	// Positions
	b.rune_i += 1 // Index of the smooth rune to be rendered in the current progress.
	if b.rune_i == b.runes.s.len { // When all the smooth runes are rendered in one col, start again at the next col.
		b.rune_i = 0
		b.state.pos += 1
		if b.theme_ == .merge || b.theme_ == .expand || b.theme_ == .split {
			b.state.pos += 1
		}
	}

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

	/*// NOTE: Upstream issue. Colors are off when directly mutating. E.g.:
	for mut r in b.runes.f {
		r = color.paint(r, .fg)
	}*/
	// Putting them into a variable and then re-assigning works.
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

pub fn (mut b SmoothBar) reset() {
	b.setup()
}

pub fn (b SmoothBar) pct() u16 {
	if b.width_ == 0 {
		return 0
	}
	return b.next_pos() * 100 / b.width_
}

pub fn (b SmoothBar) eta() f64 {
	next_pos := b.next_pos()
	if b.width_ == next_pos {
		return 0.0
	}
	return (b.state.time.last_change - b.state.time.start) / next_pos * (b.width_ - next_pos)
}

pub fn (b SmoothBar) spinner() string {
	next_pos := b.next_pos()
	if b.width_ == next_pos {
		return ''
	}
	return bartender.spinner_runes[(b.rune_i) % bartender.spinner_runes.len]
}

// <== }

// { == Misc ==> ==============================================================

pub fn (b BarBase) pos() u16 {
	return b.state.pos
}

fn (mut b BarBase) set_fit_width() {
	term_width, _ := term.get_terminal_size()
	affix_width := utf8_str_visible_length(term.strip_ansi(b.pre.resolve_affix(.pending))) +
		utf8_str_visible_length(term.strip_ansi(b.post.resolve_affix(.pending)))

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

fn (a AffixType) resolve_affix(state AffixState) string {
	return match a {
		string {
			a
		}
		Affix {
			if state == .pending {
				a.pending
			} else {
				a.finished
			}
		}
	}
}

// <== }
