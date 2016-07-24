use strict;
use warnings;

package PowerShell::Pipeline;

# ABSTRACT: Wraps powershell cmdlet pipeline
# PODNAME: PowerShell::Pipeline

use Carp;
use PowerShell::Cmdlet;

sub new {
    return bless({}, shift)->_init(@_);
}

sub add {
    my ($self, $cmdlet, @parameters) = @_;

    delete($self->{command}); #clear cached command

    unless (ref($cmdlet) && $cmdlet->isa('PowerShell::Cmdlet')) {
        $cmdlet = PowerShell::Cmdlet->new($cmdlet);
        foreach my $parameter (@parameters) {
            my $ref = ref($parameter);
            if (!$ref || $ref eq 'SCALAR') {
                $cmdlet->parameter($parameter);
            }
            elsif ($ref eq 'ARRAY' && scalar(@$parameter) == 2) {
                $cmdlet->parameter(@$parameter);
            }
            else {
                croak('inline parameters must be name value array ref, or scalar value');
            }
        }
    }

    push(@{$self->{pipeline}}, $cmdlet);

    return $self;
}

sub _init {
    my ($self) = @_;

    $self->{pipeline} = [];

    return $self;
}

sub command {
    my ($self) = @_;
    unless ($self->{command}) {
        $self->{command} = join('|', map {$_->command()} @{$self->{pipeline}});
    }
    return $self->{command};
}

1;

__END__

=head1 SYNOPSIS

    use PowerShell::Pipeline;

    # Minimally
    my $pipeline = PowerShell::Pipeline->new()
        ->add('Mount-DiskImage', 
            ['Image', 'C:\\tmp\\foo.iso'], 
            ['StorageType', 'ISO'])
        ->add('Get-Volume');
        ->add('Select', ['ExpandProperty', 'Name']);

    # Then execute with powershell
    PowerShell->new($pipeline)->execute();

    # Or just print it out
    print('pipeline [', $pipeline->command(), "]\n");

=head1 DESCRIPTION

Represents a pipeline of cmdlets.

=constructor new()

Creates a new pipeline for cmdlets.

=method add($cmdlet, [@parameters])

Adds C<$cmdlet> to the end of the pipeline.  If C<$cmdlet> is a string, it
will be passed on to the constructor of C<PowerShell::Cmdlet> and 
C<parameter> will be called for each of the supplied parameters.

=method command()

Returns a string form of the pipeline.

=head1 SEE ALSO

PowerShell
PowerShell::Cmdlet
https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting

