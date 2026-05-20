package Math::Combinatorics::LatinSquares;

use strict;
use warnings;
use Algorithm::DLX;
use List::Util qw(shuffle);
use Carp       qw(croak);

our $VERSION = '0.01';

=head1 NAME

Math::Combinatorics::LatinSquares - Generate random latin squares with simultaneous
rectangular regional constraints

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Math::Combinatorics::LatinSquares;

    # Classic 9x9 sudoku (3x3 boxes only — no row/col constraint unless you
    # add --region 1 9 and --region 9 1)
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[3, 3]]);
    my $grid = $ls->solve;

    # 6x6 with horizontal and vertical 2x3 box tilings simultaneously
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[2, 3], [3, 2]]);
    my $grid = $ls->solve;   # $grid->[$r][$c] = value (1..N)

    # Full sudoku pair latin square: rows, cols, and both box orientations
    my $ls = Math::Combinatorics::LatinSquares->new(
        regions => [[1, 6], [6, 1], [2, 3], [3, 2]],
    );
    my $grid = $ls->solve;

    # Print it
    $ls->print_grid($grid);

=head1 DESCRIPTION

A B<latin square> is an NxN grid in which each of N symbols appears exactly
once in every row and every column.

A B<sudoku pair latin square> (also called a jigsaw or irregular sudoku)
adds one or more I<regional> constraints: the NxN grid is partitioned into N
non-overlapping regions of N cells each, and each region must also contain
every symbol exactly once.

This module focuses on B<rectangular regional tilings>: each region
specification C<[R, C]> describes a uniform tiling of the NxN grid by RxC
rectangles.  Multiple region specifications can be enforced I<simultaneously>,
meaning every tiling must independently be latin at the same time.

Rows and columns are I<not> assumed; specify C<[1, N]> and C<[N, 1]> explicitly
if you want them.

Solving is done via L<Algorithm::DLX> (Dancing Links exact cover).  Candidate
placements are shuffled before each solve call, so every call to C<solve>
returns a different random solution.

=head1 METHODS

=head2 new(%args)

    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[2, 3], [3, 2]]);

Constructs a new solver object.  Arguments:

=over 4

=item regions

Required.  An arrayref of C<[box_rows, box_cols]> pairs.  All pairs must have
the same product R*C, which becomes N (the grid side length and symbol count).

=back

=cut

sub new {
    my ($class, %args) = @_;

    croak "regions is required" unless exists $args{regions};
    my $region_specs = $args{regions};
    croak "regions must be a non-empty arrayref"
        unless ref $region_specs eq 'ARRAY' && @$region_specs;

    my $N;
    my @regions;
    for my $spec (@$region_specs) {
        croak "each region spec must be an arrayref of two positive integers"
            unless ref $spec eq 'ARRAY' && @$spec == 2
                && $spec->[0] >= 1 && $spec->[1] >= 1;
        my ($br, $bc) = @$spec;
        my $prod = $br * $bc;
        croak "region [$br, $bc]: product must be >= 2" if $prod < 2;
        if (defined $N) {
            croak "region [$br, $bc]: product $prod differs from $N "
                . "(all regions must have the same product)"
                unless $prod == $N;
        } else {
            $N = $prod;
        }
        croak "grid size $N must be divisible by box_rows $br" if $N % $br;
        croak "grid size $N must be divisible by box_cols $bc" if $N % $bc;
        push @regions, [$br, $bc];
    }

    my @region_maps = map { _build_region_map($N, $_->[0], $_->[1]) } @regions;

    return bless {
        N           => $N,
        regions     => \@regions,
        region_maps => \@region_maps,
    }, $class;
}

=head2 n

Returns N, the grid side length (and number of symbols).

=cut

sub n { $_[0]->{N} }

=head2 regions

Returns the arrayref of C<[box_rows, box_cols]> region specs.

=cut

sub regions { $_[0]->{regions} }

=head2 region_maps

Returns an arrayref of region maps (one per region spec).  Each map is a 2D
arrayref C<$map->[$r][$c]> giving the box index (0..N-1) for cell (r, c).

=cut

sub region_maps { $_[0]->{region_maps} }

=head2 solve

    my $grid = $ls->solve;   # returns undef if no solution exists
    # $grid->[$r][$c] = integer value 1..N

Builds and solves the exact cover problem via L<Algorithm::DLX>.  Candidate
placements are shuffled on every call, so repeated calls return different
random solutions.

Returns a 2D arrayref on success, or C<undef> if no solution exists for the
given combination of regional constraints.

=cut

sub solve {
    my ($self) = @_;
    my $N           = $self->{N};
    my @regions     = @{ $self->{regions} };
    my @region_maps = @{ $self->{region_maps} };

    my $dlx = Algorithm::DLX->new();
    my %col;

    # --- Cell constraints: each cell gets exactly one value ---
    for my $r (0 .. $N-1) {
        for my $c (0 .. $N-1) {
            $col{"cell_${r}_${c}"} = $dlx->add_column("cell_${r}_${c}");
        }
    }

    # --- Regional constraints: one set of N*N columns per tiling ---
    # A tiling [br, bc] on an NxN grid produces N boxes numbered 0..N-1
    # (left-to-right, top-to-bottom).  For each box k and value v we need
    # a column asserting "box k in tiling t contains value v exactly once".
    for my $t (0 .. $#regions) {
        for my $k (0 .. $N-1) {
            for my $v (1 .. $N) {
                $col{"t${t}_box${k}_v${v}"} = $dlx->add_column("t${t}_box${k}_v${v}");
            }
        }
    }

    # --- Candidate rows (shuffled for randomness) ---
    my @placements;
    for my $r (0 .. $N-1) {
        for my $c (0 .. $N-1) {
            for my $v (1 .. $N) {
                push @placements, [$r, $c, $v];
            }
        }
    }

    for my $p (shuffle @placements) {
        my ($r, $c, $v) = @$p;
        my @cols = ( $col{"cell_${r}_${c}"} );
        for my $t (0 .. $#regions) {
            my $k = $region_maps[$t][$r][$c];
            push @cols, $col{"t${t}_box${k}_v${v}"};
        }
        $dlx->add_row("${r},${c},${v}", @cols);
    }

    my $solutions = $dlx->solve(number_of_solutions => 1);
    return undef unless $solutions && @$solutions;

    my @grid;
    for my $row_name (@{ $solutions->[0] }) {
        my ($r, $c, $v) = split /,/, $row_name;
        $grid[$r][$c] = $v;
    }
    return \@grid;
}

=head2 print_grid($grid, %opts)

    $ls->print_grid($grid);
    $ls->print_grid($grid, fh => \*STDERR);

Prints the solution grid to a filehandle (default: STDOUT).

=cut

sub print_grid {
    my ($self, $grid, %opts) = @_;
    my $fh = $opts{fh} // \*STDOUT;
    my $N  = $self->{N};
    my $w  = length($N);
    for my $r (0 .. $N-1) {
        print $fh join(' ', map { sprintf("%${w}d", $grid->[$r][$_]) } 0 .. $N-1), "\n";
    }
}

=head2 print_region_map($tiling_index, %opts)

    $ls->print_region_map(0);           # first tiling
    $ls->print_region_map(1, fh => \*STDERR);

Prints the box map for the given tiling index using letter labels.

=cut

sub print_region_map {
    my ($self, $t, %opts) = @_;
    my $fh  = $opts{fh} // \*STDOUT;
    my $N   = $self->{N};
    my $map = $self->{region_maps}[$t];
    my @labels = ('A'..'Z', 'a'..'z', '0'..'9');
    for my $r (0 .. $N-1) {
        print $fh join(' ', map { $labels[$map->[$r][$_]] // '?' } 0 .. $N-1), "\n";
    }
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

sub _build_region_map {
    my ($N, $br, $bc) = @_;
    my $boxes_across = $N / $bc;
    my @map;
    for my $r (0 .. $N-1) {
        for my $c (0 .. $N-1) {
            $map[$r][$c] = int($r / $br) * $boxes_across + int($c / $bc);
        }
    }
    return \@map;
}

1;

__END__

=head1 REGION SPECIFICATIONS

Each region spec C<[R, C]> describes a uniform tiling of the NxN grid by RxC
rectangles.  N must equal R*C, and N must be divisible by both R and C (which
is always true since N = R*C).

Rows and columns are just special cases:

  [1, N]  — each row is a single 1xN strip (row latin constraint)
  [N, 1]  — each column is a single Nx1 strip (column latin constraint)

They are not added automatically; specify them explicitly if desired.

=head1 ALGORITHM

The problem is modelled as an exact cover problem and solved with
L<Algorithm::DLX> (Knuth's Dancing Links algorithm).

Columns (constraints):

=over 4

=item * B<Cell>: one column per cell — each cell receives exactly one value.

=item * B<Regional>: for each tiling T, box K, and value V — box K of tiling T
contains value V exactly once.  There are N² such columns per tiling.

=back

Each candidate row corresponds to placing value V in cell (R, C), and covers:
the cell column for (R, C), and for each tiling T the regional column for the
box containing (R, C) and value V.

Candidates are shuffled before each solve, so C<solve> returns a different
random solution on every call.  C<number_of_solutions =E<gt> 1> is passed to
L<Algorithm::DLX> so it exits as soon as the first solution is found.

=head1 DEPENDENCIES

L<Algorithm::DLX>, L<List::Util>

=head1 AUTHOR

James Hammer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
