module main

import bartender
import net.http
import os
import io

struct ProgressReader {
	data []u8 [required]
	size int  [required]
mut:
	progress_bar bartender.SmoothBar
	state        int
	pos          int
}

fn (mut r ProgressReader) read(mut buf []u8) !int {
	if r.pos >= r.size {
		return io.Eof{}
	}
	max_bytes := 3200
	end := if r.pos + max_bytes >= r.size { r.size } else { r.pos + max_bytes }
	n := copy(mut buf, r.data[r.pos..end])
	r.pos += n
	if (f64(r.pos) / r.size * r.progress_bar.width) > r.state {
		r.state += 1
		r.progress_bar.progress()
	}
	return n
}

fn create_reader(data []u8) !&io.BufferedReader {
	return io.new_buffered_reader(
		reader: ProgressReader{
			data: data
			size: data.len
			state: 0
			progress_bar: bartender.SmoothBar{
				width: 60
				label: ['Downloading...', 'Download completed!']!
				border: ['│', '│']!
			}
		}
	)
}

fn main() {
	file_path := 'v_linux.zip'
	url := 'https://github.com/vlang/v/releases/latest/download/v_linux.zip'

	mut resp := http.get(url)!
	if resp.status_code != 200 {
		eprintln('[Error] Download failed with statuscode: ${resp.status_code}')
		exit
	}

	mut file := os.create(file_path) or { panic(err) }
	mut r := create_reader(resp.body.bytes()) or { panic(err) }

	io.cp(mut r, mut file) or { panic(err) }
	os.rm(file_path) or { panic(err) }
}
