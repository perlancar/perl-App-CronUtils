package App::CronUtils;

# DATE
# VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to cron & crontab',
};

my %arg_file = (
    file => {
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

my %argopt_parser = (
    parser => {
        schema => ['str*', in=>[qw/Parse::Crontab Pegex::Crontab/]],
        default => 'Parse::Crontab',
    },
);

$SPEC{parse_crontab} = {
    v => 1.1,
    summary => "Parse crontab file into data structure",
    description => <<'_',

Will return 500 status if there is a parsing error.

Resulting data structure can be different depending on the parser selected.

_
    args => {
        %arg0_file,
        %argopt_parser,
    },
};
sub parse_crontab {
    require File::Slurper::Dash;

    my %args = @_;
    my $parser = $args{parser} // 'Parse::Crontab';

    my $crontab_str = File::Slurper::Dash::read_text($args{file});

    my $crontab_data;
    if ($parser eq 'Parse::Crontab') {
        require File::Temp;
        require Parse::Crontab;
        my ($tmp_fh, $tmp_path) = File::Temp::tempfile();
        File::Slurper::Dash::write_text($tmp_path, $crontab_str);
        my $parser = Parse::Crontab->new(verbose=>1, file=>$tmp_path);
        unless ($parser->is_valid) {
            return [500, "Can't parse $args{file}: " . $parser->error_messages];
        }
        $crontab_data = [];
        for my $job ($parser->jobs) {
            push @$crontab_data, {
                minute =>  $job->minute,
                hour => $job->hour,
                day => $job->day,
                month => $job->month,
                day_of_week => $job->day_of_week,
                command => $job->command,
            };
        }
        return [200, $crontab_data];
    } elsif ($parser eq 'Pegex::Crontab') {
        require Pegex::Crontab;
        $crontab_data = Pegex::Crontab->new->parse($crontab_str);
        return [200, "OK", $crontab_data];
    } else {
        return [400, "Unknown parser '$parser'"];
    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS


=head1 DESCRIPTION

This distribution includes the following CLI utilities related to cron &
crontab:

#INSERT_EXECS_LIST
