import 'package:flutter/material.dart';
import 'package:projeto_spotify/Utils/music_player.dart';
import 'package:spotify/spotify.dart' as sptf;

import '../Utils/constants.dart';
import '../Utils/image_loader.dart';
import '../Utils/load_screen.dart';

class PlayMusic extends StatefulWidget {
  final String trackId;
  const PlayMusic({super.key, required this.trackId});

  @override
  State<PlayMusic> createState() => _PlayMusicState();
}

class _PlayMusicState extends State<PlayMusic> {
  final musicPlayer = MusicPlayer();

  bool allLoad = false;
  bool loading = false;

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

        setState(() {});
      });
    }).then((value) => setState(() => allLoad = true));

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
          title: Row(
            children: [
              if (allLoad)
                SizedBox(
                  width: width * 0.14,
                  height: height * 0.14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ImageLoader().imageNetwork(
                        urlImage: musicPlayer.artistImage.elementAt(0),
                        size: width * 0.14),
                  ),
                ),
              SizedBox(width: width * 0.01),
              Expanded(
                child: Text(
                  musicPlayer.playlistName.elementAtOrNull(0) ?? '',
                  style:
                      TextStyle(color: Colors.white, fontSize: width * 0.065),
                ),
              ),
            ],
          ),
        ),
        body: allLoad
            ? SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.07),
                    SizedBox(
                      width: size.width * 1,
                      height: size.height * 0.35,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: ImageLoader().imageNetwork(
                            urlImage: musicPlayer.imageList
                                    .elementAtOrNull(musicPlayer.songIndex) ??
                                '',
                            size: width * 0.80),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    Text(
                      musicPlayer.songList
                              .elementAtOrNull(musicPlayer.songIndex) ??
                          '',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.07,
                      ),
                    ),
                    musicPlayer.progressBar(
                      width * 0.80,
                      loadingMaster,
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () async {
                                if (musicPlayer.songIndex != 0) {
                                  setState(() => loading = true);
                                  await musicPlayer.passMusic('Left');
                                  setState(() {
                                    musicPlayer.player.seek(Duration.zero);
                                    loading = false;
                                  });
                                }
                              },
                              child: Icon(
                                musicPlayer.songIndex != 0
                                    ? Icons.arrow_circle_left_outlined
                                    : Icons.arrow_circle_left,
                                size: width * 0.14,
                                color: musicPlayer.songIndex != 0
                                    ? Colors.white
                                    : Colors.red,
                              ),
                            ),
                            Stack(
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    setState(() => loading = true);

                                    try {
                                      await musicPlayer.changeMusic();

                                      if (musicPlayer.musicaCompletada()) {
                                        musicPlayer.player.seek(Duration.zero);
                                      }
                                      setState(() =>
                                          musicPlayer.musica = Duration.zero);

                                      await musicPlayer.play().then((value) {
                                        setState(() => loading = false);
                                      });
                                    } catch (error) {
                                      setState(() => loading = false);
                                    }
                                  },
                                  child: Icon(
                                    musicPlayer.player.playing
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                    size: (size.width + size.height) * 0.08,
                                    color: loading
                                        ? Colors.transparent
                                        : Colors.white,
                                  ),
                                ),
                                if (loading)
                                  Positioned(
                                    right: size.width * 0.05,
                                    bottom: size.height * 0.021,
                                    child: SizedBox(
                                      width: (size.width + size.height) * 0.065,
                                      height:
                                          (size.width + size.height) * 0.065,
                                      child: const CircularProgressIndicator(
                                        color: Constants.color,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                if (musicPlayer.songIndex !=
                                    musicPlayer.songList.length - 1) {
                                  setState(() => loading = true);
                                  await musicPlayer.passMusic('Right');
                                  setState(() {
                                    musicPlayer.player.seek(Duration.zero);
                                    loading = false;
                                  });
                                }
                              },
                              child: Icon(
                                musicPlayer.songIndex !=
                                        musicPlayer.songList.length - 1
                                    ? Icons.arrow_circle_right_outlined
                                    : Icons.arrow_circle_right,
                                size: width * 0.14,
                                color: musicPlayer.songIndex !=
                                        musicPlayer.songList.length - 1
                                    ? Colors.white
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                  onPressed: () {
                    switch (musicPlayer.repeatType) {
                      case 0:
                        musicPlayer.autoPlay = true;
                        musicPlayer.repeatType += 1;
                      case 1:
                        musicPlayer.repeat = true;
                        musicPlayer.autoPlay = false;
                        musicPlayer.repeatType += 1;
                      case 2:
                        musicPlayer.repeat = false;
                        musicPlayer.repeatType = 0;
                    }

                    setState(() {});
                  },
                  child: Icon(
                    musicPlayer.repeatType == 0
                        ? Icons.repeat
                        : musicPlayer.repeatType == 1
                            ? Icons.repeat
                            : Icons.repeat_one,
                    size: width * 0.11,
                    color: musicPlayer.repeatType == 0
                        ? Colors.white
                        : musicPlayer.repeatType == 1
                            ? Constants.color
                            : Constants.color,
                  ),
                ),
                            TextButton(
                              onPressed: () {
                                setState(() =>
                                    musicPlayer.shuffle = !musicPlayer.shuffle);
                              },
                              child: Icon(
                                Icons.shuffle,
                                size: width * 0.11,
                                color: musicPlayer.shuffle
                                    ? Constants.color
                                    : Colors.white,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              )
            : LoadScreen().loadingNormal(size));
  }
}
