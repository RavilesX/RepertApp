import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _buttonPlayer = AudioPlayer(playerId: 'button');
  final AudioPlayer _okPlayer = AudioPlayer(playerId: 'ok');

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> button() => _play(_buttonPlayer, 'sounds/button.mp3');
  Future<void> ok() => _play(_okPlayer, 'sounds/ok.mp3');
}
