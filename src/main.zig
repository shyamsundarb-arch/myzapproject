const std = @import("std");
const zap = @import("zap");
const UserEndpoints = @import("userendpoints.zig");

fn on_request(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    var allocator = gpa.allocator();
    // Scoped, so that memory leak, if any can be detected later
    {
        var listener = zap.Endpoint.Listener.init(
            allocator,
            .{
                .port = 3000,
                .on_request = on_request,
                .log = true,
                .max_clients = 100000,
                .max_body_size = 100 * 1024 * 1024,
            },
        );
        defer listener.deinit();
        var userendpoints = UserEndpoints.init(allocator, "/users");
        defer userendpoints.deinit();

        try listener.register(userendpoints.endpoint());

        try listener.listen();

        std.debug.print("Listening on 0.0.0.0:3000\n", .{});

        // start worker threads
        zap.start(.{
            .threads = 1,
            .workers = 2,
        });
    }
    // show potential memory leaks when ZAP is shut down
    const has_leaked = gpa.detectLeaks();
    std.log.debug("Has leaked: {}\n", .{has_leaked});
}
