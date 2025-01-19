import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' as sptf;

import 'package:projeto_spotify/Utils/music_player.dart';
import 'package:text_scroll/text_scroll.dart';
import 'whats_playing.dart';

import '../Utils/constants.dart';

class PlaylistStyle extends StatefulWidget {
  final String trackId;
  const PlaylistStyle({super.key, required this.trackId});

  @override
  State<PlaylistStyle> createState() => _PlaylistStyleState();
}

class _PlaylistStyleState extends State<PlaylistStyle> {
  final musicPlayer = MusicPlayer();

  bool loading = false;
  bool otherMusic = false;

  bool isPlaying = false;

  void loadingMaster(bool value) {
    setState(() => loading = value);
  }

  @override
  void initState() {
    final credentials =
        sptf.SpotifyApiCredentials(Constants.clientId, Constants.clientSecret);
    final spotify = sptf.SpotifyApi(credentials);

    spotify.playlists.get(widget.trackId).then((value) {
      musicPlayer.playlistName.add(value.name!);
      musicPlayer.artistImage.add(value.images!.first.url!);

      value.tracks?.itemsNative?.forEach((value) {
        List<String> saveArtistName = [];

        musicPlayer.songList.add(value['track']['name']);
        musicPlayer.imageList.add(value['track']['album']['images'][0]['url']);

        value['track']['artists'].forEach((artistas) {
          saveArtistName.add(artistas['name']);
        });
        musicPlayer.artistName.addAll({value['track']['name']: saveArtistName});
      });

      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    musicPlayer.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          musicPlayer.playlistName.elementAtOrNull(0) ?? '',
          style: TextStyle(color: Colors.white, fontSize: width * 0.055),
        ),
      ),
      body: Stack(
        children: [
          const SizedBox(height: double.infinity),
          Container(
            decoration: const BoxDecoration(color: Colors.black),
            padding: const EdgeInsets.all(5),
            width: double.infinity,
            height: isPlaying ? height * 0.727 : double.infinity,
            child: ListView.separated(
              itemCount: musicPlayer.songList.length,
              separatorBuilder: (BuildContext context, int index) =>
                  SizedBox(height: height * 0.01),
              itemBuilder: (BuildContext context, int index) {
                return musicPlayer.songList.isNotEmpty
                    ? Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                  color: Colors.white, fontSize: width * 0.05),
                            ),
                          ),
                          SizedBox(width: width * 0.02),
                          SizedBox(
                              width: width * 0.20,
                              height: height * 0.10,
                              child:
                                  Image.network(musicPlayer.imageList[index])),
                          SizedBox(width: width * 0.02),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: index < 9
                                    ? width * 0.50
                                    : index < 99
                                        ? width * 0.47
                                        : width * 0.45,
                                child: TextScroll(
                                  '${musicPlayer.songList.elementAt(index)}   ',
                                  velocity: const Velocity(
                                      pixelsPerSecond: Offset(90, 0)),
                                  intervalSpaces: 5,
                                  pauseBetween: const Duration(seconds: 2),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: height * 0.025,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: index < 9
                                    ? width * 0.50
                                    : index < 99
                                        ? width * 0.47
                                        : width * 0.45,
                                child: TextScroll(
                                  '${musicPlayer.textArtists(musicPlayer.artistName[musicPlayer.songList.elementAt(index)]!)} ',
                                  velocity: const Velocity(
                                      pixelsPerSecond: Offset(90, 0)),
                                  intervalSpaces: 5,
                                  pauseBetween: const Duration(seconds: 2),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: height * 0.025,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                            ),
                            onPressed: () async {
                              if (loading == true) {
                                return;
                              }

                              setState(() => loading = true);

                              musicPlayer.songIndex = index;

                              await musicPlayer.changeMusic();

                              // // caso o nome da música não esteja na lista mapSongURL
                              // // e seja diferente da que esta sendo tocada no momento
                              // if (!musicPlayer.mapSongURL.containsKey(
                              //     musicPlayer.songList.elementAt(index))) {
                              //   // muda a música atual para a nova;
                              //   musicPlayer.actualSong =
                              //       musicPlayer.songList.elementAt(index);
                              //   // para a música que está tocando
                              //   await musicPlayer.player.stop();
                              //   // coloca salva o index dá música e procura e salva no mapSongURL
                              //   // e a toca
                              //   await musicPlayer.getUrlMusic(
                              //       musicPlayer.songList.elementAt(index),
                              //       musicPlayer.artistName);
                              // } else if (musicPlayer.songList
                              //         .elementAt(index) !=
                              //     musicPlayer.actualSong) {
                              //   // muda a música atual para a nova;
                              //   musicPlayer.actualSong =
                              //       musicPlayer.songList.elementAt(index);
                              //   // caso a música esteja no mapSongURL e não é a que está tocando,
                              //   // para a música que está tocando
                              //   await musicPlayer.player.stop();
                              //   // inicia a música nova
                              //   await musicPlayer.setAudioSource(
                              //       musicPlayer.songList.elementAt(index));
                              // }

                              musicPlayer.play();
                              isPlaying = true;
                              setState(() => loading = false);
                            },
                            child: Stack(
                              children: [
                                Icon(
                                  (musicPlayer.player.playing &&
                                          musicPlayer.songList
                                                  .elementAt(index) ==
                                              musicPlayer.actualSong)
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  color: loading
                                      ? Colors.transparent
                                      : Colors.green,
                                  size: (width + height) * 0.04,
                                ),
                                if (loading == true &&
                                    musicPlayer.songList.elementAt(index) ==
                                        musicPlayer.actualSong)
                                  Positioned(
                                    top: height * 0.008,
                                    right: width * 0.015,
                                    child: SizedBox(
                                      width: ((width + height) * 0.03),
                                      height: ((width + height) * 0.03),
                                      child: const CircularProgressIndicator(
                                          color: Colors.green),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Placeholder(color: Colors.transparent);
              },
            ),
          ),
          if (isPlaying)
            Positioned(
              bottom: 0,
              child: WhatsPlaying(
                nameMusic:
                    musicPlayer.songList.elementAt(musicPlayer.songIndex),
                imageMusic: musicPlayer.imageList[musicPlayer.songIndex],
                artistName: musicPlayer.artistName[
                    musicPlayer.songList.elementAt(musicPlayer.songIndex)]!,
                musicPlayer: musicPlayer,
                loading: loading,
                loadingMaster: loadingMaster,
                duration: musicPlayer.mapDuration[musicPlayer.songList
                        .elementAt(musicPlayer.songIndex)] ??
                    Duration.zero,
                stopWidget: () {
                  setState(() {
                    isPlaying = false;
                    musicPlayer.player.stop();
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
