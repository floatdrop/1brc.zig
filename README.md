# [1brc](https://github.com/gunnarmorling/1brc) in Zig

One billion rows challange in std Zig.

```
Benchmark 1: ./zig-out/bin/06_short_hash
  Time (mean ± σ):      1.872 s ±  0.037 s    [User: 21.691 s, System: 1.330 s]
  Range (min … max):    1.829 s …  1.959 s    10 runs
```


Our target is to beat at least [Top 1 submission](https://github.com/gunnarmorling/1brc/blob/main/src/main/java/dev/morling/onebrc/CalculateAverage_thomaswue.java) from Java 1brc solution compiled with GraalVM:

```
Benchmark 1: ./calculate_average_thomaswue.sh
  Time (mean ± σ):     587.7 ms ±   3.3 ms    [User: 3.6 ms, System: 4.5 ms]
  Range (min … max):   583.2 ms … 593.2 ms    10 runs
```

## TODO

- Implement work stealing with 2MB chunks
- Figure out faster hash function
- Reduce branches where possible
- Profile cachemisses

## Build and run

You will need Zig 0.15.2.

```
$ zig build --release=fast

$ ./zig-out/bin/create_measurements

$ ./zig-out/bin/05_parallel
```


## Resources

- [Solving Java’s 1 Billion Row Challenge (Ep. 1) | With @caseymuratori](https://www.youtube.com/watch?v=n-YK3B4_xPA) - Very good series about this challenge 
