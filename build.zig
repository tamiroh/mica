const std = @import("std");

pub fn build(b: *std.Build) void {
    const kernel = b.addExecutable(.{
        .name = "mica",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(.{
                .cpu_arch = .aarch64,
                .os_tag = .freestanding,
                .abi = .none,
                // With the MMU off, memory accesses must be naturally aligned.
                .cpu_features_add = std.Target.aarch64.featureSet(&.{.strict_align}),
                .cpu_features_sub = std.Target.aarch64.featureSet(&.{ .fp_armv8, .neon }),
            }),
            .optimize = b.standardOptimizeOption(.{}),
            .single_threaded = true,
            .stack_protector = false,
        }),
    });
    kernel.root_module.addAssemblyFile(b.path("src/boot.S"));
    kernel.setLinkerScript(b.path("linker.ld"));
    kernel.entry = .{ .symbol_name = "_start" };
    b.installArtifact(kernel);

    const run = b.addSystemCommand(&.{
        "qemu-system-aarch64",
        "-machine",
        "virt",
        "-cpu",
        "cortex-a53",
        "-m",
        "128M",
        "-smp",
        "1",
        "-nographic",
        "-nic",
        "none",
        "-kernel",
    });
    run.addArtifactArg(kernel);
    b.step("run", "Boot mica in QEMU (Ctrl-A, X to exit)").dependOn(&run.step);
}
