package YAPC2013::Controller::Event;
use Mojo::Base 'YAPC2013::Controller::CRUD';

sub index { $_[0]->redirect_to("/2013/event/list") }

sub input {
    my $self = shift;
    my $member = $self->assert_email or return;

    $self->SUPER::input(@_);
}

sub commit {
    my $self = shift;
    my $member = $self->assert_email or return;
    my $data = $self->load_from_subsession();
    if (! $data) {
        $self->subsession_not_found();
        return;
    }

    if (! $data->{is_edit}) {
        $data->{member_id} = $member->{id};
    }
    local $data->{start_on_date};
    local $data->{start_on_time};
    local $data->{start_on} = $data->{start_on};
    if (! $data->{start_on}) {
        delete $data->{start_on};
    }

    my $start_on;
    my $start_on_date = delete $data->{start_on_date};
    my $start_on_time = delete $data->{start_on_time};
    if ($start_on_date) {
        $data->{start_on} = sprintf(
            "%s %s",
            $start_on_date,
            $start_on_time || '00:00'
        );
    }
    $self->SUPER::commit();
}

1;