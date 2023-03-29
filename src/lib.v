// Source: https://github.com/tobealive/bartender
// License: MIT

// The lib.v file contains all public functions. Associated public structs
// and private sub-functions are located in the corresponding files.
module bartender

import term
import time

struct BarBase {
mut:
	state State
pub mut:
	width u16 = 80
	pre AffixType = Affix{
		pending: ''
		finished: ''
	}
	post AffixType = Affix{
		pending: ''
		finished: ''
	}
}

type AffixType = Affix | string

pub struct Affix {
	pending  string
	finished string
}

enum AffixState {
	pending
	finished
}

struct State {
mut:
	pos     u16
	percent u8
	time    Time
}

struct Time {
	start i64
mut:
	last_change i64
}

const spinner_runes = ['⡀', '⠄', '⠂', '⠁', '⠈', '⠐', '⠠', '⢀']!

// { == Bar ==> ===============================================================

pub fn (mut b Bar) progress() {
	if b.params.runes[0].len == 0 {
		b.setup()
	}
	if b.state.pos >= b.params.width {
		panic(IError(BarError{ kind: .finished }))
	}
	if b.state.pos == 0 {
		term.hide_cursor()
		b.state.time = Time{
			start: time.ticks()
		}
	}
	b.state.time.last_change = time.ticks()
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
	if b.params.width == 0 {
		return 0
	}
	return (b.state.pos + 1) * 100 / b.params.width
}

pub fn (b Bar) eta() f64 {
	next_pos := b.state.pos + 1
	return (b.state.time.last_change - b.state.time.start) / next_pos * (b.params.width - next_pos)
}

pub fn (b Bar) spinner() string {
	if b.state.pos + 1 >= b.params.width {
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
	if b.runes.s.len == 0 {
		b.setup()
	}
	if b.state.pos >= b.params.width {
		panic(IError(BarError{ kind: .finished }))
	}

	// Time
	if b.state.pos == 0 {
		term.hide_cursor()
		b.state.time = Time{
			start: time.ticks()
		}
	}
	b.state.time.last_change = time.ticks()

	// Position
	b.rune_i += 1
	if b.rune_i == b.runes.s.len {
		b.rune_i = 0
		b.state.pos += 1
		if b.params.theme == .merge || b.params.theme == .expand || b.params.theme == .split {
			b.state.pos += 1
		}
	}

	// Draw
	term.erase_line('0')
	match b.params.theme {
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
	if b.params.width == 0 {
		return 0
	}
	return b.next_pos() * 100 / b.params.width
}

pub fn (b SmoothBar) eta() f64 {
	next_pos := b.next_pos()
	if b.params.width == next_pos {
		return 0.0
	}
	return (b.state.time.last_change - b.state.time.start) / next_pos * (b.width - next_pos)
}

pub fn (b SmoothBar) spinner() string {
	next_pos := b.next_pos()
	if b.params.width == next_pos {
		return ''
	}
	return bartender.spinner_runes[(b.rune_i) % bartender.spinner_runes.len]
}

// <== }

// { == Misc ==> ==============================================================

pub fn (b BarBase) pos() u16 {
	return b.state.pos
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
