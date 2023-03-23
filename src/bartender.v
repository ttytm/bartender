// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

pub struct Bar {
mut:
	state  u16
	theme_ Theme
pub mut:
	theme ThemeChoice = Theme.push
	label [2]string // Pending, Finished
	width u16 = 79
	runes Runes
}

pub struct Runes {
	f []rune // Fillers
	d []rune // Delimeters
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
	timeout_ms = 2
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
	b.runes = Runes{
		f: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		d: if stream == .fill { bartender.delimeters } else { bartender.delimeters.reverse() }
	}
}

fn (mut b Bar) prep_pull(stream Stream) {
	b.runes = Runes{
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

fn (b Bar) draw() {
	n := match b.theme_ {
		.pull {
			// The bar progressively empties.
			[b.width - b.state, b.state]
		}
		else {
			// The bar progressively fills up, the difference to the full width is filled with delimiters.
			[b.state, b.width - b.state]
		}
	}

	for r in b.runes.f {
		eprint(`\r`)
		// Progress until current state.
		eprint(b.runes.d[0].repeat(n[0]))
		eprint(r)
		time.sleep(bartender.timeout_ms * time.millisecond)
	}

	if b.state >= b.width {
		b.finish()
		return
	}

	// Fill with delimters when state didn't reached full width.
	eprint(b.runes.d[1].repeat(n[1]))
	eprint(' ${b.state * 100 / b.width}% ${b.label[0]}')
}

pub fn (mut b Bar) progress() {
	if b.runes.f.len == 0 {
		b.prep()
	}
	b.state += 1

	if b.theme_ == .pull || b.theme_ == .push {
		b.draw()
	}
}

fn (b Bar) finish() {
	dlm := if b.theme_ == .pull { b.runes.d[1] } else { b.runes.d[0] }
	eprint('\r')
	term.erase_line('2')
	println('${dlm.repeat(b.width + 1)} ${b.label[1]}')
}

// <== }
