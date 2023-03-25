module bartender

import time

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

	for r in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(n[0])}${r}')
		time.sleep(b.timeout)
	}

	if b.state >= b.width {
		dlm := if b.theme_ == .pull { b.runes.f[1] } else { b.runes.f[0] }
		finish('${b.border[0]}${dlm.repeat(b.width + 1)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[1].repeat(n[1])}${b.border[1]} ${b.state * 100 / b.width}% ${b.label[0]}')
}

fn (b SmoothBar) draw_merge() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(b.state)}${b.runes.s[idx]}')
		if width - b.state * 2 >= 0 {
			eprint(b.runes.f[1].repeat(width - b.state * 2))
		} else {
			eprint(b.runes.f[0])
		}
		eprint(b.runes.sm[idx])
		time.sleep(b.timeout)
	}
	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[0].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[0].repeat(b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_expand() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[1].repeat(width / 2 - b.state)}${b.runes.sm[idx]}${b.runes.f[0].repeat(b.state * 2)}${b.runes.s[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[0].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[1].repeat(width / 2 - b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}

fn (b SmoothBar) draw_split() {
	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for idx, _ in b.runes.s {
		eprint('\r${b.border[0]}${b.runes.f[0].repeat(width / 2 - b.state)}${b.runes.sm[idx]}${b.runes.f[1].repeat(b.state * 2)}${b.runes.s[idx]}')
		time.sleep(b.timeout * 2)
	}

	if b.state * 2 >= width {
		finish('${b.border[0]}${b.runes.f[1].repeat(width + 2)}${b.border[1]} ${b.label[1]}')
		return
	}
	eprint('${b.runes.f[0].repeat(width / 2 - b.state)}${b.border[1]} ${b.state * 100 / (width / 2)}% ${b.label[0]}')
}
