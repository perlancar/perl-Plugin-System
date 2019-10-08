package Plugin::System;

# DATE
# VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger;

1;
# ABSTRACT: An opinionated plugin+hooks system for your Perl module/application

=head1 SYNOPSIS

In your main module:

 package My::App;
 use Plugin::System qw(perform_action_with_plugins);

 sub suspend_user {
     my ($self, $r) = @_;

     perform_action_with_plugins(
         # name of the hook. by default, will take caller()'s name (in this
         # case, also 'suspend_user').
         hook_name => 'suspend_user',

         # list of plugins to include. if not specified, will take caller's
         # package (in this case, 'My::App'), add '::Plugin' to it, and list and
         # include all modules under that namespace. in other words, will
         # include all installed plugins.
         #
         # if you want to exclude some installed modules, use modules from
         # another namespace, or use several instances of the same module, you
         # can specify an array of module names or module instances here. you
         # can also set $main::Plugins instead of passing list of plugins here.
         plugins     => $plugins, # e.g. ['My::App::Plugin::Foo', bless('My::App::Plugin::Bar', {config=>{path=>'/path1'}}), bless('My::App::Plugin::Bar', {config=>{path=>'/path2'}})]

         # what arguments to pass to each plugin's hook handler. if not
         # specified, plugin will get $stash, which is a hashref passed from
         # plugin to plugin and containing some information (see STASH).
         args        => [$self, $r],

         # other hook to run before performing our hook. by default, will not
         # run a before hook. can also be set to just '1' which means to use
         # 'before_' + hook_name (in this case, also 'before_suspend_user'). the
         # before hook can abort the main hook if a hook returns XXX.
         before_hook => 'before_suspend_user',

         # code to perform action for the hook. required.
         action => sub {
             ...
         },

         # other hook to run after performing our hook. by default, will not
         # run a before hook. can also be set to just '1' which means to use
         # 'before_' + hook_name (in this case, also 'before_suspend_user').
         before_hook => 'before_suspend_user',
     );
 }

 sub unsuspend_user {
     my ($self, $r) = @_;

     perform_action_with_plugins(
         args => \@_,
         before_hook => 1,
         action => sub { ... },
         after_hook => 1,
     );
 }


=head1 DESCRIPTION

A plugin approach offers flexibility. Users can enable or disable plugins which
they need, sometimes also in the order that they want. Each plugin can supply
behavior at various points (hooks) in an application. More than one plugin (also
multiple instances of the same plugin) can supply behavior for a single hook. In
addition, a plugin can modify the flow of the application by aborting or
repeating a hook.


=head1 SEE ALSO

L<Module::Pluggable> and its variants like L<Module::Pluggable::Fast>.

=cut
