# Zig RegEx wrapper for Oniguruma

Using https://github.com/kkos/oniguruma.

Oniguruma is a modern and flexible regular expressions library. It encompasses features from different regular expression implementations that traditionally exist in different languages.

## Usage

Include the libregex-oniguruma into the `build.zig.zon` file.

```
.dependencies = .{
    .libregex-oniguruma = .{
        .url = "https://github.com/arats-io/zig-regex-oniguruma/archive/refs/tags/v0.1.0.tar.gz",
        .hash = "12201fd38f467e6c64ee7bca53da95863b6c05da77fc51daf0ab22079ede57cbd4e2",
    },
},
```
