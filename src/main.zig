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
        fn func(list: [][digits]u8, digit: u8, reverse: bool) u8 {
            var num_1: u32 = 0;
            for (list) |value| {
                if (value[digit] == '1') num_1 += 1;
            }
            if (num_1 * 2 >= list.len) {
                return if (reverse) '0' else '1';
            } else {
                return if (reverse) '1' else '0';
            }
        }
    }.func;

    const input: [][digits]u8 = blk: {
        var input = std.ArrayList([digits]u8).init(allocator);
        var file = std.fs.cwd().openFile("input/day3", .{}) catch return PuzzleError.MissingInput;
        defer file.close();
        var reader = file.reader();
        var buf: [512]u8 = undefined;
        while (reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput) |line| {
            if (line.len != digits) return PuzzleError.InvalidInput;
            input.append(line[0..digits].*) catch return PuzzleError.OutOfMemory;
        }
        break :blk input.toOwnedSlice();
    };
    defer allocator.free(input);

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
                most_common[i] = most_common_digit(input, i, false);
            }
        }
        const gamma_rate: u32 = std.fmt.parseInt(u32, most_common[0..], 2) catch return PuzzleError.Unexpected;
        const epsilon_rate: u32 = std.fmt.parseInt(u32, flip_digits(most_common)[0..], 2) catch return PuzzleError.Unexpected;
        return gamma_rate * epsilon_rate;
    } else {
        var res: u32 = 1;
        for ([_]bool{ false, true }) |most_or_least| {
            var input_copy = std.ArrayList([digits]u8).init(allocator);
            input_copy.appendSlice(input) catch return PuzzleError.OutOfMemory;

            var i: u8 = 0;
            while (i < digits) : (i += 1) {
                const keep: u8 = most_common_digit(input_copy.items, i, most_or_least);
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
    const board_size = 5;
    const Board = struct {
        values: [board_size][board_size]?u32,
        won: bool = false,
    };

    var input_numbers = std.ArrayList(u32).init(allocator);
    defer input_numbers.deinit();
    var boards = std.ArrayList(Board).init(allocator);
    defer boards.deinit();
    {
        var file = std.fs.cwd().openFile("input/day4", .{}) catch return PuzzleError.MissingInput;
        defer file.close();
        var reader = file.reader();
        var buf: [1024]u8 = undefined;

        {
            const first_line = reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput;
            if (first_line == null) return PuzzleError.InvalidInput;

            var it = std.mem.split(first_line.?, ",");
            while (it.next()) |numstr| {
                const number: u32 = std.fmt.parseInt(u32, numstr, 10) catch return PuzzleError.InvalidInput;
                input_numbers.append(number) catch return PuzzleError.InvalidInput;
            }
        }

        while (true) {
            const empty_line = reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput;
            if (empty_line == null) break;

            boards.append(undefined) catch return PuzzleError.OutOfMemory;
            var row: u8 = 0;
            while (row < board_size) : (row += 1) {
                const line = reader.readUntilDelimiterOrEof(&buf, '\n') catch return PuzzleError.InvalidInput;
                if (line == null) return PuzzleError.InvalidInput;
                var it = std.mem.tokenize(line.?, " ");
                var col: u8 = 0;
                while (it.next()) |numstr| {
                    if (col >= 5) return PuzzleError.InvalidInput;
                    const number: u32 = std.fmt.parseInt(u32, numstr, 10) catch {
                        return PuzzleError.InvalidInput;
                    };
                    boards.items[boards.items.len - 1].values[row][col] = number;
                    col += 1;
                }
                if (col < 5) return PuzzleError.InvalidInput;
            }
        }

        if (input_numbers.items.len == 0 or boards.items.len == 0) return PuzzleError.InvalidInput;
    }

    const Coord = struct { row: u8, col: u8 };
    const get_coord = struct {
        fn func(value: u32, board: Board) ?Coord {
            var row: u8 = 0;
            while (row < board_size) : (row += 1) {
                var col: u8 = 0;
                while (col < board_size) : (col += 1) {
                    if (board.values[row][col] == value)
                        return Coord{ .row = row, .col = col };
                }
            }
            return null;
        }
    }.func;
    const check_winning = struct {
        fn func(board: Board, coord: Coord) bool {
            var row: u8 = 0;
            while (row < board_size) : (row += 1) {
                if (board.values[row][coord.col] != null)
                    break;
            } else return true;
            var col: u8 = 0;
            while (col < board_size) : (col += 1) {
                if (board.values[coord.row][col] != null)
                    break;
            } else return true;
            return false;
        }
    }.func;
    const get_unmarked_sum = struct {
        fn func(board: Board) u32 {
            var sum: u32 = 0;
            var row: u8 = 0;
            while (row < board_size) : (row += 1) {
                var col: u8 = 0;
                while (col < board_size) : (col += 1) {
                    if (board.values[row][col]) |val|
                        sum += val;
                }
            }
            return sum;
        }
    }.func;

    if (easy) {
        for (input_numbers.items) |number| {
            for (boards.items) |_, board_num| {
                var board = &boards.items[board_num];
                if (get_coord(number, board.*)) |coord| {
                    board.*.values[coord.row][coord.col] = null;
                    if (check_winning(board.*, coord)) {
                        return get_unmarked_sum(board.*) * number;
                    }
                }
            }
        }
        return error.InvalidInput;
    } else {
        var last_score: ?u32 = null;
        for (input_numbers.items) |number| {
            for (boards.items) |_, board_num| {
                var board = &boards.items[board_num];
                if (board.*.won) continue;
                if (get_coord(number, board.*)) |coord| {
                    board.*.values[coord.row][coord.col] = null;
                    if (check_winning(board.*, coord)) {
                        board.*.won = true;
                        last_score = get_unmarked_sum(board.*) * number;
                    }
                }
            }
        }
        return last_score orelse error.InvalidInput;
    }
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
