#############################################################################
#  OpenKore - Network subsystem												#
#  This module contains functions for sending messages to the server.		#
#																			#
#  This software is open source, licensed under the GNU General Public		#
#  License, version 2.														#
#  Basically, this means that you're allowed to modify and distribute		#
#  this software. However, if you distribute modified versions, you MUST	#
#  also distribute the source code.											#
#  See http://www.gnu.org/licenses/gpl.html for the full license.			#
#############################################################################
# bRO (Brazil)
package Network::Send::bRO;
use strict;
use base qw(Network::Send::ServerType0);
use Log qw(debug);
use Globals qw($rodexWrite $char);
use I18N qw(stringToBytes);


sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'098F' => ['char_delete2_accept', 'v a4 a*', [qw(length charID code)]],
		'0A6E' => ['rodex_send_mail', 'v Z24 Z24 V2 v v V a* x a* x', [qw(len receiver sender zeny1 zeny2 title_len body_len char_id title body)]],   # -1 -- RodexSendMail
	);

	$self->{packet_list}{$_} = $packets{$_} for keys %packets;

	my %handlers = qw(
		master_login 02B0
		buy_bulk_vender 0801
		party_setting 07D7
		send_equip 0998
		pet_capture 08B5
		char_delete2_accept 098F
		rodex_open_mailbox 0AC0
		rodex_refresh_maillist 0AC1
		rodex_send_mail 0A6E
	);
	
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	$self->{send_buy_bulk_pack} = "v V";
	$self->{char_create_version} = 0x0A39;
	
	return $self;
}

sub reconstruct_char_delete2_accept {
	my ($self, $args) = @_;

	$args->{length} = 8 + length($args->{code});
	debug "Sent sendCharDelete2Accept. CharID: $args->{charID}, Code: $args->{code}, Length: $args->{length}\n", "sendPacket", 2;
}

sub rodex_send_mail {
	my ($self) = @_;

	my $title = stringToBytes($rodexWrite->{title});
	my $body = stringToBytes($rodexWrite->{body});
	my $title_len = (length $title) + 1;
	my $body_len = (length $body) + 1;
	
	my $pack = $self->reconstruct({
		switch => 'rodex_send_mail',
		receiver => $rodexWrite->{target}{name},
		sender => stringToBytes($char->{name}),
		zeny1 => $rodexWrite->{zeny},
		zeny2 => 0,
		title_len => $title_len,
		body_len => $body_len,
		char_id => $rodexWrite->{target}{char_id},
		title => $title,
		body => $body,
	});

	$self->sendToServer($pack);
}

1;