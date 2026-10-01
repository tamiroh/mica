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
    write("Hello from mica!\r\nmica> ");
    while (true) {
        switch (readByte()) {
            '\r', '\n' => write("\r\nmica> "),
            else => |byte| writeByte(byte),
        }
    }
}

fn halt() noreturn {
    while (true) asm volatile ("wfi");
}

pub fn panic(message: []const u8, _: ?*@import("std").builtin.StackTrace, _: ?usize) noreturn {
    write("panic: ");
    write(message);
    write("\r\n");
    halt();
}
