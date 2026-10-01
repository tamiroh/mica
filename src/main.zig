// PL011 UART registers on QEMU's AArch64 virt machine.
const uart_data: *volatile u32 = @ptrFromInt(0x09000000);
const uart_flags: *volatile u32 = @ptrFromInt(0x09000018);

fn write(text: []const u8) void {
    for (text) |byte| {
        while (uart_flags.* & (1 << 5) != 0) {
            asm volatile ("yield");
        }
        uart_data.* = byte;
    }
}

export fn kernel_main() callconv(.c) noreturn {
    write("Hello from mica!\r\n");
    halt();
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
