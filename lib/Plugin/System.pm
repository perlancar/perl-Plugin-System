## no critic: TestingAndDebugging::RequireUseStrict
package Plugin::System;

#IFBUILT
use strict 'subs', 'vars';
use warnings;
#END IFBUILT

# AUTHORITY
# DATE
# DIST
# VERSION

our $re_addr = qr/\(0x([0-9a-f]+)/o;

our %Target_Packages;      # key=package name, value=1
our %Per_Package_Handlers; # key=package name, value={ $event=>$hooks, ... }

my $sub0 = sub {0};
my $sub1 = sub {1};

sub install_routines {
    my ($target_pkg, $routines) = @_;

    if (!defined &subname) {
        #if (eval { require Sub::Name; 1 }) {
        #    *subname = \&Sub::Name::subname;
        #} else {
            *subname = sub {};
        #}
    }

    for my $r (@$routines) {
        my ($code, $name) = @$r;
        *{"$target_pkg\::$name"} = $code;
        subname("$target_pkg\::$name", $code);
    }
}

sub add_target {
    my ($pkg, %args) = @_;

    # check arguments
    my $events = delete $args{events} or die "Please specify 'events' argument";
    for (keys %$events) { /\A\w+\z/ or die "Invalid syntax in event name '$_', please use alphanumeric only" };

    keys %args and die "Unknown argument(s): ".join(", ", sort keys %args);

    # if already defined, overwrite previous configuration
    $Target_Packages{$pkg} = {events => $events};
}

sub init_target {
    my $pkg = shift;

    my $args = $Target_Packages{$pkg} or die "Package '$pkg' has not been added as target yet";

    my $routines = [];
    for my $event (keys %{ $args->{events} }) {
        push @$routines, [sub(;&@) { 1 }, "event_$event"];
    }
    install_routines($pkg, $routines);
}

sub _import_to {
    my $pkg = shift;
    my $target_pkg = shift;

    add_target($target_pkg, @_);
    init_target($target_pkg);
}

sub import {
    my $pkg = shift;

    my $caller = caller(0);
    $pkg->_import_to($caller, @_);
}

1;
# ABSTRACT: A plugin system for your Perl framework or application

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

=head2 Use in framework

In your F<lib/Your/Framework.pm>:

 package Your::Framework;
 use Plugin::System;

 use Plugin::System (
     # optional, default to caller package (i.e. in this case, Your::Framework)
     #app => 'Your::Framework',

     # optional, namespace to search for the plugins, default to ${app}::Plugin.
     # can also be an arrayref to search in multiple namespaces.
     plugin_ns => 'Your::FrameworkX',

     # required, list of known events along with their specification
     events => {
         check_input => { ... },
         output => { ... },
         ...
     },
     ...

 );

 # after this, Plugin::System will install event_XXX(;&@) routines for each
 # defined event so you can use them:

 sub run {
     my %args = @_;

     my $res = event_check_input {
         # the code block for an event. plugins can run before and/or after this
         # block. a "before" plugin can ask to skip this block. an "after"
         # plugin can ask to repeat this block.
         check_args(%args);
     };
     # the event will return the result of the code block or, if configured, the
     # result of the first handler that returns result.

     # this event does not provide the main call block. the event might require
     # there is at least one plugin that installs a handler for this event.
     event_output;
 }

 1;

=head2 Plugin code

In your F<lib/Your/FrameworkX/Foo.pm>:

 package Your::FrameworkX::Foo;

 sub meta {
     # must return a DefHash, see DefHash specification
     return +{
         # optional, default priority for all handlers (0-100), defaults to 50
         #prio => ...,

         # optional, define arguments/configuration parameters that your plugin
         # recognizes
         args => {
             # a DefHash
             arg1 => {
                 # a DefHash
                 summary => 'Blah blah ...',
                 schema => 'str*', # a Sah schema
                 req => 0,
                 ...
             },
         },
     };
 }

 sub new {
     my ($self, %args) = @_;
     ...
 }

 # required handler if we want to handle the 'check_input' event
 sub on_check_input {
     ...

     # plugin can signal success by returning 200 or error by returning 4xx or
     # 5xx status. it can also return 201 to instruct to skip calling the rest
     # of the handlers for the event. it can also return 204 to "decline".

     # a handler can be configured to return (replace) the result of the
 }

 # metadata for the 'check_input' handler. required.
 sub meta_on_check_input {
     return +{ prio => ..., ... };
 }

 # a before_ handler is optional
 sub before_check_input {
     my ($self, $r) = @_;
     ...

     # plugin can instruct to cancel the event by returning 601.
 }

 # required if before_check_input is defined
 sub meta_before_check_input { ... }

 # an after_ handler is optional
 sub after_check_input {
     my ($self, $r) = @_;
     ...
     # plugin can instruct to repeat an event by returning 602.
 }

 # required if after_check_input is defined
 sub meta_after_check_input { ... }

 1;

=head2 Using plugins for users

You can use L<Plugin::System::Exporter>, e.g. in F<lib/Your/Framework.pm>:

 package Your::Framework;
 ...
 use Plugin::System::Exporter (
     # optional, see Synopsis/Use in framework
     # app => 'Your::Framework',

     # optional, see Synopsis/Use in framework
     plugin_ns => 'Your::FrameworkX',
 );

so your users can activate plugins this way:

 use Your::Framework 'Foo' => {arg1=>..., arg2 => ..., ...};


=head1 GLOSSARY

=head2 Event

A named point in code. L<Plugin|/Plugin>s can define L<handler|/Handler>s to add
behaviors for an event. An event can also contain the main code block. When no
handlers are registered for an event, only the main code block will be executed
and the result returned. When there are handlers, the handler can add behavior
before+after the main code block, and can also replace or remove the execution
of the main code block.

=head2 Main code block

The code to be executed by default during an event. See L</Event>.

=head2 Handler

Code to execute for an L<event|/Event>. Handlers are supplied by
L<plugin|/Plugin>s.

=head2 Plugin

A module defining a class which provides methods to generate
L<handler|/Handler>s for L<event|/Event>s. In B<Plugin::System>, the user can
also register plugin from another application/framework (as long as it also uses
Plugin::System). The user can also customize the target event and
L<priority|/Priority> of handlers from the plugin.

=head2 Priority

A number between 0 and 100 to specify order of execution of L<handler|/Handler>s
for an event. Smaller number means higher priority (earlier execution). If two
handlers have the same priority, then handlers registered first will be executed
first.

=head2 Target package

The package which C<use>s C<Plugin::System> and defines the L<event|/Event>s it
wants to have. Plugin::System will install the event subroutines (by default
C<event_NAME>s) to this package.

=head2 Registration

The act of loading a plugin then adding the handlers it provides to a target
package.

=head2 Initialization

The process of generating the event subroutines for a target package.


=head1 DESCRIPTION

A plugin approach offers flexibility. Users can enable or disable plugins which
they need, in the order that they want. Each plugin can supply behavior at
various code points (events) in an application. More than one plugin (also
multiple instances of the same plugin) can supply behavior for a single event.

This module, B<Plugin::System>, offers a fast, highly flexible plugin system
with a (hopefully) nice syntax. A plugin can modify the flow of the application
by skipping (aborting) or repeating an event. For all features of this plugin
system, see L<Plugin::System::_ModuleFeatures>.


=head1 IMPORT ARGUMENTS

Plugin::System accepts a key-value pairs of arguments. Known arguments:

=head2 events

Define known events.

=head2


=head1 SEE ALSO

Other plugin systems: L<Module::Pluggable> and its variants like
L<Module::Pluggable::Fast>. See comparison and benchmarks at
L<Acme::CPANModules::PluginSystems>.

Examples of frameworks using Plugin::System: L<Require::HookPlugin>, L<ScriptX>,
L<Data::DumpX>.

=cut
