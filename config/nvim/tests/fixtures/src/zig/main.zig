const std = @import("std");
fn square(x: i32) i32 { return x * x; }
export fn sumSquares(n: i32) i32 {
    var acc: i32 = 0;
    var i: i32 = 0;
    while (i < n) : (i += 1) { acc +%= square(i); }
    return acc;
}
pub fn main() void { std.debug.print("{d}\n", .{sumSquares(10)}); }
