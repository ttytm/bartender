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
