package Vitruvius::Core::FileSet;

use Vitruvius::Skel::Moo;

use Vitruvius::Types qw< ArrayRef HasMethods VtvSourceFile >;

use Vitruvius::Core::SourceFile;
use Vitruvius::Util qw< parallelize >;

=head1 NAME

Vitruvius::Core::FileSet - collection of files to be processed

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PARAMETERS

=head2 config

Configuration object: must provide C<jobs>, C<base_dir>, and C<filenames> attributes

=cut

has config => (
    is       => 'ro',
    isa      => HasMethods [qw< jobs base_dir filenames >],
    required => 1,
);

=head1 ATTRIBUTES

=head2 files

Arrayref of L<Vitruvius::Core::SourceFile>, built from given filenames

=cut

has files => (
    is      => 'ro',
    lazy    => 1,
    isa     => ArrayRef [ VtvSourceFile ],
    builder => '_build_files',
);

sub _build_files {
    my $self = shift;

    my $config = $self->config;

    my $base_dir  = $config->base_dir;
    my $jobs      = $config->jobs;
    my $filenames = $config->filenames;

    my $files;

    parallelize(
        log        => $self->log,
        jobs       => $jobs,
        message    => "Reading " . scalar(@$filenames) . " files",
        input      => $filenames,
        single_sub => sub {
            $files = [ map { Vitruvius::Core::SourceFile->new( base_dir => $base_dir, file => $_ ) } @$filenames ];
        },
        child_sub => sub {
            my $filenames = shift;

            my $job_files = [];

            for my $filename (@$filenames) {
                my $file = Vitruvius::Core::SourceFile->new(
                    base_dir => $base_dir,
                    file     => $filename,
                );
                $file->tree->nodes;    # force all parsing and building to be done in parallel
                push @$job_files, $file;
            }

            return $job_files;
        },
        finish_sub => sub {
            my $return = shift;
            push @$files, @$return;
        },
    );

    return $files;
}

1;
__END__

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
