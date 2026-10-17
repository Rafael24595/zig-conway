const std = @import("std");

const zon = @import("build.zig.zon");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_zig_zon = b.createModule(.{
        .root_source_file = b.path("build.zig.zon"),
        .target = target,
        .optimize = optimize,
    });

    build_main(
        b,
        target,
        optimize,
        build_zig_zon,
    );

    build_test(
        b,
        target,
        optimize,
        build_zig_zon,
    );
}

fn build_main(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    build_zig_zon: *std.Build.Module,
) void {
    const exe = b.addExecutable(.{
        .name = "zig_conway",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = target.result.os.tag != .windows,
        }),
    });

    add_build_zig_zon(exe.root_module, build_zig_zon);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}

fn build_test(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    build_zig_zon: *std.Build.Module,
) void {
    const mod = b.createModule(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = target.result.os.tag != .windows,
    });

    add_build_zig_zon(mod, build_zig_zon);

    const tests = b.addTest(.{
        .root_module = mod,
    });

    const test_step = b.step("test", "Run tests");
    const run_tests = b.addRunArtifact(tests);

    test_step.dependOn(&run_tests.step);
}

fn add_build_zig_zon(
    mod: *std.Build.Module,
    build_zig_zon: *std.Build.Module,
) void {
    mod.addImport("build.zig.zon", build_zig_zon);
}
