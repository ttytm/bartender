module bartender

import term

pub struct Bar {
	BarBase
mut:
	params BarParams
pub mut:
	runes     BarRunes
	indicator ?rune
}

pub struct BarRunes {
	progress  rune = `#`
	remaining rune = ` `
}

// Private params. Set on setup() based on user width and theme config.
struct BarParams {
mut:
	width     u16
	runes     [2]string // Strings instead of runes for color support.
	indicator string
}

fn (mut b Bar) setup() {
	b.state.pos = 0
	b.params = BarParams{
		width: b.width
		runes: [b.runes.progress.str(), b.runes.remaining.str()]!
		indicator: b.indicator or { b.runes.progress }.str()
	}
}

fn (b Bar) draw() {
	prefix := b.pre.resolve_affix(.pending)
	postfix := b.post.resolve_affix(.pending)

	eprint('\r${prefix}${b.params.runes[0].repeat(b.state.pos - 1)}${b.params.indicator}')
	if b.state.pos >= b.params.width {
		b.finish(b.params.runes[0].repeat(b.params.width))
		return
	}
	eprint('${b.params.runes[1].repeat(b.params.width - b.state.pos)}${postfix}')
}

fn (b &Bar) finish(bar string) {
	term.erase_line('2')
	println('\r${b.pre.resolve_affix(.finished)}${bar}${b.post.resolve_affix(.finished)}')
	term.show_cursor()
}
