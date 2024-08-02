const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "Ball-Lightning",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        // .use_lld = optimize != .Debug,
        // .use_llvm = optimize != .Debug,
    });
    @import("system_sdk").addLibraryPathsTo(exe);

    const zglfw_dep = b.dependency("zglfw", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("zglfw", zglfw_dep.module("root"));
    exe.linkLibrary(zglfw_dep.artifact("glfw"));

    const zjobs_dep = b.dependency("zjobs", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("zjobs", zjobs_dep.module("root"));

    const zflecs_dep = b.dependency("zflecs", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("zflecs", zflecs_dep.module("root"));
    exe.linkLibrary(zflecs_dep.artifact("flecs"));

    @import("zgpu").addLibraryPathsTo(exe);
    const zgpu_dep = b.dependency("zgpu", .{
        .target = target,
        .optimize = optimize,
        .dawn_skip_validation = false,
    });
    exe.root_module.addImport("zgpu", zgpu_dep.module("root"));
    exe.linkLibrary(zgpu_dep.artifact("zdawn"));

    const zmath_dep = b.dependency("zmath", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("zmath", zmath_dep.module("root"));

    const zigimg_dep = b.dependency("zigimg", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("img", zigimg_dep.module("zigimg"));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
