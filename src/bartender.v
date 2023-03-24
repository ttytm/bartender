// Source: https://github.com/tobealive/bartender
// License: MIT
module bartender

import time
import term

struct PapaBar {
mut:
	state u16
pub mut:
	width  u16 = 79
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
	runes  struct {
		f  []rune // Fillers
		f2 []rune // Fillers reversed. Used for merge, expand and split variant.
		d  []rune // Delimeters
	}
pub mut:
	theme   ThemeChoice = Theme.push
	timeout u8 = 2 // Milliseconds between printing characters to the same column for a smooth effect
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

// { == Prepare ==> ===========================================================

pub fn (mut b SmoothBar) prep() {
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
				.merge, .expand {
					b.prep_merge_expand()
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

fn (mut b SmoothBar) prep_merge_expand() {
	b.runes = struct {
		f: bartender.smooth_ltr
		f2: bartender.smooth_rtl.reverse()
		d: bartender.delimeters
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
		else {}
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
		time.sleep(time.millisecond * b.timeout)
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
		time.sleep(time.millisecond * b.timeout * 2)
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
		time.sleep(time.millisecond * b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.d[0].repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.d[1].repeat(width / 2 - b.state)} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

// <== }

fn finish(res string) {
	eprint('\r')
	term.erase_line('2')
	term.show_cursor()
	println(res)
}
