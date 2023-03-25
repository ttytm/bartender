module bartender

pub struct Bar {
	Bar_
mut:
	runes_     [2]string // Strings instead of runes for color support.
	indicator_ string
pub mut:
	runes     [2]rune = [`#`, ` `]!
	indicator ?rune
}

type Rune = rune | string

fn (b Bar) draw() {
	eprint('\r${b.border[0]}${b.runes_[0].repeat(b.state - 1)}${b.indicator_}')
	if b.state >= b.width {
		finish('${b.border[0]}${b.runes_[0].repeat(b.width)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes_[1].repeat(b.width - b.state)}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (mut b Bar) setup() {
	b.state = 0
	b.runes_ = [b.runes[0].str(), b.runes[1].str()]!
	b.indicator_ = b.indicator or { b.runes[0] }.str()
}
