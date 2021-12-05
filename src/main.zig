const std = @import("std");

const PuzzleError = error{
    MissingInput,
    InvalidInput,
    OutOfMemory,
    Unimplemented,
};


fn day1(easy: bool) PuzzleError!u32 {
    var file = std.fs.cwd().openFile("input/day1", .{}) catch return PuzzleError.MissingInput;
    defer file.close();

    var buf: [512]u8 = undefined;
    var reader = file.reader();
    if (easy) {
        var prev: u32 = std.math.maxInt(u32);
        var count_bigger: u32 = 0;
        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            var val: u32 = std.fmt.parseInt(u32, line, 10) catch return PuzzleError.InvalidInput;
            if (val > prev)
                count_bigger += 1;
            prev = val;
        }
        return count_bigger;
    } else {
        var count_bigger: u32 = 0;

        var window = [3]u32{std.math.maxInt(u32), std.math.maxInt(u32), std.math.maxInt(u32) };
        var cur_index: u8 = 0;
        var sum: u64 = @intCast(u64, window[0]) + window[1] + window[2];
        var prev_sum = sum;

        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            sum -= window[cur_index];
            window[cur_index] = std.fmt.parseInt(u32, line, 10) catch return PuzzleError.InvalidInput;
            sum += window[cur_index];
            cur_index = (cur_index + 1) % 3;
            if (sum > prev_sum)
                count_bigger += 1;
            prev_sum = sum;
        }

        return count_bigger;
    }
}

fn day2(easy: bool) PuzzleError!u32 {
    var file = std.fs.cwd().openFile("input/day2", .{}) catch return PuzzleError.MissingInput;
    defer file.close();

    var buf: [512]u8 = undefined;
    var reader = file.reader();

    var horiz: u32 = 0;
    var depth: u32 = 0;
    if (easy) {
        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            const sp: usize = std.mem.indexOfScalar(u8, line, ' ') orelse return PuzzleError.InvalidInput;
            const num: u32 = std.fmt.parseInt(u32, line[sp+1..], 10) catch return PuzzleError.InvalidInput;
            if (std.mem.startsWith(u8, line, "forward")) {
                horiz += num;
            } else if (std.mem.startsWith(u8, line, "up")) {
                depth -= num;
            } else if (std.mem.startsWith(u8, line, "down")) {
                depth += num;
            }
        }
    } else {
        var aim: u32 = 0;
        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            const sp: usize = std.mem.indexOfScalar(u8, line, ' ') orelse return PuzzleError.InvalidInput;
            const num: u32 = std.fmt.parseInt(u32, line[sp+1..], 10) catch return PuzzleError.InvalidInput;
            if (std.mem.startsWith(u8, line, "forward")) {
                horiz += num;
                depth += num * aim;
            } else if (std.mem.startsWith(u8, line, "up")) {
                aim -= num;
            } else if (std.mem.startsWith(u8, line, "down")) {
                aim += num;
            }
        }
    }
    return horiz * depth;
}

fn day3(easy: bool) PuzzleError!u32 {
    return error.Unimplemented;
}

fn day4(easy: bool) PuzzleError!u32 {
    return error.Unimplemented;
}

fn day5(easy: bool) PuzzleError!u32 {
    return error.Unimplemented;
}

const answers = [_]*const fn(bool) PuzzleError!u32{
    &day1,
    &day2,
    &day3,
    &day4,
    &day5,
};

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();

    const args: [][*:0]u8 = std.os.argv;
    if (args.len != 3)
        return error.InvalidArguments;

    const puzzle: u32 = try std.fmt.parseInt(u32, std.mem.span(args[1]), 10);
    const easy: bool = if (std.mem.eql(u8, std.mem.span(args[2]), "easy"))
            true
         else if (std.mem.eql(u8, std.mem.span(args[2]), "hard"))
            false
         else
            return error.InvalidArguments;

    if (puzzle == 0 or puzzle > answers.len)
        return error.InvalidArguments;

    const val: u32 = try answers[puzzle - 1].*(easy);

    const str = if (easy) "easy" else "hard";
    try stdout.print("Answer to day {} ({s}) is: {}\n", .{puzzle, str, val});
}
