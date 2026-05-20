# Math::Combinatorics::LatinSquares

Generate random latin squares with simultaneous rectangular regional constraints.

## What is this?

A **latin square** is an NxN grid where each of N symbols appears exactly once
in every region you care about.  This module lets you specify any number of
**rectangular tilings** of the grid, each of which must independently be latin.

Rows and columns are just special cases of rectangular tilings — they are *not*
assumed.  You opt into them explicitly.

## Examples

### Classic 9x9 sudoku (rows + cols + 3x3 boxes)

    latin-squares --region 1 9 --region 9 1 --region 3 3

### 6x6 with horizontal and vertical box tilings (no rows/cols)

    latin-squares --region 2 3 --region 3 2 --verbose

### Full 6x6 sudoku pair latin square

    latin-squares --region 1 6 --region 6 1 --region 2 3 --region 3 2

### Just 2x3 boxes on a 6x6 grid

    latin-squares --region 2 3

## Region specification

`--region R C` tiles the NxN grid with RxC rectangles, left-to-right and
top-to-bottom.  All `--region` pairs must have the same product R*C = N.

Special cases:
- `--region 1 N` — each row is a region (row latin constraint)
- `--region N 1` — each column is a region (column latin constraint)

## Installation

    perl Makefile.PL
    make
    make test
    make install

## Dependencies

- [Algorithm::DLX](https://github.com/jmh0036/perlDLX) >= 0.02
- List::Util (core)
- Getopt::Long (core)
- Pod::Usage (core)

## Algorithm

The problem is modelled as an exact cover problem solved by Knuth's Dancing
Links (DLX) algorithm via `Algorithm::DLX`.

Constraints:
- **Cell**: each cell gets exactly one value.
- **Regional**: for each tiling T, box K, and value V — box K of tiling T
  contains value V exactly once.

Candidates (one per cell × value) are shuffled before every solve, so each
call to `solve()` returns a different random solution.  `number_of_solutions =>
1` is passed to `Algorithm::DLX` so it exits on the first solution found.

## License

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
