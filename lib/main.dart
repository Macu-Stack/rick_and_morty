import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CharacterListPage(),
    );
  }
}

class CharacterListPage extends StatefulWidget {
  @override
  _CharacterListPageState createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  List<dynamic> characters = [];

  @override
  void initState() {
    super.initState();
    fetchCharacters();
  }

  Future<void> fetchCharacters() async {
    final response =
        await http.get(Uri.parse('https://rickandmortyapi.com/api/character'));

    if (response.statusCode == 200) {
      setState(() {
        final data = json.decode(response.body);
        characters = data['results'];
      });
    } else {
      throw Exception('Error al cargar los personajes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personajes de Rick and Morty'),
      ),
      body: characters.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(character['image']),
                  ),
                  title: Text(character['name']),
                  subtitle: Text(character['species']),
                  trailing: ElevatedButton(
                    child: Text('Ver episodios'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EpisodeListPage(
                            characterId: character['id'],
                            characterName: character['name'],
                            characterUrl: character['url'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class EpisodeListPage extends StatefulWidget {
  final int characterId;
  final String characterName;
  final String characterUrl;

  EpisodeListPage(
      {required this.characterId,
      required this.characterName,
      required this.characterUrl});

  @override
  _EpisodeListPageState createState() => _EpisodeListPageState();
}

class _EpisodeListPageState extends State<EpisodeListPage> {
  List<dynamic> episodes = [];

  @override
  void initState() {
    super.initState();
    fetchEpisodes();
  }

  Future<void> fetchEpisodes() async {
    try {
      final response = await http
          .get(Uri.parse(widget.characterUrl))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final characterData = json.decode(response.body);
        List<dynamic> episodeUrls = characterData['episode'];

        List<Future> episodeFutures = episodeUrls.map((url) async {
          try {
            final episodeResponse =
                await http.get(Uri.parse(url)).timeout(Duration(seconds: 10));

            if (episodeResponse.statusCode == 200) {
              return json.decode(episodeResponse.body);
            }
          } catch (e) {
            print('Error fetching episode: $e');
          }
          return null;
        }).toList();

        final fetchedEpisodes = await Future.wait(episodeFutures);

        if (mounted) {
          setState(() {
            episodes =
                fetchedEpisodes.where((episode) => episode != null).toList();
          });
        }
      } else {
        throw Exception('Error al cargar los episodios del personaje');
      }
    } catch (e) {
      print('Error fetching character data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Episodios de ${widget.characterName}'),
      ),
      body: episodes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return ListTile(
                  title: Text(episode['name']),
                  subtitle: Text('Fecha de emisión: ${episode['air_date']}'),
                  trailing: Text(episode['episode']),
                );
              },
            ),
    );
  }
}
