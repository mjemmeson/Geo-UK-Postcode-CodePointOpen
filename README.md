# NAME

Geo::UK::Postcode::CodePointOpen - Utility object to extract OS Code-Point Open data for British Postcodes

# SYNOPSIS

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

# DESCRIPTION

Util object to read OS Code-Point Open data.

# ATTRIBUTES

## path

Set at construction to the directory containing the contents of the OS
Code-Point Open Zip file.

## doc\_dir, data\_dir

[Path::Tiny](https://metacpan.org/pod/Path::Tiny) objects for the documentation and CSV data directories.

## metadata

Hashref parsed from the `Doc/metadata.txt` file. Contains postcode counts
per area, date data generated, etc.

# METHODS

## new

    my $code_point_open = Geo::UK::Postcode::CodePointOpen->new(
        path => ...,    # path to Unzipped Code-Point Open directory
    );

Constructor.

## read\_iterator

    my $iterator = $code_point_open->read_iterator(
        outcodes           => [...],    # specify certain outcodes
        short_column_names => 1,        # default is false (long names)
        include_lat_long   => 1,        # default is false
        split_postcode     => 1,        # split into outcode/incode
    );

    while ( my $pc = $iterator->() ) {
        ...
    }

Returns a coderef iterator. Call that coderef repeatedly to get a hashref of
data for each postcode in data files.

## batch\_iterator

    my $batch_iterator = $code_point_open->batch_iterator(
        outcodes           => [...],    # specify certain outcodes
        batch_size         => 100,      # number per batch (default 100)
        short_column_names => 1,        # default is false (long names)
        include_lat_long   => 1,        # default is false
        split_postcode     => 1,        # split into outcode/incode
    );

    while ( my @batch = $batch_iterator->() ) {
        ...
    }

Returns a coderef iterator. Call that coderef repeatedly to get a list of
postcode hashrefs.

# data\_files

    my @data_files = $code_point_open->data_files(
        qw/ AB10 AT3 WC /
    );

Returns list of data files matching a supplied list of outcodes or data areas.

NOTE - doesn't check that the outcode(s) exist within the list of returned
files - an invalid outcode will return a matching file, provided the area
(non-digit part of outcode) is valid.

# SEE ALSO

- [Geo::UK::Postcode::Regex](https://metacpan.org/pod/Geo::UK::Postcode::Regex)

# AUTHOR

Michael Jemmeson <mjemmeson@cpan.org>

# COPYRIGHT

Copyright 2014- Michael Jemmeson

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
