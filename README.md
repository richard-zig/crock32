# Crock32

This is a zig implementation of Douglas Crockford's [base32 encoding scheme](See: https://www.crockford.com/base32.html).

## Installation

Use the following command:

```
zig fetch --save git+https://github.com/richard-zig/crock32
```

Then in your `build.zig` file:

```zig
const crock32 = b.dependency("crock32", .{
    .target = target,
});
exe.root_module.addImport("crock32", crock32.module("crock32"));
```

## Usage

```zig
const crock32 = @import("crock32");

var buf: [crock32.max_buf_len]u8 = undefined;

// encodes the u64 as 'y010'
const str1 = try encode(buf[0..], 983072);

// adds a check value and gives 'y010k'
const str2 = try encodeCheck(buf[0..], 983072);

// uses upper case
const str3 = try encodeUpper(buf[0..], 983072);

// upper case with a check value
const str4 = try encodeUpperCheck(buf[0..], 983072);

// for strings created by encode and encodeUpper, use decode
const num1 = try decode(str1);

// if you have a check value, use decodeCheck
const num2 = try decodeCheck(str4);
```