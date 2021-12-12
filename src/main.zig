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
    for (fishies) |fish| {
        sum += fish;
    }
    return sum;
}

fn day7(easy: bool, allocator: *Allocator) !u64 {
    var file = try std.fs.cwd().openFile("input/day7", .{});
    defer file.close();

    var number_list = std.ArrayList(u16).init(allocator);
    defer number_list.deinit();

    var reader = file.reader();
    var numbuf: [8]u8 = undefined;
    var size: u8 = 0;
    while (true) {
        const byte = reader.readByte() catch break;
        switch (byte) {
            ',', '\n' => {
                try number_list.append(try std.fmt.parseInt(u16, numbuf[0..size], 10));
                size = 0;
            },
            else => {
                if (size == numbuf.len) return error.InvalidInput;
                numbuf[size] = byte;
                size += 1;
            },
        }
    }

    if (easy) {
        std.sort.sort(u16, number_list.items, {}, comptime std.sort.asc(u16));
        const items = number_list.items;
        var median: u16 = undefined;
        if (items.len % 2 == 1)
            median = items[items.len / 2]
        else {
            var medf = @intToFloat(f32, items[items.len / 2 - 1] + items[items.len / 2]) / 2.0;
            median = @floatToInt(u16, std.math.round(medf));
        }
        var total: u32 = 0;
        for (items) |number| {
            total += if (number > median) number - median else median - number;
        }
        return total;
    } else {
        // not clear what the solution is, fuck it let's brute force
        var max: u16 = std.mem.max(u16, number_list.items);
        var min: u16 = std.mem.min(u16, number_list.items);

        var minSum: u32 = std.math.maxInt(u32);
        var i = min;
        while (i <= max) : (i += 1) {
            var sum: u32 = 0;
            for (number_list.items) |number| {
                const dist: u32 = if (number > i) number - i else i - number;
                sum += dist * (dist + 1) / 2;
            }
            minSum = std.math.min(minSum, sum);
        }
        return minSum;
    }
}

fn day8(easy: bool, allocator: *Allocator) !u64 {
    //   a
    //  b c
    //   d
    //  e f
    //   g

    var file = try std.fs.cwd().openFile("input/day8", .{});
    defer file.close();
    var reader = file.reader();
    var buf: [128]u8 = undefined;

    //var input: [9][7]u8
    //while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    return error.Unimplemented;
}

fn day9(easy: bool, allocator: *Allocator) !u64 {
    const get_coord = struct {
        fn func(row: u8, col: u8, columns: u8) usize {
            return @intCast(usize, row) * columns + col;
        }
    }.func;
    const height_at = struct {
        fn func(heightmap: []u4, row: u8, col: u8, columns: u8) u4 {
            return heightmap[get_coord(row, col, columns)];
        }
    }.func;

    var heightmap = std.ArrayList(u4).init(allocator);
    defer heightmap.deinit();
    var rows: u8 = 0;
    var columns: u8 = 0;

    // encircle the heightmap with '9' so that we don't have to special case the edges
    var file = try std.fs.cwd().openFile("input/day9", .{});
    defer file.close();
    var reader = file.reader();
    var buf: [128]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (heightmap.items.len == 0) {
            if ((line.len + 2) > std.math.maxInt(u8)) return error.InvalidInput;
            columns = @intCast(u8, (line.len + 2));
            try heightmap.appendNTimes(9, columns);
            rows += 1;
        } else if ((line.len + 2) != columns) {
            return error.InvalidInput;
        }
        try heightmap.append(9);
        var i: u8 = 0;
        while (i < line.len) : (i += 1) {
            try heightmap.append(try std.fmt.parseInt(u4, line[i .. i + 1], 10));
        }
        rows += 1;
        try heightmap.append(9);
    }
    try heightmap.appendNTimes(9, columns);
    rows += 1;

    if (easy) {
        var sum: u32 = 0;
        // skip edges, we know they're 9s
        var row: u8 = 1;
        while (row < (rows - 1)) : (row += 1) {
            var column: u8 = 1;
            while (column < (columns - 1)) : (column += 1) {
                const coord = get_coord(row, column, columns);
                const height = heightmap.items[coord];
                if (height < heightmap.items[coord + 1] and
                    height < heightmap.items[coord - 1] and
                    height < heightmap.items[coord + columns] and
                    height < heightmap.items[coord - columns])
                {
                    sum += height + 1;
                }
            }
        }
        return sum;
    } else {
        var maxBasinsSize = [3]u32{ 0, 0, 0 };
        var row: u8 = 1;
        var basinExplorerStack = std.ArrayList(usize).init(allocator);
        defer basinExplorerStack.deinit();

        while (row < (rows - 1)) : (row += 1) {
            var column: u8 = 1;
            while (column < (columns - 1)) : (column += 1) {
                const coord_start = get_coord(row, column, columns);
                if (heightmap.items[coord_start] == 9) {
                    continue;
                }
                try basinExplorerStack.append(coord_start);
                var basinSize: u32 = 0;
                while (basinExplorerStack.items.len > 0) {
                    const cur = basinExplorerStack.pop();
                    if (heightmap.items[cur] == 9) continue;
                    try basinExplorerStack.append(cur + 1);
                    try basinExplorerStack.append(cur - 1);
                    try basinExplorerStack.append(cur + columns);
                    try basinExplorerStack.append(cur - columns);
                    heightmap.items[cur] = 9;
                    basinSize += 1;
                }
                if (basinSize > maxBasinsSize[0]) {
                    maxBasinsSize[0] = basinSize;
                    std.sort.sort(u32, maxBasinsSize[0..], {}, comptime std.sort.asc(u32));
                }
            }
        }
        return maxBasinsSize[0] * maxBasinsSize[1] * maxBasinsSize[2];
    }
}

fn day10(easy: bool, allocator: *Allocator) !u64 {
    const is_opener = struct {
        fn func(v: u8) bool {
            return switch (v) {
                '{', '[', '<', '(' => true,
                else => false,
            };
        }
    }.func;
    const is_closer = struct {
        fn func(v: u8) bool {
            return switch (v) {
                '}', ']', '>', ')' => true,
                else => false,
            };
        }
    }.func;
    const matches = struct {
        fn func(closer: u8, opener: u8) !bool {
            return switch (opener) {
                '{' => return (closer == '}'),
                '[' => return (closer == ']'),
                '<' => return (closer == '>'),
                '(' => return (closer == ')'),
                else => return error.Unexpected,
            };
        }
    }.func;

    var completion_scores = std.ArrayList(u64).init(allocator);
    defer completion_scores.deinit();

    var file = try std.fs.cwd().openFile("input/day10", .{});
    defer file.close();
    var score_illegal: u32 = 0;
    var reader = file.reader();
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |input_line| {
        var opener_stack: [1024]u8 = undefined;
        var opener_stack_size: u16 = 0;
        var i: u32 = 0;
        while (i < input_line.len) : (i += 1) {
            const value: u8 = input_line[i];
            if (is_opener(value)) {
                if (opener_stack_size >= opener_stack.len) {
                    // depth exceeded
                    return error.InvalidInput;
                }
                opener_stack[opener_stack_size] = value;
                opener_stack_size += 1;
            } else if (is_closer(value)) {
                if (opener_stack_size > 0 and try matches(value, opener_stack[opener_stack_size - 1])) {
                    opener_stack_size -= 1;
                } else {
                    score_illegal += switch (value) {
                        ')' => @as(u32, 3),
                        ']' => @as(u32, 57),
                        '}' => @as(u32, 1197),
                        '>' => @as(u32, 25137),
                        else => unreachable,
                    };
                    break;
                }
            } else {
                return error.InvalidInput;
            }
        } else {
            var score: u64 = 0;
            var j: u32 = opener_stack_size - 1;
            while (true) {
                score = (score * 5) + switch (opener_stack[j]) {
                    '(' => @as(u64, 1),
                    '[' => @as(u64, 2),
                    '{' => @as(u64, 3),
                    '<' => @as(u64, 4),
                    else => unreachable,
                };
                if (j == 0) {
                    break;
                } else {
                    j -= 1;
                }
            }
            try completion_scores.append(score);
        }
    }
    if (easy) {
        return score_illegal;
    } else {
        std.sort.sort(u64, completion_scores.items, {}, comptime std.sort.asc(u64));
        return completion_scores.items[(completion_scores.items.len - 1) / 2];
    }
}

fn day11(easy: bool, allocator: *Allocator) !u64 {
    const input_size = 10;
    const board_size = input_size + 2;

    const FLASHING: u4 = 10;
    const FLASHED: u4 = 11;
    const WALL: u4 = 15;

    var octopus_grid = [_]u4{WALL} ** (board_size * board_size);

    {
        var file = try std.fs.cwd().openFile("input/day11", .{});
        defer file.close();
        var reader = file.reader();
        var buf: [16]u8 = undefined;

        var row: u16 = board_size;
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |input_line| {
            if (row >= octopus_grid.len or input_line.len != input_size) {
                return error.InvalidInput;
            }
            var i: u8 = 0;
            while (i < input_line.len) : (i += 1) {
                octopus_grid[row + i + 1] = try std.fmt.parseInt(u4, input_line[i .. i + 1], 10);
            }
            row += board_size;
        }
        row += board_size;
        if (row != octopus_grid.len) {
            return error.InvalidInput;
        }
    }

    const perform_epoch = struct {
        fn func(grid: []u4, flashing: *std.ArrayList(u8)) !u32 {
            var flashes: u32 = 0;

            const increment_octopus = struct {
                fn func(grid2: []u4, coord: u8, flashing2: *std.ArrayList(u8), flash_count: *u32) !void {
                    if (grid2[coord] > 9)
                        return;
                    grid2[coord] += 1;
                    if (grid2[coord] == FLASHING) {
                        try flashing2.*.append(coord);
                        flash_count.* += 1;
                    }
                }
            }.func;

            var i: u8 = 0;
            while (i < board_size * board_size) : (i += 1) {
                try increment_octopus(grid, i, flashing, &flashes);
            }

            while (flashing.*.items.len > 0) {
                const cur = flashing.*.pop();
                grid[cur] = FLASHED;
                for ([_]u8{ cur - board_size, cur, cur + board_size }) |t1| {
                    for ([_]u8{ t1 - 1, t1, t1 + 1 }) |t2| {
                        try increment_octopus(grid, t2, flashing, &flashes);
                    }
                }
            }

            i = 0;
            while (i < board_size * board_size) : (i += 1) {
                if (grid[i] == FLASHED)
                    grid[i] = 0;
            }

            return flashes;
        }
    }.func;

    var flashing_octopuses = std.ArrayList(u8).init(allocator);
    defer flashing_octopuses.deinit();

    if (easy) {
        var epoch: u8 = 100;
        var flashes: u32 = 0;
        while (epoch > 0) : (epoch -= 1) {
            flashes += try perform_epoch(octopus_grid[0..], &flashing_octopuses);
        }
        return flashes;
    } else {
        var epoch: u32 = 1;
        const all_octopuses: u32 = input_size * input_size;
        while (true) {
            const flashes = try perform_epoch(octopus_grid[0..], &flashing_octopuses);
            if (flashes == all_octopuses) {
                return epoch;
            }
            epoch += 1;
        }
    }
}

fn day12(easy: bool, allocator: *Allocator) !u64 {
    const CaveSystem = struct {
        const Cave = struct {
            const Type = enum { Start, End, Small, Big };
            type: Type,
            connections: std.ArrayList(u16),
        };
        caves: std.ArrayList(Cave),
    };

    var caveSystem = CaveSystem{
        .caves = std.ArrayList(CaveSystem.Cave).init(allocator),
    };
    defer {
        for (caveSystem.caves.items) |cave| {
            cave.connections.deinit();
        }
        caveSystem.caves.deinit();
    }

    {
        var file = try std.fs.cwd().openFile("input/day12", .{});
        defer file.close();

        // maps cave identifier to index in the 'caves' array
        var cavename_to_index = std.StringHashMap(u16).init(allocator);
        defer cavename_to_index.deinit();

        // since we iterate over the file without reading it all at once,
        // we need to store the keys of the previous map ourselves
        var cavename_list = std.ArrayList([]u8).init(allocator);
        defer {
            for (cavename_list.items) |str| {
                allocator.free(str);
            }
            cavename_list.deinit();
        }

        var buf: [64]u8 = undefined;
        var reader = file.reader();
        while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            const getOrCreateCave = struct {
                fn func(caveName: []const u8, caveSys: *CaveSystem, caveNameMap: *std.StringHashMap(u16), caveNameList: *std.ArrayList([]u8), alloc: *Allocator) !u16 {
                    if (caveName.len == 0) return error.InvalidInput;
                    if (caveNameMap.*.get(caveName)) |idx|
                        return idx;

                    // gotta copy the string to the pool, since caveName is temporary
                    var nameCopy: []u8 = try alloc.*.alloc(u8, caveName.len);
                    std.mem.copy(u8, nameCopy, caveName);
                    try caveNameList.append(nameCopy);

                    const idx = @intCast(u16, caveSys.caves.items.len);
                    try caveSys.caves.append(undefined);
                    try caveNameMap.*.put(nameCopy, idx);

                    const cave = &caveSys.caves.items[caveSys.caves.items.len - 1];
                    cave.connections = std.ArrayList(u16).init(alloc);
                    if (std.mem.eql(u8, caveName, "start")) {
                        cave.*.type = CaveSystem.Cave.Type.Start;
                    } else if (std.mem.eql(u8, caveName, "end")) {
                        cave.*.type = CaveSystem.Cave.Type.End;
                    } else {
                        const isUpper = std.ascii.isUpper(caveName[0]);
                        var i: u8 = 1;
                        while (i < caveName.len) : (i += 1) {
                            if (std.ascii.isUpper(caveName[i]) != isUpper) return error.InvalidInput;
                        }
                        cave.*.type = if (isUpper) CaveSystem.Cave.Type.Big else CaveSystem.Cave.Type.Small;
                    }
                    return idx;
                }
            }.func;

            var it = std.mem.split(line, "-");

            const from_idx = try getOrCreateCave(it.next() orelse return error.InvalidInput, &caveSystem, &cavename_to_index, &cavename_list, allocator);
            const to_idx = try getOrCreateCave(it.next() orelse return error.InvalidInput, &caveSystem, &cavename_to_index, &cavename_list, allocator);
            if (from_idx == to_idx)
                return error.InvalidInput;
            const from_cave = &(caveSystem.caves.items[from_idx]);
            const to_cave = &(caveSystem.caves.items[to_idx]);
            try from_cave.*.connections.append(to_idx);
            try to_cave.*.connections.append(from_idx);
            if (from_cave.*.type == CaveSystem.Cave.Type.Big and to_cave.*.type == CaveSystem.Cave.Type.Big) // two big caves cannot be connected, else we loop endlessly
                return error.InvalidInput;
        }
        var has_start: bool = false;
        var has_end: bool = false;
        for (caveSystem.caves.items) |cave| {
            if (cave.type == CaveSystem.Cave.Type.Start) {
                if (has_start)
                    return error.InvalidInput;
                has_start = true;
            }
            if (cave.type == CaveSystem.Cave.Type.End) {
                if (has_end)
                    return error.InvalidInput;
                has_end = true;
            }
        }
        if (!has_start or !has_end)
            return error.InvalidInput;
    }

    const Path = struct {
        cave_index: u16,
        prev_path_index: u32,
    };
    var paths = std.ArrayList(Path).init(allocator);
    defer paths.deinit();
    var to_process = std.ArrayList(u32).init(allocator);
    defer to_process.deinit();
    var winning = std.ArrayList(u32).init(allocator);
    defer winning.deinit();

    var previouslyCheckedCaves = try allocator.alloc(bool, caveSystem.caves.items.len);
    defer allocator.free(previouslyCheckedCaves);

    {
        var start_cave_index: u16 = undefined;
        for (caveSystem.caves.items) |cave, i| {
            if (cave.type == CaveSystem.Cave.Type.Start) {
                start_cave_index = @intCast(u16, i);
                break;
            }
        } else return error.InvalidInput;
        try paths.append(Path{
            .cave_index = start_cave_index,
            .prev_path_index = 0,
        });
        try to_process.append(0);
    }
    while (to_process.items.len > 0) {
        const current_path_idx: u32 = to_process.pop();
        const current_path = paths.items[current_path_idx];
        const current_cave = caveSystem.caves.items[current_path.cave_index];
        if (current_cave.type == CaveSystem.Cave.Type.End) {
            try winning.append(current_path_idx);
        } else {
            var has_children: bool = false;
            connection: for (current_cave.connections.items) |connected_cave_idx| {
                const connected_cave = caveSystem.caves.items[connected_cave_idx];
                switch (connected_cave.type) {
                    CaveSystem.Cave.Type.Start => continue :connection,
                    CaveSystem.Cave.Type.Big => {},
                    CaveSystem.Cave.Type.End => {},
                    CaveSystem.Cave.Type.Small => if (easy) {
                        var prev_path_index = current_path.prev_path_index;
                        while (prev_path_index > 0) {
                            const prev_path = paths.items[prev_path_index];
                            if (prev_path.cave_index == connected_cave_idx)
                                continue :connection;
                            prev_path_index = prev_path.prev_path_index;
                        }
                    } else {
                        defer std.mem.set(bool, previouslyCheckedCaves, false);
                        previouslyCheckedCaves[connected_cave_idx] = true;
                        var dupes: u2 = 0;
                        var path = current_path;
                        while (true) {
                            const cave = caveSystem.caves.items[path.cave_index];
                            if (cave.type == CaveSystem.Cave.Type.Small) {
                                if (previouslyCheckedCaves[path.cave_index]) {
                                    dupes += 1;
                                    if (dupes == 2) continue :connection;
                                }
                                previouslyCheckedCaves[path.cave_index] = true;
                            }
                            if (path.prev_path_index == 0)
                                break;
                            path = paths.items[path.prev_path_index];
                        }
                    },
                }
                has_children = true;
                try to_process.append(@intCast(u32, paths.items.len));
                try paths.append(Path{
                    .cave_index = connected_cave_idx,
                    .prev_path_index = current_path_idx,
                });
            }
            //if (!has_children) {
            //}
        }
    }
    return winning.items.len;
}
fn day13(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day14(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day15(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day16(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day17(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day18(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day19(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day20(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day21(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day22(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day23(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day24(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}
fn day25(easy: bool, allocator: *Allocator) !u64 {
    return error.Unimplemented;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = &gpa.allocator;
    //var allocator = std.testing.allocator;

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
        1 => try day1(easy, allocator),
        2 => try day2(easy, allocator),
        3 => try day3(easy, allocator),
        4 => try day4(easy, allocator),
        5 => try day5(easy, allocator),
        6 => try day6(easy, allocator),
        7 => try day7(easy, allocator),
        8 => try day8(easy, allocator),
        9 => try day9(easy, allocator),
        10 => try day10(easy, allocator),
        11 => try day11(easy, allocator),
        12 => try day12(easy, allocator),
        13 => try day13(easy, allocator),
        14 => try day14(easy, allocator),
        15 => try day15(easy, allocator),
        16 => try day16(easy, allocator),
        17 => try day17(easy, allocator),
        18 => try day18(easy, allocator),
        19 => try day19(easy, allocator),
        20 => try day20(easy, allocator),
        21 => try day21(easy, allocator),
        22 => try day22(easy, allocator),
        23 => try day23(easy, allocator),
        24 => try day24(easy, allocator),
        25 => try day25(easy, allocator),
        else => return error.InvalidArguments,
    };

    const str = if (easy) "easy" else "hard";
    try stdout.print("Answer to day {} ({s}) is: {}\n", .{ puzzle, str, val });
}
