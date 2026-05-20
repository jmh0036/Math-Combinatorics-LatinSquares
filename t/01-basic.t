use strict;
use warnings;
use Test::More;
use Math::Combinatorics::LatinSquares;

# ---------------------------------------------------------------------------
# Helper: verify a grid satisfies all regional constraints
# ---------------------------------------------------------------------------

sub verify_grid {
    my ($ls, $grid) = @_;
    my $N       = $ls->n;
    my $regions = $ls->regions;
    my $maps    = $ls->region_maps;

    # Each cell has a value in 1..N
    for my $r (0 .. $N-1) {
        for my $c (0 .. $N-1) {
            return 0 unless defined $grid->[$r][$c]
                         && $grid->[$r][$c] >= 1
                         && $grid->[$r][$c] <= $N;
        }
    }

    # Each tiling: every box contains each value exactly once
    for my $t (0 .. $#$regions) {
        my $map = $maps->[$t];
        my @box_vals;   # $box_vals[$k]{$v} = count
        for my $r (0 .. $N-1) {
            for my $c (0 .. $N-1) {
                my $k = $map->[$r][$c];
                my $v = $grid->[$r][$c];
                $box_vals[$k]{$v}++;
            }
        }
        for my $k (0 .. $N-1) {
            for my $v (1 .. $N) {
                return 0 unless ($box_vals[$k]{$v} // 0) == 1;
            }
        }
    }
    return 1;
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

subtest '2x2 boxes only (4x4 grid)' => sub {
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[2, 2]]);
    is($ls->n, 4, 'N=4');
    my $grid = $ls->solve;
    ok(defined $grid, 'got a solution');
    ok(verify_grid($ls, $grid), 'solution satisfies constraints');
};

subtest '1x4 and 4x1 (rows and cols, 4x4)' => sub {
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[1, 4], [4, 1]]);
    is($ls->n, 4, 'N=4');
    my $grid = $ls->solve;
    ok(defined $grid, 'got a solution');
    ok(verify_grid($ls, $grid), 'solution satisfies constraints');
};

subtest '2x2 + rows + cols (classic 4x4 sudoku)' => sub {
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[1,4],[4,1],[2,2]]);
    my $grid = $ls->solve;
    ok(defined $grid, 'got a solution');
    ok(verify_grid($ls, $grid), 'solution satisfies constraints');
};

subtest '2x3 and 3x2 (6x6, no rows/cols)' => sub {
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[2, 3], [3, 2]]);
    is($ls->n, 6, 'N=6');
    my $grid = $ls->solve;
    ok(defined $grid, 'got a solution');
    ok(verify_grid($ls, $grid), 'solution satisfies constraints');
};

subtest 'mismatched products croaks' => sub {
    eval { Math::Combinatorics::LatinSquares->new(regions => [[2, 3], [2, 2]]) };
    like($@, qr/differ/, 'croaks on mismatched products');
};

subtest 'solve returns different results (randomness)' => sub {
    my $ls = Math::Combinatorics::LatinSquares->new(regions => [[2, 2]]);
    my %seen;
    my $tries = 20;
    for (1 .. $tries) {
        my $grid = $ls->solve;
        my $key  = join(',', map { join('', @$_) } @$grid);
        $seen{$key}++;
    }
    cmp_ok(scalar keys %seen, '>', 1, "got more than one distinct solution in $tries tries");
};

done_testing;
