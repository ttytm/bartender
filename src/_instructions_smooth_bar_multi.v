module bartender

import term
import time
import sync

fn (bars []&SmoothBar) draw() bool {
	mut finished := true
	mut formatted := []string{}
	for b in bars {
		formatted << b.format()
		if b.state.pos < b.width_ {
			finished = false
		}
	}
	println(formatted.join_lines())
	if !finished {
		term.cursor_up(bars.len)
	}
	return finished
}

// A function that takes a sumtype arg []&Bar | []&SmoothBar would more concice, but won't work atm.
fn (bars []&SmoothBar) ensure_mutli() ! {
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

// Functions for exposure.

pub fn (bars []&SmoothBar) watch_(mut wg sync.WaitGroup) {
	// NOTE: Same function for Bars and SmoothBars. Re-check with Vlangs progression if this can be solved with a sumtype.
	bars.ensure_mutli() or {
		eprintln(err)
		exit(0)
	}
	for {
		if bars.draw() {
			term.show_cursor()
			break
		}
		// Slow redraw loop to reduce load.
		time.sleep(time.millisecond * 5)
	}
	wg.done()
}
