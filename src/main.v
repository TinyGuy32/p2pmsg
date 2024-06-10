module main

import net
import os
import time

struct P2PMsgSession {
mut:
	lpeer  net.UdpConn
	rpeers []net.Addr
}

fn main() {
	if os.args.len != 2 {
		eprintln('to few args')
		exit(1)
	}

	mut session := &P2PMsgSession{
		lpeer: net.listen_udp(os.args[1])!
		rpeers: []net.Addr{}
	}

	spawn recv(mut session)
	spawn keep_alive(mut session)

	println('Awaiting data')

	text_input(mut session)!
}

fn text_input(mut session P2PMsgSession) ! {
	for {
		print('> ')
		data := os.get_line()

		// make all messages starting with '//' be remaped to a function in shell_fns
		mut shell_fns := map[string]ShellFn{}
		shell_fns['add'] = add

		// put in a function called 'msg_shell'
		if data[0..2] == '//' {
			mut shell_str := data[2..data.len].clone()

			shell_args := shell_str.split(' ')

			shell_action := shell_fns[shell_args[0]] or {
				eprintln('invallid command')
				continue
			}
			shell_action(mut session, shell_args) or {
				eprintln('${err}')
				exit(1)
			}
			continue
		}

		for rpeer in session.rpeers {
			session.lpeer.write_to_string(rpeer, data) or {
				eprintln('failed to send data to ${rpeer}')
				continue
			}
		}
	}
}

fn recv(mut session P2PMsgSession) ! {
	mut buffer := []u8{len: 1024}
	for {
		size, rpeer := session.lpeer.read(mut buffer) or { continue }
		text_data := buffer[0..size].clone().bytestr()

		if text_data == '::ignore' {
			continue
		}

		println('\r${rpeer}|${size} // ${text_data}')
		print('> ')
	}
}

fn keep_alive(mut session P2PMsgSession) ! {
	for {
		for rpeer in session.rpeers {
			session.lpeer.write_to_string(rpeer, '::ignore') or {
				eprintln('keepalive fail')
				continue
			}
		}
		time.sleep(1_000_000_000 * 0.65)
	}
}
