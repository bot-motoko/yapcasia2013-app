package YAPC2013::API::HRForecast;
use Moo;
use POSIX ();

with 'YAPC2013::API::WithContainer';

has 'hf_url' => (is => 'ro');

sub record {
    my ($self, $service, $section, $graph, $count, $epoch) = @_;

    $epoch ||= time();
    my $furl = $self->get('Furl');
    my $url = sprintf
        '%s/api/%s/%s/%s',
        $self->hf_url,
        $service,
        $section,
        $graph,
    ;

    $furl->post($url, [], [
        number => $count, 
        datetime => POSIX::strftime("%Y-%m-%d %H:%M", localtime($epoch)),
    ]);
}

no Moo;

1;
