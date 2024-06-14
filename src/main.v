module main

import net
import os
import time

struct P2PMsgSession {
mut:
	lpeer     net.UdpConn
	rpeers    []net.Addr
	alias_map map[string]string
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

		if data.len >= 2 {
			res := msg_shell(mut session, shell_fns, data)!
			if res == 1 {
				continue
			}
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

	mut rmsg_shell_m := map[string]RmsgShellFn{}
	rmsg_shell_m['alias-me'] = alias
	rmsg_shell_m['invalid'] = r_invalid
	rmsg_shell_m['error'] = r_shell_error

	for {
		size, rpeer := session.lpeer.read(mut buffer) or { continue }
		text_data := buffer[0..size].clone().bytestr()

		if text_data == '::ignore' {
			continue
		}

		if text_data.len > 2 {
			res := rmsg_shell(mut session, rmsg_shell_m, rpeer, text_data)!
			if res == 1 {
				continue
			}
		}

		mut rpeer_alias := rpeer.str()
		if rpeer_alias in session.alias_map {
			rpeer_alias = session.alias_map[rpeer_alias]
		}

		println('\r${rpeer_alias}|${size} // ${text_data}')
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
