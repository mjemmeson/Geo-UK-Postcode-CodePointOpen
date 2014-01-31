package Geo::UK::Postcode::CodePointOpen;

our $VERSION = '0.003';

use Moo;
use Types::Path::Tiny qw/ Dir /;

use Geo::UK::Postcode::Regex;
use Geo::Coordinates::OSGB qw/ grid_to_ll shift_ll_into_WGS84 /;
use Text::CSV;

my $pc_re = Geo::UK::Postcode::Regex->strict_regex;

has path => ( is => 'ro', isa => Dir, coerce => Dir->coercion );
has column_headers => ( is => 'lazy' );
has csv            => ( is => 'lazy' );
has metadata       => ( is => 'lazy' );

sub _build_column_headers {
    my $self = shift;

    my $fh = $self->doc_dir->child('Code-Point_Open_Column_Headers.csv')
        ->filehandle('<');

    return {
        short => $self->csv->getline($fh),
        long  => $self->csv->getline($fh),
    };
}

sub _build_csv {
    my $csv = Text::CSV->new( { binary => 1, eol => "\r\n" } )
        or die Text::CSV->error_diag();
    return $csv;
}

# <author>
# PRODUCT: <product>
# DATASET VERSION NUMBER: <version>
# COPYRIGHT DATE: <YYYYMMDD>
# RM UPDATE DATE: <YYYYMMDD>
#       XX\t123
sub _build_metadata {
    my $self = shift;

    my $metadata_file = $self->doc_dir->child('metadata.txt');

    my @lines = $metadata_file->lines( { chomp => 1 } );

    my $author = shift @lines;

    my @headers = grep {/:/} @lines;
    my @counts  = grep {/\t/} @lines;

    return {
        AUTHOR => $author,
        ( map { split /\s*:\s*/ } @headers ),
        counts =>
            { map { /\s+([A-Z]{1,2})\t(\d+)/ ? ( $1, $2 ) : () } @counts },
    };
}

sub doc_dir {
    shift->path->child('Doc');
}

sub data_dir {
    shift->path->child('Data/CSV');
}

sub read_iterator {
    my ( $self, %args ) = @_;

    my ( @col_names, $lat_col, $lon_col, $out_col, $in_col );
    if ( $args{short_column_names} ) {
        @col_names = @{ $self->column_headers->{short} };
        ( $lat_col, $lon_col ) = ( 'LA', 'LO' );
        ( $out_col, $in_col )  = ( 'OC', 'IC' );
    } else {
        @col_names = @{ $self->column_headers->{long} };
        ( $lat_col, $lon_col ) = ( 'Latitude', 'Longitude' );
        ( $out_col, $in_col )  = ( 'Outcode',  'Incode' );
    }

    # Get list of data files
    my @data_files = sort $self->data_dir->children(qr/\.csv$/);

    # Create iterator coderef
    my $fh2;
    my $csv = $self->csv;

    my $iterator = sub {

        unless ( $fh2 && !eof $fh2 ) {
            my $file = shift @data_files or return;    # none left
            $fh2 = $file->filehandle('<');
        }

        my $row = $csv->getline($fh2);

        my $i = 0;
        my $pc = { map { $_ => $row->[ $i++ ] } @col_names };

        if ( $args{include_lat_long} ) {
            if ( $row->[2] && $row->[3] ) {
                my ( $lat, $lon )
                    = shift_ll_into_WGS84( grid_to_ll( $row->[2], $row->[3] ) );

                $pc->{$lat_col} = sprintf( "%.5f", $lat );
                $pc->{$lon_col} = sprintf( "%.5f", $lon );
            }
        }

        if ( $args{split_postcode} ) {

            $row->[0] =~ s/\s+/ /;

            my ( $area, $district, $sector, $unit )
                = eval { $row->[0] =~ $pc_re };

            if ( $@ || !$unit ) {
                die "Unable to parse '"
                    . $row->[0]
                    . "' : Please report via "
                    . "https://github.com/mjemmeson/Geo-UK-Postcode-Regex/issues\n";

            } else {
                $pc->{$out_col} = $area . $district;
                $pc->{$in_col}  = $sector . $unit;
            }
        }

        return $pc;
    };

    return $iterator;
}

sub batch_iterator {
    my ( $self, %args ) = @_;

    my $batch_size = $args{batch_size} || 100;

    my $read_iterator = $self->read_iterator(%args);

    return sub {

        my $i = 1;
        my @postcodes;

        while ( my $pc = $read_iterator->() ) {
            push @postcodes, $pc;
            last if ++$i > $batch_size;
        }

        return @postcodes;
    };
}

1;

__END__

=head1 NAME

Geo::UK::Postcode::CodePointOpen - Utility object to extract OS Code-Point Open data for British Postcodes

=head1 SYNOPSIS

    use Geo::UK::Postcode::CodePointOpen;

    my $code_point_open = Geo::UK::Postcode::CodePointOpen->new( path => ... );

    my $metadata = $code_point_open->metadata();

    my $iterator = $code_point_open->read_iterator();
    while ( my $pc = $iterator->() ) {
        ...;
    }

    my $batch_iterator = $code_point_open->batch_iterator();
    while ( my @batch = $batch_iterator->() ) {
        ...;
    }

    # Just access data files (as Path::Tiny objects)
    my @data_files = sort $self->data_dir->children( qr/\.csv$/ );

=head1 DESCRIPTION

Util object to read OS Code-Point Open data.

=head1 ATTRIBUTES

=head2 path

Set at construction to the directory containing the contents of the OS
Code-Point Open Zip file.

=head2 doc_dir, data_dir

L<Path::Tiny> objects for the documentation and CSV data directories.

=head2 metadata

Hashref parsed from the C<Doc/metadata.txt> file. Contains postcode counts
per area, date data generated, etc.

=head1 METHODS

=head2 new

    my $code_point_open = Geo::UK::Postcode::CodePointOpen->new(
        path => ...,    # path to Unzipped Code-Point Open directory
    );

Constructor.

=head2 read_iterator

    my $iterator = $code_point_open->read_iterator(
        short_column_names => 1,    # default is false (long names)
        include_lat_long   => 1,    # default is false
        split_postcode     => 1,    # split into outcode/incode
    );

    while ( my $pc = $iterator->() ) {
        ...
    }

Returns a coderef iterator. Call that coderef repeatedly to get a hashref of
data for each postcode in data files.

=head2 batch_iterator

    my $batch_iterator = $code_point_open->batch_iterator(
        batch_size         => 100,  # number per batch (default 100)
        short_column_names => 1,    # default is false (long names)
        include_lat_long   => 1,    # default is false
        split_postcode     => 1,    # split into outcode/incode
    );

    while ( my @batch = $batch_iterator->() ) {
        ...
    }

Returns a coderef iterator. Call that coderef repeatedly to get a list of
postcode hashrefs.

=head1 SEE ALSO

=over

=item *

L<Geo::UK::Postcode::Regex>

=back

=head1 AUTHOR

Michael Jemmeson E<lt>mjemmeson@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Michael Jemmeson

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

