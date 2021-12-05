const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;

const PuzzleError = error{
    MissingInput,
    InvalidInput,
    OutOfMemory,
    Unimplemented,
    Unexpected,
};

fn day1(easy: bool, allocator: *Allocator) PuzzleError!u32 {
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

        var window = [3]u32{ std.math.maxInt(u32), std.math.maxInt(u32), std.math.maxInt(u32) };
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

fn day2(easy: bool, allocator: *Allocator) PuzzleError!u32 {
    var file = std.fs.cwd().openFile("input/day2", .{}) catch return PuzzleError.MissingInput;
    defer file.close();

    var buf: [512]u8 = undefined;
    var reader = file.reader();

    var horiz: u32 = 0;
    var depth: u32 = 0;
    if (easy) {
        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            const sp: usize = std.mem.indexOfScalar(u8, line, ' ') orelse return PuzzleError.InvalidInput;
            const num: u32 = std.fmt.parseInt(u32, line[sp + 1 ..], 10) catch return PuzzleError.InvalidInput;
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
            const num: u32 = std.fmt.parseInt(u32, line[sp + 1 ..], 10) catch return PuzzleError.InvalidInput;
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

fn day3(easy: bool, allocator: *Allocator) PuzzleError!u32 {
    const digits = 12;

    const most_common_digit = struct {
        fn func(list: std.ArrayList([digits]u8), digit: u8, reverse: bool) u8 {
            var num_1: u32 = 0;
            for (list.items) |value| {
                if (value[digit] == '1') num_1 += 1;
            }
            if (num_1 * 2 >= list.items.len) {
                return if (reverse) '0' else '1';
            } else {
                return if (reverse) '1' else '0';
            }
        }
    }.func;

    const list: std.ArrayList([digits]u8) = blk: {
        var list = std.ArrayList([digits]u8).init(allocator);
        var file = std.fs.cwd().openFile("input/day3", .{}) catch return PuzzleError.MissingInput;
        defer file.close();
        var reader = file.reader();
        var buf: [512]u8 = undefined;
        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            if (line.len != digits) return PuzzleError.InvalidInput;
            list.append(line[0..digits].*) catch return PuzzleError.OutOfMemory;
        }
        //list.resize(10) catch |err| {};
        break :blk list;
    };
    defer list.deinit();

    if (easy) {
        const flip_digits = struct {
            fn func(in: [digits]u8) [digits]u8 {
                var out: [digits]u8 = undefined;
                var i: u8 = 0;
                while (i < digits) : (i += 1) {
                    out[i] = if (in[i] == '0') '1' else '0';
                }
                return out;
            }
        }.func;

        var most_common: [digits]u8 = undefined;
        {
            var i: u8 = 0;
            while (i < digits) : (i += 1) {
                most_common[i] = most_common_digit(list, i, false);
            }
        }
        const gamma_rate: u32 = std.fmt.parseInt(u32, most_common[0..], 2) catch return PuzzleError.Unexpected;
        const epsilon_rate: u32 = std.fmt.parseInt(u32, flip_digits(most_common)[0..], 2) catch return PuzzleError.Unexpected;
        return gamma_rate * epsilon_rate;
    } else {
        var res: u32 = 1;
        for ([_]bool{ false, true }) |most_or_least| {
            var input_copy = std.ArrayList([digits]u8).init(allocator);
            input_copy.appendSlice(list.items) catch return PuzzleError.OutOfMemory;

            var i: u8 = 0;
            while (i < digits) : (i += 1) {
                const keep: u8 = most_common_digit(input_copy, i, most_or_least);
                var j: u32 = 0;
                var culled: u32 = 0;
                while (j < input_copy.items.len) {
                    if (input_copy.items[j][i] == keep) {
                        j += 1;
                    } else {
                        _ = input_copy.swapRemove(j);
                        culled += 1;
                    }
                }
                if (input_copy.items.len <= 1) break;
            }
            if (input_copy.items.len == 1) {
                const measure: u32 = std.fmt.parseInt(u32, input_copy.items[0][0..], 2) catch return PuzzleError.Unexpected;
                res *= measure;
            } else {
                return PuzzleError.Unexpected;
            }
        }
        return res;
    }
}

fn day4(easy: bool, allocator: *Allocator) PuzzleError!u32 {
    return error.Unimplemented;
}

fn day5(easy: bool, allocator: *Allocator) PuzzleError!u32 {
    return error.Unimplemented;
}

const answers = [_]*const fn (bool, *Allocator) PuzzleError!u32{
    &day1,
    &day2,
    &day3,
    &day4,
    &day5,
};

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

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

    const val: u32 = try answers[puzzle - 1].*(easy, &arena.allocator);

    const str = if (easy) "easy" else "hard";
    try stdout.print("Answer to day {} ({s}) is: {}\n", .{ puzzle, str, val });
}
