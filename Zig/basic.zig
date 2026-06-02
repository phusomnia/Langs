const log = @import("std").debug.print;

fn hello_world() void {
    log("Hello word", .{});
}

fn typed() void {
    const name = "ZigC";
    var SIGNED: i32 = 12;
    SIGNED += 1;
    const UNSIGNED: u32 = 32;
    const TRUE: bool = true;
    log("Name: {s}, Signed: {}, Unsigned: {}, Bool: {}, {}\n", .{ name, SIGNED, UNSIGNED, TRUE, !TRUE });
}

fn flow_control(a: i32) void {
    if (a != 0) {
        log("a is {}", .{a});
    }

    const name: ?[]const u8 = "Zig";
    if (name) |n| {
        log("{s}", .{n});
    }

    for (0..10) |i| {
        log("{}\n", .{i});
    }
}

const Character = enum { Mario, Luigi, Peach };
fn switch_pattern(character: Character) void {
    const player = switch (character) {
        .Mario => "XD WTF",
        .Luigi => "Green brother",
        .Peach => "B princess",
    };
    log("Player: {s}\n", .{player});
}

const Player = struct {
    health: f32,
    score: u32,

    pub fn constructor(health: f32, score: u32) Player {
        return Player{ .health = health, .score = score };
    }

    pub fn takeDamage(self: *Player, amount: f32) void {
        self.health -= amount;
        log("Health: {}\n", .{self.health});
    }
};

pub fn main() void {
    hello_world();
    typed();
    flow_control(0);
    switch_pattern(Character.Mario);
    var p = Player{ .health = 100, .score = 10 };
    p.takeDamage(10);
}
