import 'dart:async';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}


class MyApp extends StatelessWidget {

  final ColorScheme colorScheme = ColorScheme.light(
  primary: Color.fromARGB(255, 162, 162, 162),  // A sleek dark blue-grey
  secondary: Color.fromARGB(255, 61, 61, 61),    // A vibrant teal
  surface: Colors.white,           // White surface for cards
  onPrimary: Colors.white,         // White text on primary color
  onSecondary: Colors.white,       // White text on secondary color
  onSurface: Colors.black,         // Black text on surface
  tertiary: const Color.fromARGB(255, 129, 129, 129),
  onTertiary: Colors.white
  );

  MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'AI assistant app',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,//ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  var chatHistory = <String>[];

  void addToChat(newMessage) {
    chatHistory.add(newMessage);
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedindex = 0;
  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedindex) {
      case 0:
        page = StartingPage();
      case 1:
        page = BlocProvider(
          create: (context) => BackendBloc(),
          child: MyCustomForm());
      default:
        throw UnimplementedError('no widget for $selectedindex');
    }
    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat),
                  label: Text('Chat'),
                ),
              ],
              selectedIndex: selectedindex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedindex = value;
                });
                print('selected: $value');
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.secondary,
              child: page,
            ),
          ),
        ],
      ),
    );
  }
}


class StartingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.onPrimary);

    return Column(mainAxisAlignment: MainAxisAlignment.center,
    children: [Icon(Icons.computer, 
    size: 100, 
    color: theme.colorScheme.onPrimary,),
    Text("Personal AI travel assistant", 
    style: style,)]);
  } 
}

class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  State<MyCustomForm> createState() => ChatPage();
}


class ChatPage extends State<MyCustomForm> {
  final myController = TextEditingController();
  
  dynamic align;
  dynamic icon;
  dynamic textItems;
  bool _loading = false;
  int _dotCount = 0;
  String _loadingText = "loading";
  Timer? _timer;


  void _startLoadingAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4; // Loop the dots from 0 to 3
        _loadingText = "loading${"." * _dotCount}";
      });
    });
  }


  void _stop() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var chatHistory = appState.chatHistory;

    final backendBloc = BlocProvider.of<BackendBloc>(context);
    return Stack(
      children: [Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                if (index % 2 == 0) {
                  align = Alignment.centerLeft;
                  icon = Icons.android;
                  textItems = Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Row(
                      children : [
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Icon(icon, color: Colors.white, size: 40,),
                              ))),
                          Expanded(
                            flex: 10,
                            child: Card(
                              color: Theme.of(context).colorScheme.tertiary,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Align(
                                  alignment: align,
                                  child: Text(
                                    style: TextStyle( color: Theme.of(context).colorScheme.onPrimary),
                                    chatHistory[(chatHistory.length - (index + 1))]
                                    )),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SizedBox(width: 40,)),
                        ]),
                  );
                } else {
                  align = Alignment.centerRight;
                  icon = Icons.account_circle;
                  textItems = Row(
                    children : [
                        Expanded(
                          flex: 1,
                          child: SizedBox(width: 40,)),
                        Expanded(
                          flex: 10,
                          child: Card(
                            color: Theme.of(context).colorScheme.primary,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Align(
                                alignment: align,
                                child: Text(
                                  style: TextStyle( color: Theme.of(context).colorScheme.onPrimary),
                                  chatHistory[(chatHistory.length - (index + 1))])),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(icon, color: Colors.white, size: 40),
                            ))),
                      ]);
                }
                return Padding(
                  padding: EdgeInsets.only(left: 100, right: 100),
                  child: IntrinsicHeight(
                    child: textItems,
                  ),
                );
              },
              reverse: true,
            ),
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                    Flexible(
                      child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextField(
                        onSubmitted: (value) {
                                  if (myController.text.isNotEmpty){
                                      setState(() {
                                        _loading = true;
                                      });
                                      _startLoadingAnimation();
                                      var userInput = myController.text;
                                      myController.clear();
                                      backendBloc.fetchData(userInput).then((String result){
                                      appState.addToChat(userInput);
                                      appState.addToChat(result);
                                      setState(() {
                                        chatHistory = appState.chatHistory;
                                        _loading = false;
                                      });
                                      _stop();
                                    });
                                  }
                        },
                        controller: myController,
                        decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Where to next?',
                        fillColor: Colors.white,
                        filled: true,
                        
                        ),
                      ),
                    ),
                    ),
                    IconButton(
                            onPressed: () {
                              if (myController.text.isNotEmpty){
                                setState(() {
                                  _loading = true;
                                });
                                _startLoadingAnimation();
                                var userInput = myController.text;
                                myController.clear();
                                backendBloc.fetchData(userInput).then((String result){
                                appState.addToChat(userInput);
                                appState.addToChat(result);
                                setState(() {
                                  chatHistory = appState.chatHistory;
                                  _loading = false;
                                });
                                _stop();
                              });
                            }
                            },
                            icon: Icon(Icons.send),
                    color: Colors.white,
                    )
            
                  ],
            ),
      
          ]),
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3), // Semi-transparent background
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/loading.gif', // Replace with your GIF path
                      width: 100,
                      height: 100,
                    ),
                    Text(_loadingText, style: TextStyle( color: Theme.of(context).colorScheme.onPrimary))
                  ],
                ),
              ),
            )
          ]
    );
  }
}




class BackendBloc extends Cubit<String> {
  BackendBloc() : super('');

  Future<String> fetchData(String userInput) async {

    Map<String, String> jsonInput = <String, String>{};
    jsonInput["query"] = userInput;

    final response = await http.post(Uri.parse('http://localhost:5001/api/data'), body: jsonInput);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return 'Failed to fetch data';
    }
  }
}


class RecordPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {

    var appState = context.watch<MyAppState>();
    var chatHist = appState.chatHistory;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [for (var item in chatHist) Text(item),],
    );
  }
}