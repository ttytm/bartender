// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

pub struct Bar {
mut:
	state u16
pub mut:
	theme Theme = Push{.fill}
	label [2]string // Pending, Finished
	width u16 = 79
	runes Runes
}

pub struct Runes {
	f []rune // Fillers
	d []rune // Delimeters
}

// In rust it'd be an enum with it's push & pull variants having values. The current solution can probably be improved.
type Theme = Expand | Merge | Pull | Push | Split

pub struct Push {
	stream Stream
}

pub struct Pull {
	stream Stream
}

pub enum Stream {
	fill
	drain
}

pub struct Merge {}

pub struct Expand {}

pub struct Split {}

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
		Push {
			b.prep_push(b.theme.stream)
		}
		Pull {
			b.prep_pull(b.theme.stream)
		}
		else {}
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
	repeat := match b.theme {
		Pull {
			[b.width - b.state, b.state]
		}
		else {
			[b.state, b.width - b.state]
		}
	}

	for r in b.runes.f {
		eprint(`\r`)
		// Progress until current state.
		eprint(b.runes.d[0].repeat(repeat[0]))
		eprint(r)
		time.sleep(bartender.timeout_ms * time.millisecond)
	}

	if b.state >= b.width {
		b.finish()
		return
	}

	// Fill with delimters when state didn't reached full width.
	eprint(b.runes.d[1].repeat(repeat[1]))
	eprint(' ${b.state * 100 / b.width}% ${b.label[0]}')
}

pub fn (mut b Bar) progress() {
	if b.runes.f.len == 0 {
		b.prep()
	}
	b.state += 1

	match b.theme {
		Pull, Push {
			b.draw()
		}
		else {}
	}
}

fn (b Bar) finish() {
	dlm := match b.theme {
		Pull {
			b.runes.d[1]
		}
		else {
			b.runes.d[0]
		}
	}
	eprint('\r')
	term.erase_line('2')
	println('${dlm.repeat(b.width + 1)} ${b.state * 100 / b.width}% ${b.label[1]}')
}

// <== }
