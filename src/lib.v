// Source: https://github.com/tobealive/bartender License: MIT

// The lib.v file contains all public functions. Associated public structs
// and private sub-functions are located in the corresponding files.
module bartender

import term
import time

struct BarBase {
mut:
	state State
	// Private params. Based on public equivalents and assigned on `<bar>.setup()` or on `<bar>.progress()`.
	// Might get mutated by e.g., state or terminal size changes.
	width_ u16
	pre_   string
	post_  string
pub mut:
	width u16 = 60
	// Number of iterations. NOTE: Solution is up for improvement.
	// Resolves to `width_` for `Bar` and `smooth_runes.len * width_` for `SmoothBar`.
	iters int = 60
	// TODO: improve default values
	pre AffixInput = Affix{
		pending: ''
		finished: ''
	}
	post AffixInput = Affix{
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

type BarType = Bar | SmoothBar

// TODO: return (string, stirng) for prefix and postfix in affix_fns
type AffixInput = Affix | fn (b Bar) string | fn (b SmoothBar) string | string

const spinner_runes = ['⡀', '⠄', '⠂', '⠁', '⠈', '⠐', '⠠', '⢀']!

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
	b.state.time.last_change = time.ticks()

	// Pre- and Postfix.
	prefix, postfix := resolve_affixations(b)
	b.pre_ = prefix
	b.post_ = postfix

	// Adjust width to potential term size change.
	last_width := b.width_
	// ---
	b.set_fit_width()
	if last_width != b.width_ {
		b.iters = b.width_
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

pub fn (b Bar) eta(delay u8) string {
	next_pos := b.state.pos + 1
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time to progress one postion until now * rest of positions.
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
	// Time
	b.state.time.last_change = time.ticks()

	// Pre- and Postfix.
	prefix, postfix := resolve_affixations(b)
	b.pre_ = prefix
	b.post_ = postfix

	// Width. Adjust to potential term size change.
	last_width := b.width
	// ---
	b.set_fit_width()
	if last_width != b.width_ {
		b.iters = b.width_ * b.runes.s.len
		if b.theme_ != .push && b.theme_ != .pull {
			b.iters /= 2
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

// TODO: allow custom pct / eta fns with append prepend for easier partial customized setup?
/*
pub fn (b SmoothBar) pct_str() fn (SmoothBar) string {
	return fn (b SmoothBar) string {
		return b.pct().str()
	}
}*/

pub fn (b SmoothBar) pct() u16 {
	if b.width_ == 0 {
		return 0
	}
	return b.next_pos() * 100 / b.width_
}

// TODO: range input 0..100, document.
pub fn (b SmoothBar) eta(delay u8) string {
	next_pos := b.next_pos()
	if b.width_ == b.state.pos {
		return ''
	}
	if next_pos < f32(b.width_) * delay / 100 {
		return b.spinner()
	}
	// Avg. time to progress one postion until now * rest of positions.
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

// SumType won't work as BarType method. But no issues as param.
fn (a AffixInput) resolve_affix(b BarType, state AffixState) string {
	return match a {
		fn (SmoothBar) string {
			match b {
				SmoothBar { a(b) }
				else { '' }
			}
		}
		fn (Bar) string {
			match b {
				Bar { a(b) }
				else { '' }
			}
		}
		Affix {
			if state == .pending {
				a.pending
			} else {
				a.finished
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
