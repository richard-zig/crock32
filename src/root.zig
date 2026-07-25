const std = @import("std");

pub const Crock32Error = error{
    UnexpectedChar,
    OverflowsU64,
    BufferOverflow,
    CannotCheck,
    UnexpectedCheckChar,
    CheckFailed,
};

pub const max_buf_len = 14; // includes check

const digits = "0123456789abcdefghjkmnpqrstvwxyz*~$=u";
const digitsUpper = "0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U";

fn decodeChar(b: u8) u8 {
    return switch (b) {
        'U', 'u' => 36,
        'O', 'o' => 0,
        'L', 'l', 'I', 'i' => 1,
        '0'...'9' => b - '0',
        'a'...'h' => b - 'a' + 10,
        'A'...'H' => b - 'A' + 10,
        'j', 'k' => b - 'a' + 9,
        'J', 'K' => b - 'A' + 9,
        'm', 'n' => b - 'a' + 8,
        'M', 'N' => b - 'A' + 8,
        'p'...'t' => b - 'a' + 7,
        'P'...'T' => b - 'A' + 7,
        'v'...'z' => b - 'a' + 6,
        'V'...'Z' => b - 'A' + 6,
        '*' => 32,
        '~' => 33,
        '$' => 34,
        '=' => 35,
        '-' => 254,
        else => 255,
    };
}

pub fn decode(str: []const u8) Crock32Error!u64 {
    const cutoff: u64 = ((1 << 64) - 1) / 32 + 1;
    var n: u64 = 0;
    for (str) |char| {
        if (n >= cutoff) return Crock32Error.OverflowsU64;
        const c = decodeChar(char);
        if (c == 254) continue;
        if (c >= 32) return Crock32Error.UnexpectedChar;
        n = n * 32 + c;
    }
    return n;
}

pub fn decodeCheck(str: []const u8) Crock32Error!u64 {
    if (str.len < 2) return Crock32Error.CannotCheck;
    const check = decodeChar(str[str.len - 1]);
    if (check > 36) return Crock32Error.UnexpectedCheckChar;
    const val = try decode(str[0 .. str.len - 1]);
    if (val % 37 != check) return Crock32Error.CheckFailed;
    return val;
}

fn enc(d: []const u8, buf: []u8, n: u64) Crock32Error![]const u8 {
    var i = buf.len;
    if (i == 0) return Crock32Error.BufferOverflow;
    var nn = n;
    while (nn >= 32) {
        if (i > 1) i -= 1 else return Crock32Error.BufferOverflow;
        buf[i] = d[nn % 32];
        nn /= 32;
    } else i -= 1;
    buf[i] = d[nn];
    return buf[i..];
}

pub fn encode(buf: []u8, n: u64) Crock32Error![]const u8 {
    return enc(digits, buf, n);
}

pub fn encodeCheck(buf: []u8, n: u64) Crock32Error![]const u8 {
    if (buf.len < 2) return Crock32Error.BufferOverflow;
    const str = try encode(buf[0 .. buf.len - 1], n);
    buf[buf.len - 1] = digits[n % 37];
    return buf[buf.len - str.len - 1 ..];
}

pub fn encodeUpper(buf: []u8, n: u64) Crock32Error![]const u8 {
    return enc(digitsUpper, buf, n);
}

pub fn encodeUpperCheck(buf: []u8, n: u64) Crock32Error![]const u8 {
    if (buf.len < 2) return Crock32Error.BufferOverflow;
    const str = try encodeUpper(buf[0 .. buf.len - 1], n);
    buf[buf.len - 1] = digitsUpper[n % 37];
    return buf[buf.len - str.len - 1 ..];
}

test "decode" {
    const val = try decode("yolo");
    try std.testing.expect(val == 983072);
}

test "encode" {
    var buf: [4]u8 = undefined;
    const str = try encode(buf[0..], 983072);
    try std.testing.expectEqualStrings(str, "y010");
}

test "decodeCheck" {
    const val = try decodeCheck("yolok");
    try std.testing.expect(val == 983072);
}

test "decodeCheck bad check" {
    try std.testing.expect(decodeCheck("yolo=") == Crock32Error.CheckFailed);
}

test "encodeCheck" {
    var buf: [5]u8 = undefined;
    const str = try encodeCheck(buf[0..], 983072);
    try std.testing.expectEqualStrings(str, "y010k");
}

test "upper round trip" {
    var buf: [max_buf_len]u8 = undefined;
    const str = try encodeUpperCheck(buf[0..], 0xFFFFFFFFFFFFFFFF);
    const num = try decodeCheck(str);
    try std.testing.expect(num == 0xFFFFFFFFFFFFFFFF);
}
