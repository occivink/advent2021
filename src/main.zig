const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;

fn day1(easy: bool, allocator: *Allocator) !u64 {
    var file = try std.fs.cwd().openFile("input/day1", .{});
    defer file.close();

    var buf: [512]u8 = undefined;
    var reader = file.reader();

    var count_bigger: u32 = 0;
    if (easy) {
        var prev: u32 = std.math.maxInt(u32);
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var val: u32 = try std.fmt.parseInt(u32, line, 10);
            if (val > prev)
                count_bigger += 1;
            prev = val;
        }
    } else {
        var window = [3]u32{ std.math.maxInt(u32), std.math.maxInt(u32), std.math.maxInt(u32) };
        var cur_index: u8 = 0;
        var sum: u64 = @intCast(u64, window[0]) + window[1] + window[2];
        var prev_sum = sum;

        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            sum -= window[cur_index];
            window[cur_index] = try std.fmt.parseInt(u32, line, 10);
            sum += window[cur_index];
            cur_index = (cur_index + 1) % 3;
            if (sum > prev_sum)
                count_bigger += 1;
            prev_sum = sum;
        }

    }
    return count_bigger;
}

fn day2(easy: bool, allocator: *Allocator) !u64 {
    var file = try std.fs.cwd().openFile("input/day2", .{});
    defer file.close();

    var buf: [512]u8 = undefined;
    var reader = file.reader();

    var horiz: u32 = 0;
    var depth: u32 = 0;
    if (easy) {
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const sp: usize = std.mem.indexOfScalar(u8, line, ' ') orelse return error.Unexpected;
            const num: u32 = try std.fmt.parseInt(u32, line[sp + 1 ..], 10);
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
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const sp: usize = std.mem.indexOfScalar(u8, line, ' ') orelse return error.Unexpected;
            const num: u32 = try std.fmt.parseInt(u32, line[sp + 1 ..], 10);
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

fn day3(easy: bool, allocator: *Allocator) !u64 {
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
        var file = try std.fs.cwd().openFile("input/day3", .{});
        defer file.close();
        var reader = file.reader();
        var buf: [512]u8 = undefined;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            if (line.len != digits) return error.InvalidArguments;
            try input.append(line[0..digits].*);
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
        const gamma_rate: u32 = try std.fmt.parseInt(u32, most_common[0..], 2);
        const epsilon_rate: u32 = try std.fmt.parseInt(u32, flip_digits(most_common)[0..], 2);
        return gamma_rate * epsilon_rate;
    } else {
        var res: u32 = 1;
        for ([_]bool{ false, true }) |most_or_least| {
            var input_copy = std.ArrayList([digits]u8).init(allocator);
            try input_copy.appendSlice(input);

            var i: u8 = 0;
            while (i < digits) : (i += 1) {
                const keep: u8 = most_common_digit(input_copy.items, i, most_or_least);
                var j: u32 = 0;
                while (j < input_copy.items.len) {
                    if (input_copy.items[j][i] == keep) {
                        j += 1;
                    } else {
                        _ = input_copy.swapRemove(j);
                    }
                }
                if (input_copy.items.len <= 1) break;
            }
            if (input_copy.items.len == 1) {
                const measure: u32 = try std.fmt.parseInt(u32, input_copy.items[0][0..], 2);
                res *= measure;
            } else {
                return error.Unexpected;
            }
        }
        return res;
    }
}

fn day4(easy: bool, allocator: *Allocator) !u64 {
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
        var file = try std.fs.cwd().openFile("input/day4", .{});
        defer file.close();
        var reader = file.reader();
        var buf: [1024]u8 = undefined;

        {
            const first_line = try reader.readUntilDelimiterOrEof(&buf, '\n');
            if (first_line == null) return error.Unexpected;

            var it = std.mem.split(first_line.?, ",");
            while (it.next()) |numstr| {
                const number: u32 = try std.fmt.parseInt(u32, numstr, 10);
                try input_numbers.append(number);
            }
        }

        while (true) {
            const empty_line = try reader.readUntilDelimiterOrEof(&buf, '\n');
            if (empty_line == null) break;

            try boards.append(undefined);
            var row: u8 = 0;
            while (row < board_size) : (row += 1) {
                const line = try reader.readUntilDelimiterOrEof(&buf, '\n');
                if (line == null) return error.Unexpected;
                var it = std.mem.tokenize(line.?, " ");
                var col: u8 = 0;
                while (it.next()) |numstr| {
                    if (col >= 5) return error.Unexpected;
                    const number: u32 = try std.fmt.parseInt(u32, numstr, 10);
                    boards.items[boards.items.len - 1].values[row][col] = number;
                    col += 1;
                }
                if (col < 5) return error.Unexpected;
            }
        }

        if (input_numbers.items.len == 0 or boards.items.len == 0) return error.Unexpected;
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
            for (boards.items) |*board| {
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
            for (boards.items) |*board| {
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

fn day5(easy: bool, allocator: *Allocator) !u64 {
    const Coord = struct { row: u16, col: u16 };
    const Line = struct { from: Coord, to: Coord };

    var lines = std.ArrayList(Line).init(allocator);
    defer lines.deinit();
    var rows: u16 = 0;
    var columns: u16 = 0;

    {
        var file = try std.fs.cwd().openFile("input/day5", .{});
        defer file.close();
        var reader = file.reader();
        var buf: [1024]u8 = undefined;

        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |input_line| {
            var lineIt = std.mem.split(input_line, " -> ");
            const parseCoord = struct {
                fn func(str: []const u8) !Coord {
                    var coordIt = std.mem.split(str, ",");
                    var ret: Coord = undefined;
                    ret.row = try std.fmt.parseInt(u16, coordIt.next() orelse "", 10);
                    ret.col = try std.fmt.parseInt(u16, coordIt.next() orelse "", 10);
                    return ret;
                }
            }.func;
            try lines.append(undefined);
            var line = &lines.items[lines.items.len - 1];
            if (lineIt.next()) |lhs| {
                line.*.from = try parseCoord(lhs);
            } else return error.Unexpected;
            if (lineIt.next()) |rhs| {
                line.*.to = try parseCoord(rhs);
            } else return error.Unexpected;
            if (lineIt.next() != null) return error.Unexpected;
            rows = std.math.max3(rows, line.from.row, line.to.row);
            columns = std.math.max3(columns, line.from.col, line.to.col);
        }
    }
    rows += 1;
    columns += 1;

    var floor = std.ArrayList(u8).init(allocator);
    defer floor.deinit();
    try floor.appendNTimes(0, @as(u32, columns) * rows);

    for (lines.items) |line| {
        if (line.from.row == line.to.row) {
            const row = line.from.row;
            const min_col = std.math.min(line.from.col, line.to.col);
            const max_col = std.math.max(line.from.col, line.to.col);
            var col = min_col;
            while (col <= max_col) : (col += 1) {
                floor.items[@as(u32, row) * columns + col] += 1;
            }
        } else if (line.from.col == line.to.col) {
            const col = line.from.col;
            const min_row = std.math.min(line.from.row, line.to.row);
            const max_row = std.math.max(line.from.row, line.to.row);
            var row = min_row;
            while (row <= max_row) : (row += 1) {
                floor.items[@as(u32, row) * columns + col] += 1;
            }
        } else if (easy) {
            continue;
        } else {
            const diffRow = std.math.absInt(@as(i32, line.from.row) - @as(i32, line.to.row)) catch unreachable;
            const diffCol = std.math.absInt(@as(i32, line.from.col) - @as(i32, line.to.col)) catch unreachable;
            if (diffRow != diffCol) return error.Unexpected;

            const first_by_row = if (line.from.row < line.to.row) line.from else line.to;
            const second_by_row = if (line.from.row < line.to.row) line.to else line.from;
            const flipped = first_by_row.col > second_by_row.col;
            // not flipped, like this
            // \
            //  \
            //   \
            // flipped, like that
            //   /
            //  /
            // /
            var diff = second_by_row.row - first_by_row.row;
            var count: u16 = 0;
            var row = first_by_row.row;
            var col = first_by_row.col;
            while (count <= diff) : (count += 1) {
                floor.items[@as(u32, row) * columns + col] += 1;
                row += 1;
                if (flipped) {
                    col -= 1;
                } else {
                    col += 1;
                }
            }
        }
    }
    var atLeast2: u32 = 0;
    for (floor.items) |value| {
        if (value >= 2) atLeast2 += 1;
    }
    return atLeast2;
}

fn day6(easy: bool, allocator: *Allocator) !u64 {
    var fishies = [_]u64{0} ** 9;
    {
        var file = try std.fs.cwd().openFile("input/day6", .{});
        defer file.close();
        var reader = file.reader();
        var buf: [1024]u8 = undefined;

        var line = try reader.readUntilDelimiterOrEof(&buf, '\n');
        if (line == null) return error.InvalidInput;
        var it = std.mem.split(line.?, ",");
        while (it.next()) |numstr| {
            const num = try std.fmt.parseInt(u8, numstr, 10);
            if (num >= fishies.len) return error.InvalidInput;
            fishies[num] += 1;
        }
    }
    var days: u32 = if (easy) 80 else 256;
    while (days > 0) : (days -= 1) {
        std.mem.rotate(u64, fishies[0..], 1);
        fishies[6] += fishies[8];
    }
    var sum: u64 = 0;
    for (fishies) |fish| { sum += fish; }
    return sum;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var allocator = std.heap.GeneralPurposeAllocator(.{}){};

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

    const val = switch (puzzle) {
        1 => day1(easy, &allocator.allocator),
        2 => day2(easy, &allocator.allocator),
        3 => day3(easy, &allocator.allocator),
        4 => day4(easy, &allocator.allocator),
        5 => day5(easy, &allocator.allocator),
        6 => day6(easy, &allocator.allocator),
        else => return error.InvalidArguments,
    };

    const str = if (easy) "easy" else "hard";
    try stdout.print("Answer to day {} ({s}) is: {}\n", .{ puzzle, str, val });
}
