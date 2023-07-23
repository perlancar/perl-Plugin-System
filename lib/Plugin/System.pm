## no critic: TestingAndDebugging::RequireUseStrict
package Plugin::System;

# AUTHORITY
# DATE
# DIST
# VERSION

1;
# ABSTRACT: An opinionated plugin system for your Perl framework/application

=head1 SYNOPSIS

 package Your::Framework;
 use Plugin::System;

 Plugin::System->init_plugin_system(

     # optional, default to caller package (i.e. in this case, Your::Framework)
     namespace => 'Your::Framework::Plugin',

     # required, list of known events
     events => {
         check_input => { ... },
         output => { ... },
         ...
     },
     ...

 );

 sub bar {
     ...
     __PACKAGE__->run_event_with_plugins(
         event => 'check_input',
         # req_handler => 0,                         # optional
         # run_all_handlers => 1,                    # optional
         # allow_before_handler_to_skip_rest => 1,   # optional
         # allow_handler_to_skip_rest => 1,          # optional
         # allow_handler_to_repeat_event => 1,       # optional
         # allow_after_handler_to_skip_rest => 1,    # optional
         # allow_after_handler_to_repeat_event => 1, # optional
         # stop_after_first_handler_failure => 1,    # optional
     );
 }

 1;

Afterwards, your framework can use the plugin system, e.g.:

 # a plugin module, containing handlers and meta information
 package Your::Framework::Plugin::Foo;

 sub plugin_meta {
     return +{ priority => ..., };
 }

 sub new {
     my ($self, %args) = @_;
     ...
 }

 # required handler if we want to handle the 'check_input' event
 sub on_check_input {
     ...

     # plugin can signal success by returning [200] or error by returning [4xx]
     # or [5xx] status. it can also return [201] to instruct run_event() to skip
     # calling the rest of the plugins for the event. it can also return [204]
     # to "decline".
 }

 # a before_ handler is optional
 sub before_check_input {
     my ($self, $r) = @_;
     ...

     # plugin can instruct to cancel the event by returning [601].
 }

 # an after_ handler is optional
 sub after_check_input {
     my ($self, $r) = @_;
     ...
     # plugin can instruct to repeat an event by returning [602].
 }

 1;

To use the plugin, user can activate it:

 use Your::Framework 'Foo' => {arg=>..., arg2 => ...};


=head1 DESCRIPTION

B<NOT YET IMPLEMENTED. A NAME GRAB ONLY.>

A plugin approach offers flexibility. Users can enable or disable plugins which
they need, sometimes also in the order that they want. Each plugin can supply
behavior at various points (events) in an application. More than one plugin
(also multiple instances of the same plugin) can supply behavior for a single
event. In addition, a plugin can modify the flow of the application by aborting
or repeating an event.


=head1 SEE ALSO

L<Module::Pluggable> and its variants like L<Module::Pluggable::Fast>.

=cut
