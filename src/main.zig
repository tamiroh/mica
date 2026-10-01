const std = @import("std");

// PL011 UART registers on QEMU's AArch64 virt machine.
const uart_data: *volatile u32 = @ptrFromInt(0x09000000);
const uart_flags: *volatile u32 = @ptrFromInt(0x09000018);

fn write(text: []const u8) void {
    for (text) |byte| {
        writeByte(byte);
    }
}

fn writeByte(byte: u8) void {
    // Wait while the transmit FIFO is full (TXFF).
    while (uart_flags.* & (1 << 5) != 0) {
        asm volatile ("yield");
    }
    uart_data.* = byte;
}

fn readByte() u8 {
    // Wait while the receive FIFO is empty (RXFE).
    while (uart_flags.* & (1 << 4) != 0) {
        asm volatile ("yield");
    }
    return @truncate(uart_data.*);
}

export fn kernel_main() callconv(.c) noreturn {
    var line: [128]u8 = undefined;
    var length: usize = 0;
    var previous_was_cr = false;

    write("Hello from mica!\r\nmica> ");
    while (true) {
        const byte = readByte();
        // Treat CRLF as one Enter key, while also accepting CR or LF alone.
        if (byte == '\n' and previous_was_cr) {
            previous_was_cr = false;
            continue;
        }
        previous_was_cr = byte == '\r';

        switch (byte) {
            '\r', '\n' => {
                write("\r\n");
                execute(line[0..length]);
                length = 0;
                write("mica> ");
            },
            0x08, 0x7f => {
                if (length > 0) {
                    length -= 1;
                    write("\x08 \x08");
                }
            },
            0x20...0x7e => {
                if (length < line.len) {
                    line[length] = byte;
                    length += 1;
                    writeByte(byte);
                } else {
                    writeByte(0x07);
                }
            },
            else => {},
        }
    }
}

fn execute(line: []const u8) void {
    const command = std.mem.trim(u8, line, " ");
    if (command.len == 0) return;

    if (std.mem.eql(u8, command, "help")) {
        write("Commands:\r\n  help  Show this help\r\n");
    } else {
        write("Unknown command: ");
        write(command);
        write("\r\nType 'help' for available commands.\r\n");
    }
}

fn halt() noreturn {
    while (true) asm volatile ("wfi");
}

pub fn panic(message: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    write("panic: ");
    write(message);
    write("\r\n");
    halt();
}
