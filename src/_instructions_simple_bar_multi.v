module bartender

import term

fn (bars []&Bar) draw() bool {
	mut finished := true
	mut formatted := []string{}
	for b in bars {
		formatted << b.format()
		if b.state.pos > 0 && b.state.pos < b.width_ {
			finished = false
		}
	}
	println(formatted.join_lines())
	if !finished {
		term.cursor_up(bars.len)
	}
	return finished
}

fn (bars []&Bar) ensure_mutli() ! {
	mut not_multi := []int{}
	for i, bar in bars {
		if !bar.multi {
			not_multi << i
		}
	}
	if not_multi.len > 0 {
		return IError(BarError{
			kind: .missing_multi
			msg: '${not_multi}'
		})
	}
}
