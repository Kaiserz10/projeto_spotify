import 'package:flutter/material.dart';

import 'dart:core';
import 'dart:math';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'constants.dart';

class MusicPlayer extends ChangeNotifier {
  Duration musica = Duration.zero;

  final Set<String> playlistName = {};
  final Set<String> artistImage = {};
  final Set<String> songList = {};

  final List<String> imageList = [];

  final Map<String, List<String>> artistName = {};
  final Map<String, AudioSource> mapSongURL = {};
  final Map<String, Duration> mapDuration = {};

  String actualSong = '';

  int songIndex = 0;

  int newSong = 0;

  int repeatType = 0;

  bool repeat = false;
  bool shuffle = false;
  bool autoPlay = false;

  final player = AudioPlayer();

  Future<void> provisorio() async {}

  String textArtists(List<String> listArtists) {
    String artistName = '';
    for (var value in listArtists) {
      artistName += '$value, ';
    }
    artistName = artistName.replaceRange(artistName.length - 2, null, '');
    return artistName;
  }

  Widget progressBar(double width, Function loadingMaster) {
    Duration minDuration = const Duration(milliseconds: 1);

    return SizedBox(
      width: width * 0.80,
      child: StreamBuilder(
        stream: player.positionStream,
        builder: (context, data) {
          musica = data.data ?? Duration.zero;

          if (shuffle || autoPlay) {
            minDuration = const Duration(milliseconds: 1);
          } else {
            minDuration = Duration.zero;
          }

          if (musicaCompletada()) {
            if (repeat) {
              player.seek(Duration.zero);
            } else if (shuffle) {
              provisorio().then((value) => loadingMaster(true));

              shuffleOn().then((value) {
                loadingMaster(false);
              });
            } else if (autoPlay) {
              provisorio().then((value) => loadingMaster(true));

              autoPlayOn().then((value) {
                loadingMaster(false);
              });
            } else if (player.playing) {
              player.pause().then((value) => loadingMaster(false));
            }
          }

          return ProgressBar(
            progress: musica,
            total: (mapDuration[songList.elementAt(songIndex)] == null)
                ? Duration.zero
                : (mapDuration[songList.elementAt(songIndex)]! -
                    const Duration(seconds: 1)),
            buffered: player.bufferedPosition,
            bufferedBarColor: Colors.grey,
            baseBarColor: Colors.white,
            thumbColor: Constants.color,
            thumbRadius: 7,
            timeLabelTextStyle: const TextStyle(color: Colors.white),
            progressBarColor: Constants.color[900],
            onSeek: (duration) async {
              loadingMaster(true);
              await player.seek(duration - minDuration);
              loadingMaster(false);
            },
          );
        },
      ),
    );
  }

  Future<void> changeMusic() async {
    // checa se a música existe no mapSongURL
    if (!mapSongURL.containsKey(songList.elementAt(songIndex))) {
      await getUrlMusic(songList.elementAt(songIndex), artistName);
      // checa se a música sendo tocada é a nova;
    } else if (actualSong != songList.elementAt(songIndex)) {
      await setAudioSource(songList.elementAt(songIndex));
    }
  }

  Future<void> autoPlayOn() async {
    if (songIndex < songList.length - 1) {
      songIndex += 1;
    } else {
      songIndex = 0;
    }

    await changeMusic().then((value) async {
      await player.seek(Duration.zero);
      player.play();
    });
  }

  bool musicaCompletada() {
    if (mapDuration[songList.elementAt(songIndex)] != null) {
      return musica.inSeconds ==
          (mapDuration[songList.elementAt(songIndex)]!.inSeconds - 1);
    } else {
      return false;
    }
  }

  Future<void> shuffleOn() async {
    int newMusic = Random().nextInt(songList.length);

    while (newMusic == songIndex) {
      newMusic = Random().nextInt(songList.length);
    }
    songIndex = newMusic;

    await changeMusic().then((value) async {
      await player.seek(Duration.zero);
      player.play();
    });
  }

  Future<void> getUrlMusic(
      String musicName, Map<String, List<String>> nameArtists) async {
    actualSong = musicName;

    String nameArtist = textArtists(nameArtists[musicName]!);

    int indexVideos = 0;
    final yt = YoutubeExplode();

    while (true) {
      try {
        final video = (await yt.search
            .search("$musicName $nameArtist música"))[indexVideos];

        if (video.duration == null) {
          indexVideos++;
          continue;
        }
        if (video.duration! > const Duration(minutes: 20)) {
          indexVideos++;
          continue;
        }

        final videoId = video.id.value;
        mapDuration.addAll({musicName: video.duration!});

        var manifest = await yt.videos.streamsClient.getManifest(videoId);
        var audioUrl = manifest.audioOnly.last.url;

        mapSongURL.addAll({musicName: AudioSource.uri(audioUrl)});
        break;
      } catch (error) {
        List<String> separado = nameArtist.split(',');
        nameArtist = separado[0];
      }
    }
    await setAudioSource(musicName);
    notifyListeners();
  }

  Future<void> setAudioSource(String musicName) async {
    actualSong = musicName;

    await player.setAudioSource(mapSongURL[musicName]!);
    notifyListeners();
  }

  Future<void> play() async {
    if (!player.playing) {
      player.play();
    } else {
      await player.pause();
    }
    notifyListeners();
  }

  Future<void> passMusic(String lado) async {
    player.stop();
    if (lado == 'Left') {
      songIndex -= 1;
    }
    if (lado == 'Right') {
      songIndex += 1;
    }
    notifyListeners();
  }
}
