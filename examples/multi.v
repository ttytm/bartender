module main

import bartender
import sync
import time
import rand

fn pseudo_dissimilar_progress(mut wg sync.WaitGroup, mut b bartender.Bar) ! {
	rand_num := rand.intn(100) or { panic(err) }
	for _ in 0 .. b.iters {
		b.progress()!
		time.sleep((time.millisecond * rand_num) + (50 * time.millisecond))
	}
	wg.done()
}

fn main() {
	mut b1 := bartender.Bar{
		multi: true
	}
	b1.pre = '1: ['
	mut b2 := b1
	b2.pre = '2: ['
	mut b3 := b1
	b3.pre = '3: ['
	mut bars := [&b1, &b2, &b3]

	mut wg := sync.new_waitgroup()
	for mut b in bars {
		wg.add(1)
		spawn pseudo_dissimilar_progress(mut wg, mut b)
	}
	wg.add(1)
	spawn bars.watch(mut wg)
	wg.wait()
}
