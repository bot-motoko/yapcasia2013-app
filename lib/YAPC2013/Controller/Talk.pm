package YAPC2013::Controller::Talk;
use Mojo::Base 'YAPC2013::Controller::CRUD';
use YAPC2013::Constants;

sub list {
    my $self = shift;

    my $talk_api = $self->get('API::Talk');
    my $member_api = $self->get('API::Member');

    my $applied_talks = $talk_api->search(
        {},
        { order_by => "created_on DESC" },
    );

    foreach my $talk ( @$applied_talks ){
        $talk->{speaker} = $member_api->lookup( $talk->{member_id} );
    }

    $self->render( applied_talks => $applied_talks );
}

sub show {
    my $self = shift;

    $self->SUPER::show();

    if (my $talk = $self->stash->{talk}) {
        my $speaker = $self->get('API::Member')->lookup($talk->{member_id});
        if (my $member = $self->get_member) {
            if ($talk->{member_id} eq $member->{id}) {
                $self->stash( owner => 1 );
            }
        }

        my $venue = VENUE_ID->{ $talk->{venue_id} };
        if ($venue) {
            $talk->{venue} = $venue;
        }

        $talk->{speaker} = $speaker;
        $self->stash(
            speaker => $speaker,
        );
    }

    if (my $format = $self->req->param('format')) {
        if ($format eq 'json') {
            # protect some speaker information
            my $talk = $self->stash->{talk};
            my $speaker = $talk->{speaker};
            local $speaker->{authenticated_by};
            local $speaker->{email};
            local $speaker->{is_admin};
            local $speaker->{remote_id};
            delete $speaker->{$_} for qw(authenticated_by email is_admin remote_id);

            $self->render_json( $talk );
        }
    }
}

sub input {
    my $self = shift;
    my $member = $self->assert_email or return;

    # if this is a submission for LT, then we need to switch profile and
    # template that we use here
    my $is_lt = $self->req->param('lt');
    if ($is_lt) {
        $self->stash(
            template => "talk/input_lt",
        );
    } elsif (0 && $member->{is_admin}) {
        $self->render("No auth");
        $self->rendered(403);
        return;
    }

    $self->SUPER::input();

    if (my $start_on = $self->stash->{fif}->{start_on} ) {
        my($date, $time) = split / /, $start_on;
        $self->stash->{fif}->{start_on_date} = $date;
        $self->stash->{fif}->{start_on_time} = $time;
    }
}

sub edit {
    my $self = shift;
    my $member = $self->assert_email or return;
    my $id = $self->match->captures->{object_id};
    my $object = $self->load_object( $id );
    if (! $object) {
        $self->render_not_found();
        return;
    }

    if ($member->{id} ne $object->{member_id} && !$member->{is_admin}) {
        $self->render("No auth");
        $self->rendered(403);
        return;
    }

    my $is_lt = $self->req->param('lt');
    if ($is_lt) {
        $self->stash(
            profile  => "talk_lt.check",
        )
    }

    $self->SUPER::edit();

    if (my $start_on = $self->stash->{fif}->{start_on} ) {
        my($date, $time) = split / /, $start_on;
        $self->stash->{fif}->{start_on_date} = $date;
        if ($time !~ /^00:00:00$/) {
            $self->stash->{fif}->{start_on_time} = $time;
        }
    }
    if ($is_lt) {
        $self->stash(
            template => "talk/input_lt",
        );
    } else {
        $self->stash(
            template => "talk/input",
        );
    }

}

sub check {
    my $self = shift;
    my $member = $self->assert_email or return;

    # LT
    my $is_lt = $self->req->param('lt');
    if ($is_lt) {
        $self->stash(
            profile  => "talk_lt.check",
        )
    }
    $self->SUPER::check();

    if ($is_lt) {
        $self->stash(
            template => "talk/input_lt",
        );
    }
}

sub preview {
    my $self = shift;
    my $member = $self->assert_email or return;
    $self->SUPER::preview();
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
    delete $data->{start_on_date};
    delete $data->{start_on_time};

    $self->SUPER::commit();
}

1;
