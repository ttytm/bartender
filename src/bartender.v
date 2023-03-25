// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

struct PapaBar {
mut:
	state u16
pub mut:
	color  Color
	width  u16 = 79
	label  [2]string // Pending, Finished
	border [2]string = ['', '']! // Start, End
}

type Color = bool | TermColor
type TermColor = fn (msg string) string

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
	f2 []string // Fillers(usually reversed versions). Used for merge, expand and split variant.
	d  []string // Delimeters
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

const (
	smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
	smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
	delimeters = ['█', ' '] // Used for progress until current state and remaining space.
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

	if b.color is TermColor {
		b.paint()
	}
}

fn (mut b SmoothBar) prep_push(stream Stream) {
	b.runes = struct {
		f: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		d: if stream == .fill { bartender.delimeters } else { bartender.delimeters.reverse() }
	}
}

fn (mut b SmoothBar) prep_pull(stream Stream) {
	b.runes = struct {
		f: if stream == .fill {
			bartender.smooth_rtl.reverse()
		} else {
			bartender.smooth_ltr.reverse()
		}
		d: if stream == .fill { bartender.delimeters.reverse() } else { bartender.delimeters }
	}
}

fn (mut b SmoothBar) prep_duals() {
	b.runes = struct {
		f: if b.theme_ == .split { bartender.smooth_rtl } else { bartender.smooth_ltr }
		f2: if b.theme_ == .split {
			bartender.smooth_ltr.reverse()
		} else {
			bartender.smooth_rtl.reverse()
		}
		d: bartender.delimeters
	}
}

fn (mut b SmoothBar) paint() {
	mut painted_runes := SmoothRunes{}
	for d in b.runes.d {
		painted_runes.d << term.colorize(b.color as TermColor, d)
	}
	for mut f in b.runes.f {
		painted_runes.f << term.colorize(b.color as TermColor, f)
	}
	if b.runes.f2.len > 0 {
		for mut f in b.runes.f2 {
			painted_runes.f2 << term.colorize(b.color as TermColor, f)
		}
	}
	b.runes = painted_runes
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
	if b.runes.f.len == 0 {
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

	for r in b.runes.f {
		eprint('\r${b.border[0]}${b.runes.d[0].repeat(n[0])}${r}')
		time.sleep(b.timeout)
	}

	if b.state >= b.width {
		dlm := if b.theme_ == .pull { b.runes.d[1] } else { b.runes.d[0] }
		finish('${b.border[0]}${dlm.repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}

	// Fill with delimters when state didn't reached full width.
	eprint('${b.runes.d[1].repeat(n[1])}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b SmoothBar) draw_merge() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.f {
		eprint('\r${b.runes.d[0].repeat(b.state)}${b.runes.f[idx]}')
		if width - b.state * 2 >= 0 {
			eprint(b.runes.d[1].repeat(width - b.state * 2))
		} else {
			eprint(b.runes.d[0])
		}
		eprint(b.runes.f2[idx])
		time.sleep(b.timeout)
	}
	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.d[0].repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.border[0]}${b.runes.d[0].repeat(b.state)} ${b.state * 100 / (width / 2)}%${b.border[1]} ${b.label[0]}')
}

fn (b SmoothBar) draw_expand() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.f {
		eprint('\r${b.runes.d[1].repeat(width / 2 - b.state)}${b.runes.f2[idx]}${b.runes.d[0].repeat(b.state * 2)}${b.runes.f[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.d[0].repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.d[1].repeat(width / 2 - b.state)} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_split() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.f {
		eprint('\r${b.runes.d[0].repeat(width / 2 - b.state)}${b.runes.f2[idx]}${b.runes.d[1].repeat(b.state * 2)}${b.runes.f[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.d[1].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.border[0]}${b.runes.d[0].repeat(width / 2 - b.state)} ${b.state * 100 / (width / 2)}%${b.border[1]} ${b.label[0]}')
}

// <== }

fn finish(res string) {
	eprint('\r')
	term.erase_line('2')
	term.show_cursor()
	println(res)
}
