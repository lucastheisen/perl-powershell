use strict;
use warnings;

package PowerShell;

# ABSTRACT: Wraps PowerShell commands;
# PODNAME: PowerShell

use Carp;
use Encode;
use Log::Any;
use MIME::Base64;
use POSIX qw(WIFEXITED WEXITSTATUS);
use PowerShell::Pipeline;

my $logger = Log::Any->get_logger();

sub new {
    return bless({}, shift)->_init(@_);
}

sub command {
    my ($self) = @_;

    my $encoded_command = MIME::Base64::encode_base64(
            Encode::encode('UTF-16LE', $self->{pipeline}->command()),
            '');
    return "powershell -EncodedCommand $encoded_command";
}

sub execute {
    my ($self) = @_;

    my $powershell_command = $self->command();
    $logger->debugf('running [%s]', $powershell_command);
    my $result = `$powershell_command 2> /dev/null`;

    if (WIFEXITED(${^CHILD_ERROR_NATIVE})) {
        my $exit_status = WEXITSTATUS(${^CHILD_ERROR_NATIVE});
        if ($exit_status) {
            croak("[$powershell_command] failed: $exit_status");
        }
    }
    else {
        croak("[$powershell_command] exited abnormally");
    }
    
    return $result;
}

sub _init {
    my ($self, @rest) = @_;

    if (ref($rest[0]) && $rest[0]->isa('PowerShell::Pipeline')) {
        $self->{pipeline} = $rest[0];
    }
    else {
        $self->{pipeline} = PowerShell::Pipeline->new()
            ->add(@rest);
    }

    return $self;
}

sub pipe_to {
    my ($self, @rest) = @_;
    $self->{pipeline}->add(@rest);
    return $self;
}

1;

__END__

=head1 SYNOPSIS

    use PowerShell;

    # Minimally
    PowerShell
        ->new('Mount-DiskImage, 
            ['Image' => 'C:\\tmp\\foo.iso'], 
            ['StorageType' => 'ISO'])
        ->pipe_to('Get-Volume')
        ->execute();

    # Or explicitly
    PowerShell
        ->new(
            PowerShell::Pipeline
                ->new(
                    PowerShell::Cmdlet
                        ->new('Mount-DiskImage')
                        ->parameter('Image', 'C:\\tmp\\foo.iso')
                        ->parameter('StorageType', 'ISO'))
                ->add(
                    PowerShell::Cmdlet
                        ->new('Get-Volume')))
        ->execute();

    # Or just get the command
    my $command = PowerShell
        ->new('Mount-DiskImage', [Image => 'C:\\tmp\\foo.iso'])
        ->command();

    # and execute it yourself
    my $result = `$command`;


=head1 DESCRIPTION

I know, I know, why would you want a scripting language to wrap a scripting
language...  In the real world, it happens.  This can be really useful for
automation that needs to do things that are exposed via PowerShell that would
otherwise require jumping through more extensive hoops.  It can also be 
quite useful when ssh'ing to a remote system to execute PowerShell commands.
Anyway, the intent of this module is to simplify that use case.

=constructor new($command, [@cmdlet_parameters])

Creates a new PowerShell command wrapper.  C<$command> is either a 
L<PowerShell::Pipeline>, a L<PowerShell::Cmdlet>, or a string containing a
cmdlet name.  If a string containing a cmdlet name, then C<@cmdlet_parameters>
contains the parameters to that cmdlet.

=method command()

Returns a string form of the command.

=method execute()

Executes the command.

=method pipe_to($cmdlet, [@cmdlet_parameter)

Pipes the output to C<$cmdlet>.

=head1 SEE ALSO

PowerShell::Cmdlet
PowerShell::Pipeline
https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting

