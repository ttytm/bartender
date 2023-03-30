module bartender

import term

pub struct Bar {
	BarBase
mut:
	runes_     [2]string // Strings instead of runes for color support.
	indicator_ string
pub mut:
	runes     BarRunes
	indicator ?rune
}

pub struct BarRunes {
	progress  rune = `#`
	remaining rune = ` `
}

fn (mut b Bar) setup() {
	b.state.pos = 0
	b.iters = b.width
	b.width_ = b.width
	b.runes_ = [b.runes.progress.str(), b.runes.remaining.str()]!
	b.indicator_ = b.indicator or { b.runes.progress }.str()
}

fn (b Bar) draw() {
	prefix := b.pre.resolve_affix(.pending)
	postfix := b.post.resolve_affix(.pending)

	eprint('\r${prefix}${b.runes_[0].repeat(b.state.pos - 1)}${b.indicator_}')
	if b.state.pos >= b.width_ {
		b.finish(b.runes_[0].repeat(b.width_))
		return
	}
	eprint('${b.runes_[1].repeat(b.width_ - b.state.pos)}${postfix}')
}

fn (b &Bar) finish(bar string) {
	term.erase_line('2')
	println('\r${b.pre.resolve_affix(.finished)}${bar}${b.post.resolve_affix(.finished)}')
	term.show_cursor()
}
