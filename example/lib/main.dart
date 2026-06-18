import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_api_state/flutter_api_state.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_api_state example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PostsPage(),
    );
  }
}

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  Future<List<dynamic>> fetchPosts() async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
      ),
      body: ApiStateBuilder<List<dynamic>>(
        future: () => fetchPosts(),

        /// Loading Widget
        loading: const Center(child: CircularProgressIndicator()),

        /// Enable pull to refresh
        enablePullToRefresh: true,
        refreshIndicatorColor: Colors.red,

        /// Enable Retry Again
        enableRetry: true,
        retryButtonBuilder: (ctx, onRetry) => OutlinedButton(
          onPressed: onRetry,
          child: const Text('Try again'),
        ),

        /// Success Widget
        success: (context, posts) {
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  title: Text(
                    post['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(post['body']),
                ),
              );
            },
          );
        },

        /// Error Widget
        error: (context, error, stack) => Center(child: Text('$error')),

        /// Empty Widget
        empty: const Center(child: Text('No posts')),
      ),
    );
  }
}
