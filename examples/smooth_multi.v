module main

import bartender { SmoothBar, Theme, ThemeVariant }
import sync
import time
import rand

fn pseudo_dissimilar_progress_(mut wg sync.WaitGroup, mut b SmoothBar) ! {
	rand_num := rand.int_in_range(15, 35) or { 15 }
	sample_num := b.pre.str()[..1].int()
	// Modifier for the sake of this simple example.
	// It adjusts the randomized timeout for the split bar examples (numbers 5 and onward),
	// as they would finish faster using the same linear-time pseudo-progress loop.
	modifier := if sample_num > 4 { 2 } else { 1 }
	timeout := time.millisecond * rand_num * modifier
	for _ in 0 .. b.iters {
		b.progress()!
		time.sleep(timeout)
	}
	wg.done()
}

fn main() {
	mut b1 := SmoothBar{
		post: ''
	}
	b1.pre = '1: '
	mut b2 := b1
	b2.pre = '2: '
	b2.theme = Theme.pull
	mut b3 := b1
	b3.pre = '3: '
	b3.theme = ThemeVariant{.push, .drain}
	mut b4 := b1
	b4.pre = '4: '
	b4.theme = ThemeVariant{.pull, .drain}
	mut b5 := b1
	b5.pre = '5: '
	b5.theme = Theme.expand
	mut b6 := b1
	b6.pre = '6: '
	b6.theme = Theme.split
	mut b7 := b1
	b7.pre = '7: '
	b7.theme = Theme.merge
	mut bars := &[&b1, &b2, &b3, &b4, &b5, &b6, &b7]

	mut wg := sync.new_waitgroup()
	wg.add(1)
	spawn bars.watch(mut wg)
	for mut b in bars {
		wg.add(1)
		spawn pseudo_dissimilar_progress_(mut wg, mut b)
	}
	wg.wait()
}
