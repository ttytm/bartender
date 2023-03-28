module bartender

pub struct Bar {
	BarBase
mut:
	params BarParams
pub mut:
	runes     [2]rune = [`#`, ` `]!
	indicator ?rune
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
		runes: [b.runes[0].str(), b.runes[1].str()]!
		indicator: b.indicator or { b.runes[0] }.str()
	}
}

fn (b Bar) draw() {
	eprint('\r${b.border[0]}${b.params.runes[0].repeat(b.state.pos - 1)}${b.params.indicator}')
	if b.state.pos >= b.params.width {
		finish('${b.border[0]}${b.params.runes[0].repeat(b.params.width)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.params.runes[1].repeat(b.params.width - b.state.pos)}${b.border[1]} ${b.label[0]}')
}
