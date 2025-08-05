import 'dart:convert';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:http/http.dart' as http;

import 'data.dart';

const String apiEndpoint = "https://obra-allgaeu.de";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Obra | Galerie', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange)), home: const MainPage());
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late Future<List<Entry>> data;

  @override
  void initState() {
    super.initState();
    data = fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Entry> d = snapshot.data as List<Entry>;
            return GridView.count(
              crossAxisCount: max((MediaQuery.sizeOf(context).width / 400).floor(), 1),
              scrollDirection: Axis.vertical,
              physics: BouncingScrollPhysics(),
              children: [
                for (Entry e in d)
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        // barrierColor: Color(0xE0000000),
                        barrierColor: Color(0x00000000),
                        builder: (BuildContext context) {
                          return /*BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: */ DetailDialog(e: e) /*,
                          )*/;
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AspectRatio(aspectRatio: 1.17, child: PicturesView(e: e, height: 300, autoPlay: true)),
                          Text(e.name, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }

          if (snapshot.hasError) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error), Text("Fehler: ${snapshot.error}")]));
          }
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), Text("Laden...")]));
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Softwareinformationen",
        backgroundColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        mini: true,
        onPressed:
            () => showAboutDialog(
              context: context,
              applicationName: "Obra Gallery Flutter",
              applicationLegalese: """Obra Gallery client implementation using Flutter.
Copyright (C) 2025-present  Janosch Lion

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

Dynamic content (images, text, etc.) may have separate copyright.""",
            ),
        child: const Icon(Icons.info_outline),
      ),
    );
  }
}

class DetailDialog extends StatelessWidget {
  final Entry e;

  const DetailDialog({super.key, required this.e});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(color: ColorScheme.of(context).surface, borderRadius: BorderRadiusDirectional.circular(10)),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: min(MediaQuery.sizeOf(context).width / 1.77, MediaQuery.sizeOf(context).height / 1.3)),
                    child: PicturesView(e: e, height: 800, shortcutsEnabled: true),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(e.name, textScaler: TextScaler.linear(2.0)),
                      Html(data: e.desc, extensions: [TableHtmlExtension()]),
                    ],
                  ),
                  // if (e.comments.isEmpty) Text("Keine Kommentare.") else
                  for (Comment c in e.comments)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(),
                        Row(
                          children: [
                            Text(c.author, style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 5),
                            Text(c.date, style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Text(c.text),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Container(alignment: Alignment.topRight, child: CloseButton()),
        ],
      ),
    );
  }
}

class PicturesView extends StatefulWidget {
  final Entry e;
  final double height;
  final bool autoPlay;
  final bool shortcutsEnabled;

  const PicturesView({super.key, required this.e, required this.height, this.autoPlay = false, this.shortcutsEnabled = false});

  @override
  State<StatefulWidget> createState() => _PicturesViewState(e: e, height: height, autoPlay: autoPlay, shortcutsEnabled: shortcutsEnabled);
}

class _PicturesViewState extends State<PicturesView> {
  final Entry e;
  final double height;
  final bool autoPlay;
  final bool shortcutsEnabled;
  final CarouselSliderController carouselController = CarouselSliderController();
  bool autoPlaying = false;
  int activePicture = 0;

  _PicturesViewState({required this.e, required this.height, this.autoPlay = false, this.shortcutsEnabled = false});

  @override
  Widget build(BuildContext context) {
    if (e.pictures.isEmpty) {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.warning), Text("Keine Bilder verfügbar.")]);
    }
    Stack mainStack = Stack(
      children: [
        MouseRegion(
          onEnter: (PointerEvent event) {
            if (autoPlay) {
              setState(() {
                autoPlaying = true;
              });
            }
          },
          onExit: (PointerEvent event) {
            if (autoPlay) {
              setState(() {
                autoPlaying = false;
              });
            }
          },
          child: CarouselSlider.builder(
            itemCount: e.pictures.length,
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: height,
              autoPlay: autoPlay && autoPlaying,
              autoPlayInterval: Duration(seconds: 2, milliseconds: 500),
              onPageChanged:
                  (index, reason) => setState(() {
                    activePicture = index;
                  }),
            ),
            carouselController: carouselController,
            itemBuilder: (context, int index, int reaLIndex) {
              return getPictureImage(e.pictures[index]);
            },
          ),
        ),
        Container(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              carouselController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
            },
            icon: Icon(Icons.chevron_left),
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () {
              carouselController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
            },
            icon: Icon(Icons.chevron_right),
          ),
        ),
        Container(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 5,
            children: [
              for (int i = 0; i < e.pictures.length; i++)
                GestureDetector(
                  onTap: () => carouselController.animateToPage(i),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: activePicture == i ? Colors.black : Colors.grey, borderRadius: BorderRadius.circular(2.5)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (shortcutsEnabled) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => carouselController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.ease),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => carouselController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease),
        },
        child: Focus(autofocus: true, child: mainStack),
      );
    }
    return mainStack;
  }
}

Widget getPictureImage(Picture? p) {
  if (p != null) {
    return Image.network(getPictureURL(p));
  } else {
    return Icon(Icons.warning);
  }
}

String getPictureURL(Picture p) {
  return '$apiEndpoint/gallery-images/${p.fileName}';
}

Future<List<Entry>> fetchData() async {
  final response = await http.get(Uri.parse('$apiEndpoint/gallery-api-v2/fetch.php'));
  if (response.statusCode == 200) {
    List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    List<Entry> data = [];
    for (Map<String, dynamic> item in json) {
      data.add(Entry.fromJson(item));
    }
    return data;
  } else {
    throw Exception('Konnte Daten nicht laden.');
  }
}
