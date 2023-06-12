module bartender

import io

const buf_max_len = 1024

fn bar_reader_(b BarType, bytes []u8) &io.BufferedReader {
	return match b {
		Bar {
			io.new_buffered_reader(
				reader: BarReader{
					bytes: bytes
					size: bytes.len
					bar: b
				}
			)
		}
		SmoothBar {
			io.new_buffered_reader(
				reader: SmoothBarReader{
					bytes: bytes
					size: bytes.len
					bar: b
				}
			)
		}
	}
}

fn get_buf_end(r BarReaderType) int {
	return if r.pos + bartender.buf_max_len >= r.size {
		r.size
	} else {
		r.pos + bartender.buf_max_len
	}
}

fn (mut r BarReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}

	n := copy(mut buf, r.bytes[r.pos..get_buf_end(r)])
	r.pos += n

	if (f64(r.pos) / r.size * r.bar.width) > r.bar.pos() {
		r.bar.progress()
	}

	return n
}

fn (mut r SmoothBarReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}

	n := copy(mut buf, r.bytes[r.pos..get_buf_end(r)])
	r.pos += n

	if (f64(r.pos) / r.size * r.bar.width) > r.bar.pos() {
		r.bar.progress()
	}

	return n
}
