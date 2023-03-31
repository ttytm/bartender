module bartender

import term

pub struct Bar {
	BarBase
pub mut:
	runes     BarRunes
	indicator ?rune
	pre       AffixInput = '['
	post      AffixInput = fn (b Bar) (string, string) {
		progress := '] ${b.pct()}% (${b.eta(0)})'
		return progress, progress
	}
mut:
	runes_     [2]string // Internally resolve to strings instead of runes for color support.
	indicator_ string
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
	eprint('\r${b.pre_}${b.runes_[0].repeat(b.state.pos - 1)}${b.indicator_}')
	if b.state.pos >= b.width_ {
		b.finish(b.runes_[0].repeat(b.width_))
		return
	}
	eprint('${b.runes_[1].repeat(b.width_ - b.state.pos)}${b.post_}')
}

fn (b &Bar) finish(bar string) {
	term.erase_line('2')
	println('\r${b.pre_}${bar}${b.post_}')
	term.show_cursor()
}
