// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

pub struct Bar {
mut:
	state  u16
	theme_ Theme
	runes  struct {
		f []rune // Fillers
		d []rune // Delimeters
	}
pub mut:
	width   u16 = 79
	label   [2]string // Pending, Finished
	theme   ThemeChoice = Theme.push
	border  [2]string   = ['', '']! // Start, End
	timeout u8 = 2 // Milliseconds between printing characters to the same column for a smooth effect
}

pub struct Classic {
mut:
	state u16
pub mut:
	label  [2]string // Pending, Finished
	width  u16       = 79
	runes  [2]rune   = [`#`, ` `]!
	border [2]string = ['', '']! // Start, End
}

type ThemeChoice = Theme | ThemeVariant

// The current solution can probably be improved.
// In rust it'd be an enum with it's push & pull variants having values.
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
	smooth_ltr = [` `, `▏`, `▎`, `▍`, `▌`, `▋`, `▊`, `▉`, `█`]
	smooth_rtl = [`█`, `🮋`, `🮊`, `🮉`, `▐`, `🮈`, `🮇`, `▕`, ` `]
	delimeters = [`█`, ` `] // Used for progress until current state and remaining space.
)

// { == Themes ==> ============================================================

pub fn (mut b Bar) prep() {
	b.state = 0
	match mut b.theme {
		Theme {
			match b.theme {
				.push {
					b.prep_push(.fill)
				}
				.pull {
					b.prep_pull(.fill)
				}
				else {}
			}
			b.theme_ = b.theme
		}
		ThemeVariant {
			match b.theme.theme {
				.push {
					b.prep_push(b.theme.stream)
					b.theme_ = .push
				}
				.pull {
					b.prep_pull(b.theme.stream)
					b.theme_ = .pull
				}
			}
		}
	}
}

fn (mut b Bar) prep_push(stream Stream) {
	b.runes = struct {
		f: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		d: if stream == .fill { bartender.delimeters } else { bartender.delimeters.reverse() }
	}
}

fn (mut b Bar) prep_pull(stream Stream) {
	b.runes = struct {
		f: if stream == .fill {
			bartender.smooth_rtl.reverse()
		} else {
			bartender.smooth_ltr.reverse()
		}
		d: if stream == .fill { bartender.delimeters.reverse() } else { bartender.delimeters }
	}
}

// <== }

// { == Progress ==> ==========================================================

pub fn (mut b Classic) progress() {
	if b.state == 0 {
		term.hide_cursor()
	}
	b.state += 1
	b.draw()
}

fn (b Classic) draw() {
	eprint('\r${b.border[0]}${b.runes[0].repeat(b.state)}')
	if b.state >= b.width {
		b.finish()
		return
	}
	eprint('${b.runes[1].repeat(b.width - b.state)}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b Classic) finish() {
	eprint('\r')
	term.erase_line('2')
	println('${b.border[0]}${b.runes[0].repeat(b.width)}${b.border[1]} ${b.label[1]}')
	term.show_cursor()
}

pub fn (mut b Bar) progress() {
	if b.runes.f.len == 0 {
		b.prep()
	}
	if b.state == 0 {
		term.hide_cursor()
	}
	b.state += 1
	if b.theme_ == .pull || b.theme_ == .push {
		b.draw()
	}
}

fn (b Bar) draw() {
	// Progressively empty. || Progressively fill.
	n := if b.theme_ == .pull { [b.width - b.state, b.state] } else { [b.state, b.width - b.state] }

	for r in b.runes.f {
		eprint('\r${b.border[0]}${b.runes.d[0].repeat(n[0])}${r}')
		time.sleep(time.millisecond * b.timeout)
	}

	if b.state >= b.width {
		b.finish()
		return
	}

	// Fill with delimters when state didn't reached full width.
	eprint('${b.runes.d[1].repeat(n[1])}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b Bar) finish() {
	dlm := if b.theme_ == .pull { b.runes.d[1] } else { b.runes.d[0] }
	eprint('\r')
	term.erase_line('2')
	println('${b.border[0]}${dlm.repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
	term.show_cursor()
}

// <== }
