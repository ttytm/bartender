module main

import time
import term { colorize, hide_cursor, show_cursor }

struct Bar {
	width int = 79
	label ?string
	shade bool
}

enum Stream {
	fill
	drain
}

const (
	smooth_ltr = [` `, `▏`, `▎`, `▍`, `▌`, `▋`, `▊`, `▉`, `█`]
	smooth_rtl = [`█`, `🮋`, `🮊`, `🮉`, `▐`, `🮈`, `🮇`, `▕`, ` `]
	delimeters = [`█`, ` `] // runes used for progress and remaining space
	timeout_ms = 2
)

fn (b Bar) push(stream Stream) {
	mut dlm := if stream == .fill { delimeters } else { delimeters.reverse() }
	mut smooth_runes := if stream == .fill { smooth_ltr } else { smooth_rtl }
	label := b.label or { 'Push ${stream.str().title()}' }

	if b.shade {
		if stream == .fill {
			smooth_runes[0] = `░`
			dlm[1] = `░`
		} else {
			smooth_runes[smooth_runes.len - 1] = `░`
			dlm[0] = `░`
		}
	}

	for i in 1 .. b.width + 1 {
		for r in smooth_runes {
			eprint(`\r`)
			eprint(dlm[0].repeat(i))
			eprint(r)
			time.sleep(timeout_ms * time.millisecond)
		}
		eprint(dlm[1].repeat(b.width - i))
		eprint(' ${i * 100 / b.width}% ${label}')
	}
	println('')
}

fn (b Bar) pull(stream Stream) {
	dlm := if stream == .fill { delimeters.reverse() } else { delimeters }
	smooth_runes := if stream == .fill { smooth_rtl.reverse() } else { smooth_ltr.reverse() }
	label := b.label or { 'Pull ${stream.str().title()}' }

	for i in 1 .. b.width + 1 {
		for r in smooth_runes {
			eprint(`\r`)
			eprint(dlm[0].repeat(b.width - i))
			eprint(r)
			time.sleep(timeout_ms * time.millisecond)
		}
		eprint(dlm[1].repeat(i))
		eprint(' ${i * 100 / b.width}% ${label}')
	}
	println('')
}

fn (b Bar) merge() {
	color := term.cyan
	mut dlms := []string{}
	for dlm in delimeters {
		dlms << colorize(color, dlm.str())
	}
	mut smooth_runes := []string{}
	for rn in smooth_ltr {
		smooth_runes << colorize(color, rn.str())
	}
	mut smooth_runes_reverse := []string{}
	for rn in smooth_rtl.reverse() {
		smooth_runes_reverse << colorize(color, rn.str())
	}
	block := colorize(color, delimeters[0].str())
	label := b.label or { 'Merge' }

	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for i in 0 .. width {
		if width - i * 2 <= -2 {
			break
		}
		for idx, _ in smooth_runes {
			eprint(`\r`)
			eprint(dlms[0].repeat(i))
			eprint(smooth_runes[idx])
			if width - i * 2 >= 0 {
				eprint(dlms[1].repeat(width - i * 2))
			} else {
				eprint(block)
			}

			eprint(smooth_runes_reverse[idx])
			time.sleep(timeout_ms * 2 * time.millisecond)
		}
		eprint(dlms[0].repeat(i))
		eprint(' ${i * 100 / (width / 2)}% ${label}')
	}
	println('')
}

fn (b Bar) expand() {
	color := term.bright_black
	mut dlms := []string{}
	for dlm in delimeters {
		dlms << colorize(color, dlm.str())
	}
	mut smooth_runes := []string{}
	for rn in smooth_ltr {
		smooth_runes << colorize(color, rn.str())
	}
	mut smooth_runes_reverse := []string{}
	for rn in smooth_rtl.reverse() {
		smooth_runes_reverse << colorize(color, rn.str())
	}
	block := colorize(color, delimeters[0].str())
	label := b.label or { 'Expand' }

	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for i in 0 .. width {
		if i * 2 >= width + 2 {
			break
		}
		for idx, _ in smooth_runes {
			eprint(`\r`)
			eprint(dlms[1].repeat(width / 2 - i))
			eprint(smooth_runes_reverse[idx])
			eprint(block.repeat(i * 2))
			eprint(smooth_runes[idx])
			time.sleep(timeout_ms * 2 * time.millisecond)
		}

		eprint(dlms[1].repeat(width / 2 - i))
		eprint(' ${i * 100 / (width / 2)}% ${label}')
	}
	println('')
}

fn (b Bar) split() {
	color := term.yellow
	mut dlms := []string{}
	for dlm in delimeters {
		dlms << colorize(color, dlm.str())
	}
	mut smooth_runes := []string{}
	for rn in smooth_rtl {
		smooth_runes << colorize(color, rn.str())
	}
	mut smooth_runes_reverse := []string{}
	for rn in smooth_ltr.reverse() {
		smooth_runes_reverse << colorize(color, rn.str())
	}
	label := b.label or { 'Split' }

	width := if b.width % 2 != 0 { b.width - 1 } else { b.width }
	for i in 0 .. width {
		if i * 2 >= width + 2 {
			break
		}
		for idx, _ in smooth_runes {
			eprint(`\r`)
			eprint(dlms[0].repeat(width / 2 - i))
			eprint(smooth_runes_reverse[idx])
			eprint(dlms[1].repeat(i * 2))
			eprint(smooth_runes[idx])
			time.sleep(timeout_ms * 2 * time.millisecond)
		}

		eprint(dlms[0].repeat(width / 2 - i))
		eprint(' ${i * 100 / (width / 2)}% ${label}')
	}
	println('')
}

fn main() {
	b := Bar{}
	// b2 := Bar{
	// 	shade: true
	// }

	hide_cursor()

	b.push(.fill)
	// b2.push(.fill) // though shading is only handled in this struct and method, funnily all following include shading
	b.pull(.fill)
	b.push(.drain)
	b.pull(.drain)
	b.merge()
	b.expand()
	b.split()

	show_cursor()
}
