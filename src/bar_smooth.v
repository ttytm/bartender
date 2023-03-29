module bartender

import term

pub struct SmoothBar {
	BarBase
mut:
	params SmoothBarParams
	runes  SmoothRunes
	rune_i u8
pub mut:
	theme ThemeChoice = Theme.push // Extends user config.
	// Number of iterations. Eventually resolves to number of smooth runes * params.width. NOTE: temporary solution.
	iters int = 80
}

// Private params. Set on setup() based on user width and theme config.
// This solution is up for improvement.
struct SmoothBarParams {
mut:
	width u16
	theme Theme
}

// The current solution might be improved. In Rust it would be one enum with push & pull being tuple variants.
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

struct SmoothRunes {
mut: // Strings instead of runes for color support.
	f  []string // Fillers.
	s  []string // Smooth.
	sm []string // Smooth Mirrored. Used for merge, expand and split variant.
}

const (
	smooth_ltr = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█']
	smooth_rtl = ['█', '🮋', '🮊', '🮉', '▐', '🮈', '🮇', '▕', ' ']
	fillers    = ['█', ' '] // Used for progress until current state and remaining space.
)

fn (mut b SmoothBar) setup() {
	if mut b.theme is Theme {
		b.params.theme = b.theme
		match b.theme {
			.push {
				b.setup_push(.fill)
			}
			.pull {
				b.setup_pull(.fill)
			}
			else {
				b.setup_duals()
			}
		}
	} else if mut b.theme is ThemeVariant {
		match b.theme.theme {
			.push {
				b.params.theme = .push
				b.setup_push(b.theme.stream)
			}
			.pull {
				b.params.theme = .pull
				b.setup_pull(b.theme.stream)
			}
		}
	}

	b.width -= 1
	if b.params.theme != .push && b.params.theme != .pull {
		b.width -= 1
	}
	b.params.width = b.width

	b.state.pos = 0
	b.iters = b.params.width * b.runes.s.len
	if b.params.theme != .push && b.params.theme != .pull {
		b.iters /= 2
	}
}

fn (mut b SmoothBar) setup_push(stream Stream) {
	b.runes = struct {
		s: if stream == .fill { bartender.smooth_ltr } else { bartender.smooth_rtl }
		f: if stream == .fill { bartender.fillers } else { bartender.fillers.reverse() }
	}
}

fn (mut b SmoothBar) setup_pull(stream Stream) {
	b.runes = struct {
		s: if stream == .fill {
			bartender.smooth_rtl.reverse()
		} else {
			bartender.smooth_ltr.reverse()
		}
		f: if stream == .fill { bartender.fillers.reverse() } else { bartender.fillers }
	}
}

fn (mut b SmoothBar) setup_duals() {
	b.runes = struct {
		s: if b.params.theme == .split { bartender.smooth_rtl } else { bartender.smooth_ltr }
		sm: if b.params.theme == .split {
			bartender.smooth_ltr.reverse()
		} else {
			bartender.smooth_rtl.reverse()
		}
		f: bartender.fillers
	}
}

fn (b SmoothBar) draw_push_pull() {
	n := if b.params.theme == .pull {
		[b.params.width - b.state.pos, b.state.pos] // progressively empty
	} else {
		[b.state.pos, b.params.width - b.state.pos] // progressively fill
	}

	left := '${b.pre.resolve_affix(.pending)}${b.runes.f[0].repeat(n[0])}${b.runes.s[b.rune_i]}'
	right := '${b.runes.f[1].repeat(n[1])}${b.post.resolve_affix(.pending)}'

	eprint('\r${left}${right}')

	if b.state.pos >= b.params.width {
		progress := if b.params.theme == .pull { b.runes.f[1] } else { b.runes.f[0] }
		b.finish(progress.repeat(b.params.width + 1))
	}
}

fn (b SmoothBar) draw_merge() {
	remaining := b.params.width - b.state.pos

	left := '${b.pre.resolve_affix(.pending)}${b.runes.f[0].repeat(b.state.pos / 2)}${b.runes.s[b.rune_i]}'
	// TODO: Smoothness for last two cols.
	middle := if remaining >= 0 {
		b.runes.f[1].repeat(remaining)
	} else {
		b.runes.f[0]
	}
	right := '${b.runes.sm[b.rune_i]}${b.runes.f[0].repeat(b.state.pos / 2)}${b.post.resolve_affix(.pending)}'

	eprint('\r${left}${middle}${right}')

	if b.state.pos >= b.params.width {
		b.finish(b.runes.f[0].repeat(b.params.width + 2))
	}
}

fn (b SmoothBar) draw_expand() {
	prefix := b.pre.resolve_affix(.pending)
	postfix := b.post.resolve_affix(.pending)

	left := '${prefix}${b.runes.f[1].repeat((b.params.width - b.state.pos) / 2)}${b.runes.sm[b.rune_i]}'
	middle := b.runes.f[0].repeat(b.state.pos)
	right := '${b.runes.s[b.rune_i]}${b.runes.f[1].repeat((b.params.width - b.state.pos) / 2)}${postfix}'

	eprint('\r${left}${middle}${right}')

	if b.state.pos >= b.params.width {
		b.finish(b.runes.f[0].repeat(b.params.width + 2))
	}
}

fn (b SmoothBar) draw_split() {
	prefix := b.pre.resolve_affix(.pending)
	postfix := b.post.resolve_affix(.pending)

	left := '${prefix}${b.runes.f[0].repeat((b.params.width - b.state.pos) / 2)}${b.runes.sm[b.rune_i]}'
	middle := b.runes.f[1].repeat(b.state.pos)
	right := '${b.runes.s[b.rune_i]}${b.runes.f[0].repeat((b.params.width - b.state.pos) / 2)}${postfix}'

	eprint('\r${left}${middle}${right}')
	if b.state.pos >= b.params.width {
		b.finish(b.runes.f[1].repeat(b.params.width + 2))
	}
}

fn (b SmoothBar) next_pos() u16 {
	return b.state.pos + u16(if b.params.theme == .push || b.params.theme == .pull {
		1
	} else {
		2
	})
}

fn (b &SmoothBar) finish(bar string) {
	term.erase_line('2')
	println('\r${b.pre.resolve_affix(.finished)}${bar}${b.post.resolve_affix(.finished)}')
	term.show_cursor()
}
