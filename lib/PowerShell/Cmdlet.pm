use strict;
use warnings;

package PowerShell::Cmdlet;

# ABSTRACT: Wraps a generic cmdlet
# PODNAME: PowerShell::Cmdlet

sub new {
    return bless({}, shift)->_init(@_);
}

sub command {
    my ($self) = @_;

    unless ($self->{command}) {
        my @parts = ($self->{name});
        foreach my $parameter (@{$self->{parameters}}) {
            if (scalar(@$parameter) == 2) {
                push(@parts, "-$parameter->[0] '$parameter->[1]'")
            }
            else {
                push(@parts, "'$parameter->[0]'")
            }
        }
        $self->{command} = join(' ', @parts);
    }

    return $self->{command};
}

sub _init {
    my ($self, $name) = @_;

    $self->{name} = $name;
    $self->{parameters} = [];

    return $self;
}

sub parameter {
    my ($self, @parameter) = @_;

    my $parts = scalar(@parameter);
    if ($parts == 1 ) {
        push(@{$self->{parameters}}, [$parameter[0]]);
    }
    elsif ($parts == 2) {
        push(@{$self->{parameters}}, [$parameter[0] => $parameter[1]]);
    }

    return $self;
}

1;

__END__

=head1 SYNOPSIS

    use PowerShell::Cmdlet;

    # Minimally
    my $command = PowerShell::Cmdlet->new('Mount-DiskImage') 
        ->parameter('Image', 'C:\\tmp\\foo.iso')
        ->parameter('StorageType', 'ISO');

    # Then add it to a pipeline
    $pipeline->add($command);

    # Or pipe a powershell pipeline to it
    $powershell->pipe_to($command);

    # Or just print it out
    print('running [', $command->command(), "]\n");

=head1 DESCRIPTION

Represents a generic cmdlet.  Can be used as is for most situations, or can be
extended to provide a cmdlet specific interface.

=constructor new($name)

Creates a new cmdlet for C<$name>.

=method command()

Returns a string form of the command.

=method parameter([$name], $value)

Adds a parameter to the cmdlet.  If name is supplied, it will be a named 
parameter.  For example:

    PowerShell::Cmdlet('Mount-DiskImage')
        ->parameter('Image' => 'C:\\tmp\\foo.iso');

would result in:

    Mount-DiskImage -Image 'C:\tmp\foo.iso'

If C<$name> is not supplied, the value will be added by itself:

    PowerShell::Cmdlet('Get-Volume')
        ->parameter('E');

would result in:

    Get-Volume 'E'

=head1 SEE ALSO

PowerShell
PowerShell::Pipeline
https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting

