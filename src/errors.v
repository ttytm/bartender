module bartender

struct BarError {
	Error
	kind ErrorKind
	val  string
}

enum ErrorKind {
	already_finished
	delay_exceeded
	missing_multi
}

fn (err BarError) msg() string {
	return match err.kind {
		.already_finished { 'Trying to progress already finished bar.' }
		.delay_exceeded { 'Delay cannot exceed 100%.' }
		.missing_multi { 'Failed drawing bars. []&Bar indices not set as multi: ${err.val}' }
	}
}

fn bar_error(kind ErrorKind, val ?string) IError {
	return IError(BarError{
		kind: kind
		val:  val or { '' }
	})
}
