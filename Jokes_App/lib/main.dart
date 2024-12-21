import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF6A5ACD), // Slate Blue
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6A5ACD), // Slate Blue
          secondary: const Color(0xFF9370DB), // Medium Purple
        ),
        scaffoldBackgroundColor: const Color(0xFFF3E5F5), // Lavender Blush
        appBarTheme: const AppBarTheme(
          color: Color(0xFF6A5ACD), // Slate Blue
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF9370DB), // Medium Purple
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const OnboardingScreen(),
    );
  }
}

// Onboarding Screen
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          buildPage(
            context,
            title: "Welcome to Jokes App",
            description: "Get your daily dose of fun and laughter!",
            image: Icons.sentiment_very_satisfied,
          ),
          buildPage(
            context,
            title: "Personalized Experience",
            description: "Choose themes, categories, and customize your profile.",
            image: Icons.color_lens,
          ),
          buildPage(
            context,
            title: "Ready to Laugh?",
            description: "Let's get started!",
            image: Icons.thumb_up,
            isLastPage: true,
          ),
        ],
      ),
    );
  }

  Widget buildPage(BuildContext context,
      {required String title,
      required String description,
      required IconData image,
      bool isLastPage = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)], // Slate Blue to Medium Purple
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(image, size: 100, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 40),
          if (isLastPage)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6A5ACD), // Slate Blue
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              child: const Text("Get Started"),
            ),
        ],
      ),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  String selectedCategory = "Any";
  bool isLoading = false;
  String? errorMessage;
  List<String> jokes = [];
  List<String> filteredJokes = [];

  @override
  void initState() {
    super.initState();
    loadCachedJokes();
  }

  // Load cached jokes
  Future<void> loadCachedJokes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJokes = prefs.getStringList('cached_jokes_$selectedCategory');
    if (cachedJokes != null && cachedJokes.isNotEmpty) {
      setState(() {
        jokes = cachedJokes;
        filteredJokes = cachedJokes;
      });
    }
  }

  // Cache jokes after fetching
  Future<void> cacheJokes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('cached_jokes_$selectedCategory', jokes);
  }

  // Manual connectivity check
  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Fetch jokes from API
  Future<void> fetchJokes() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final online = await isConnected();
    if (!online) {
      showOfflineMessage();
      await loadCachedJokes();
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          "https://v2.jokeapi.dev/joke/$selectedCategory?amount=5&type=single"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['jokes'] != null) {
          setState(() {
            jokes = List<String>.from(data['jokes'].map((joke) => joke['joke']));
            filteredJokes = jokes;
          });

          await cacheJokes();
        } else {
          throw Exception("No jokes found for the selected category.");
        }
      } else {
        throw Exception("Failed to fetch jokes from the server.");
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void showOfflineMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Offline"),
        content: const Text("You are currently offline. Cached jokes will be displayed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void filterJokes(String query) {
    setState(() {
      filteredJokes = jokes
          .where((joke) =>
              joke.toLowerCase().contains(query.toLowerCase().trim()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Attractive Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A5ACD), Color(0xFF9370DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "😂 Jokes App",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: searchController,
                  onChanged: filterJokes,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Search jokes...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6A5ACD)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      buildCategoryChip("Any", "🌍"),
                      buildCategoryChip("Programming", "💻"),
                      buildCategoryChip("Misc", "🎲"),
                      buildCategoryChip("Dark", "🌑"),
                      buildCategoryChip("Pun", "🤡"),
                      buildCategoryChip("Spooky", "👻"),
                      buildCategoryChip("Christmas", "🎄"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Text(errorMessage!,
                            style: const TextStyle(color: Colors.red)),
                      )
                    : filteredJokes.isEmpty
                        ? const Center(
                            child: Text("No jokes found!",
                                style: TextStyle(fontSize: 18, color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: filteredJokes.length,
                            itemBuilder: (context, index) {
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                margin: const EdgeInsets.all(8),
                                child: ListTile(
                                  title: Text(filteredJokes[index]),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF6A5ACD),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchJokes,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget buildCategoryChip(String category, String emoji) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
        loadCachedJokes();
      },
      child: Chip(
        label: Text("$emoji $category"),
        backgroundColor:
            selectedCategory == category ? const Color(0xFF6A5ACD) : const Color(0xFFB2C2F2),
        labelStyle: TextStyle(
          color: selectedCategory == category ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
