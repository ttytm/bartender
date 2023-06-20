module bartender

import io

fn bar_reader(b BarType, reader io.Reader, size u64) &io.BufferedReader {
	return io.new_buffered_reader(
		reader: BarReader{
			bar: b
			reader: reader
			size: size
		}
	)
}

fn (mut br BarReader) read(mut buf []u8) !int {
	n := br.reader.read(mut buf)!
	br.pos += n
	match mut br.bar {
		// Unfortunately, comma separation doesn't work here ATM.
		// SmoothBar won't be visible or will have corrupted chars.
		Bar {
			if (f64(br.pos) / br.size * br.bar.width) > br.bar.state.pos {
				br.bar.progress()!
			}
		}
		SmoothBar {
			if (f64(br.pos) / br.size * br.bar.width) > br.bar.state.pos {
				br.bar.progress()!
			}
		}
	}
	if br.pos >= br.size {
		return io.Eof{}
	}
	return n
}
