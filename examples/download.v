module main

import bartender
import net.http
import os
import io

struct ProgressReader {
	data string [required]
	size int    [required]
mut:
	progress_bar bartender.SmoothBar
	state        int
	pos          int
}

fn (mut r ProgressReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}
	n := copy(mut buf, r.data[r.pos..].bytes())
	r.pos += n
	if (f64(r.pos) / r.size * r.progress_bar.width) > r.state {
		r.state += 1
		r.progress_bar.progress()
	}
	return n
}

fn main() {
	url := 'https://github.com/vlang/v/releases/latest/download/v_linux.zip'

	temp_output := '.tmp'
	// output := 'v_linux.zip'

	mut resp := http.get(url)!
	if resp.status_code != 200 {
		eprintln('[Error] Status: ${resp.status_code}')
		return
	}
	mut file := os.create(temp_output) or { panic(err) }
	defer {
		file.close()
	}

	data := resp.body
	mut r := io.new_buffered_reader(
		reader: ProgressReader{
			data: data
			size: data.len
			state: 0
			progress_bar: bartender.SmoothBar{
				width: 60
				label: ['Downloading V...', 'Download completed!']!
				border: ['│', '│']!
			}
		}
	)

	io.cp(mut r, mut file)!

	os.rm(temp_output)!
	// os.rename(temp_output, output)!
}
