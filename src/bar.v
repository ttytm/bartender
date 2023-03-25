module bartender

pub struct Bar {
	Bar_
pub mut:
	runes     [2]rune = [`#`, ` `]!
	indicator ?rune
}

type Rune = rune | string

fn (b Bar) draw() {
	eprint('\r${b.border[0]}${b.runes[0].repeat(b.state - 1)}${b.indicator or { b.runes[1] }}')
	if b.state >= b.width {
		finish('${b.border[0]}${b.runes[0].repeat(b.width)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes[1].repeat(b.width - b.state)}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}
