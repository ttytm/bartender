// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

struct PapaBar {
mut:
	state u16
pub mut:
	width  u16 = 80
	label  [2]string // Pending, Finished
	border [2]string = ['', '']! // Start, End
}

pub struct Bar {
	PapaBar
pub mut:
	runes     [2]rune = [`#`, ` `]!
	indicator ?rune
}

pub struct SmoothBar {
	PapaBar
mut:
	theme_ Theme
	runes  SmoothRunes
pub mut:
	timeout time.Duration = time.microsecond * 500 // Duration between same column character prints for a smooth effect.
	theme   ThemeChoice   = Theme.push // Putting sumtype field first breaks default value. Related issue (github.com/vlang/v/issues/17758)
}

struct SmoothRunes {
mut:
	f  []string // Fillers
	s  []string // Smooth
	sm []string // Smooth Mirrored. Used for merge, expand and split variant.
}

// The current solution might be improved. In Rust it would be one enum with `push` & `pull` being tuple variants.
type ThemeChoice = Theme | ThemeVariant

pub enum Theme {
	push
	pull
	merge
	expand
	split
}

pub struct ThemeVariant {
	theme  ThemeVariantOpt
	stream Stream
}

pub enum ThemeVariantOpt {
	push
	pull
}

pub enum Stream {
	fill
	drain
}

type Color = TermColor|ComponentColor
type TermColor = fn (msg string) string

pub struct ComponentColor {
	fill   TermColor
	border TermColor
}

const (
	smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
	smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
	fillers = ['█', ' '] // Used for progress until current state and remaining space.
)

// { == Prepare ==> ===========================================================

pub fn (mut b SmoothBar) prep() {
	b.state = 0

	if mut b.theme is Theme {
		b.theme_ = b.theme
		match b.theme {
			.push {
				b.prep_push(.fill)
			}
			.pull {
				b.prep_pull(.fill)
			}
			else {
				b.prep_duals()
			}
		}
	} else if mut b.theme is ThemeVariant {
		match b.theme.theme {
			.push {
				b.theme_ = .push
				b.prep_push(b.theme.stream)
			}
			.pull {
				b.theme_ = .pull
				b.prep_pull(b.theme.stream)
			}
		}
	}
}

fn (mut b SmoothBar) prep_push(stream Stream) {
	b.runes = struct {
		s: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		f: if stream == .fill { bartender.fillers } else { bartender.fillers.reverse() }
	}
}

fn (mut b SmoothBar) prep_pull(stream Stream) {
	b.runes = struct {
		s: if stream == .fill {
			bartender.smooth_rtl.reverse()
		} else {
			bartender.smooth_ltr.reverse()
		}
		f: if stream == .fill { bartender.fillers.reverse() } else { bartender.fillers }
	}
}

fn (mut b SmoothBar) prep_duals() {
	b.runes = struct {
		s: if b.theme_ == .split { bartender.smooth_rtl } else { bartender.smooth_ltr }
		sm: if b.theme_ == .split {
			bartender.smooth_ltr.reverse()
		} else {
			bartender.smooth_rtl.reverse()
		}
		f: bartender.fillers
	}
}

// <== }

// { == Colors ==> ============================================================

pub fn (mut b SmoothBar) colorize(color Color) {
	b.prep()

	if color !is ComponentColor {
		b.colorize_all(color as TermColor)
		return
	}
	b.colorize_components(color as ComponentColor)
}

fn (mut b SmoothBar) colorize_all(color TermColor) {
	mut painted_runes := SmoothRunes{}

	for d in b.runes.f {
		painted_runes.f << term.colorize(color as TermColor, d)
	}
	for mut f in b.runes.s {
		painted_runes.s << term.colorize(color as TermColor, f)
	}
	if b.runes.sm.len > 0 {
		for mut f in b.runes.sm {
			painted_runes.sm << term.colorize(color as TermColor, f)
		}
	}

	b.runes = painted_runes

	if b.border.len > 0 {
		painted_border := [term.colorize(color as TermColor, b.border[0]),
			term.colorize(color as TermColor, b.border[1])]!
		b.border = painted_border
	}
}

fn (mut b SmoothBar) colorize_components(color ComponentColor) {
	mut painted_runes := SmoothRunes{}

	painted_runes.f << term.colorize(color.fill, b.runes.f[0])
	painted_runes.f << b.runes.f[1]
	for mut f in b.runes.s {
		painted_runes.s << term.colorize(color.fill, f)
	}
	if b.runes.sm.len > 0 {
		for mut f in b.runes.sm {
			painted_runes.sm << term.colorize(color.fill, f)
		}
	}

	b.runes = painted_runes

	if b.border.len > 0 {
		painted_border := [term.colorize(color.border, b.border[0]),
			term.colorize(color.border, b.border[1])]!
		b.border = painted_border
	}
}

// <== }

// { == Progress ==> ==========================================================

pub fn (mut b Bar) progress() {
	if b.state == 0 {
		term.hide_cursor()
	}
	b.state += 1
	b.draw()
}

pub fn (mut b SmoothBar) progress() {
	if b.runes.s.len == 0 {
		b.prep()
	}
	if b.state == 0 {
		term.hide_cursor()
	}

	b.state += 1

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

// <== }

// { == Draw ==> ==============================================================

fn (b Bar) draw() {
	eprint('\r${b.border[0]}${b.runes[0].repeat(b.state - 1)}${b.indicator or { b.runes[1] }}')
	if b.state >= b.width {
		finish('${b.border[0]}${b.runes[0].repeat(b.width)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes[1].repeat(b.width - b.state)}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b SmoothBar) draw_push_pull() {
	// Progressively empty. || Progressively fill.
	n := if b.theme_ == .pull { [b.width - b.state, b.state] } else { [b.state, b.width - b.state] }

	for r in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(n[0])}${r}')
		time.sleep(b.timeout)
	}

	if b.state >= b.width {
		dlm := if b.theme_ == .pull { b.runes.f[1] } else { b.runes.f[0] }
		finish('${b.border[0]}${dlm.repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[1].repeat(n[1])}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b SmoothBar) draw_merge() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(b.state)}${b.runes.s[idx]}')
		if width - b.state * 2 >= 0 {
			eprint(b.runes.f[1].repeat(width - b.state * 2))
		} else {
			eprint(b.runes.f[0])
		}
		eprint(b.runes.sm[idx])
		time.sleep(b.timeout)
	}
	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[0].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[0].repeat(b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_expand() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[1].repeat(width / 2 - b.state)}${b.runes.sm[idx]}${b.runes.f[0].repeat(b.state * 2)}${b.runes.s[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[0].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[1].repeat(width / 2 - b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_split() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(width / 2 - b.state)}${b.runes.sm[idx]}${b.runes.f[1].repeat(b.state * 2)}${b.runes.s[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[1].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[0].repeat(width / 2 - b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

// <== }

fn finish(res string) {
	eprint('\r')
	term.erase_line('2')
	term.show_cursor()
	println(res)
}
