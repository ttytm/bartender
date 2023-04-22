module main

import bartender
import time

fn main() {
	timeout := time.millisecond * 30

	mut b := bartender.Bar{}
	mut b2 := b
	mut b3 := b

	mut mb := bartender.MultiBar{
		bars: [b, b2, b3]
	}
	for _ in 0 .. b.iters {
		mb.progress()
		time.sleep(timeout)
	}
}
