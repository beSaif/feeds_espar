import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  bool _filterClient = false;
  bool get filterClient => _filterClient;
  void setFilterClient(bool filterClient) {
    _filterClient = filterClient;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  List users = ['user1', 'user2', 'user3', 'user4'];

  String _uid = 'user1';
  String get uid => _uid;

  void setUid(String uid) {
    _uid = uid;
    filterClient ? fetchFeedAndFilterClient() : fetchFeedServer();
    notifyListeners();
  }

  List<String> _feed = [];
  List<String> get feed => _feed;
  setFeed(List<String> feed) {
    _feed = feed;
    notifyListeners();
  }

  // In this approach, we query feeds_target collection for each org that the user is following.
  // Multiple QuerySnapshots are fetched from the server.
  Future<void> fetchFeedServer() async {
    print('Fetching feed for $_uid');

    setLoading(true);
    List<String> posts = [];
    HashSet<String> feedsTarget = HashSet<String>();

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    CollectionReference postsCollection = firestore.collection('posts');
    CollectionReference userCollection = firestore.collection('users');

    // Get all orgs that the user is following from users collection for that specific user
    DocumentSnapshot userDoc = await userCollection.doc(uid).get();

    // Store all orgs that the user is following in a list
    List<String> followingOrgs = List<String>.from(userDoc['orgs']);
    print('followingOrgs: $followingOrgs');

    // If user is not following any orgs, set feed to empty and return
    if (followingOrgs.isEmpty) {
      setFeed(posts);
      setLoading(false);
      return;
    }

    // Gets the postId from feeds_target collection where for each org in followingOrgs is true
    for (var orgs in followingOrgs) {
      Query? feedsTargetQuery =
          firestore.collection('feeds_target').where(orgs, isEqualTo: true);

      QuerySnapshot feedsTargetQuerySnapshot = await feedsTargetQuery.get();

      feedsTargetQuerySnapshot.docs.forEach((feed) {
        feedsTarget.add(feed['postId']);
      });
    }
    print('feedsTarget: $feedsTarget');

    // Using the postId we got from feeds_target collection, get the content from posts collection
    QuerySnapshot postsQuery =
        await postsCollection.where('id', whereIn: feedsTarget).get();
    for (var post in postsQuery.docs) {
      posts.add(post['content']);
    }
    print('posts: $posts');

    setFeed(posts);
    setLoading(false);
    print('\n\n');
  }

  // In this approach, instead of querying feeds_target collection for each org, we query the entire collection once and filter it from Client.
  Future<void> fetchFeedAndFilterClient() async {
    print('Fetching feed for $_uid');

    setLoading(true);
    List<String> posts = [];
    HashSet<String> feedsTarget = HashSet<String>();

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    CollectionReference postsCollection = firestore.collection('posts');
    CollectionReference userCollection = firestore.collection('users');

    // Get all orgs that the user is following from users collection for that specific user
    DocumentSnapshot userDoc = await userCollection.doc(uid).get();

    // Store all orgs that the user is following in a list
    List<String> followingOrgs = List<String>.from(userDoc['orgs']);
    print('followingOrgs: $followingOrgs');

    // If user is not following any orgs, set feed to empty and return
    if (followingOrgs.isEmpty) {
      setFeed(posts);
      setLoading(false);
      return;
    }

    // Gets the postId from feeds_target collection where for each org in followingOrgs is true
    Query? feedsTargetQuery = firestore.collection('feeds_target');
    QuerySnapshot feedsTargetQuerySnapshot = await feedsTargetQuery.get();
    feedsTargetQuerySnapshot.docs.forEach((feed) {
      final Map<String, dynamic> feedJson = feed.data() as Map<String, dynamic>;
      for (var orgs in followingOrgs) {
        if (feedJson[orgs] == true) {
          feedsTarget.add(feedJson['postId']);
        }
      }
    });
    print('feedsTarget: $feedsTarget');

    // Using the postId we got from feeds_target collection, get the content from posts collection
    QuerySnapshot postsQuery =
        await postsCollection.where('id', whereIn: feedsTarget).get();
    for (var post in postsQuery.docs) {
      posts.add(post['content']);
    }
    print('posts: $posts');

    setFeed(posts);
    setLoading(false);
    print('\n\n');
  }
}
