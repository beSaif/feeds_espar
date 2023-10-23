import 'package:feeds_espar/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserProvider userProviderInit =
          Provider.of<UserProvider>(context, listen: false);

      userProviderInit.filterClient
          ? userProviderInit.fetchFeedAndFilterClient()
          : userProviderInit.fetchFeedServer();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Feeds'),
            actions: [
              Column(
                children: [
                  Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: userProvider.filterClient,
                    activeColor: Colors.green,
                    onChanged: (value) {
                      userProvider.setFilterClient(value);
                      value
                          ? userProvider.fetchFeedAndFilterClient()
                          : userProvider.fetchFeedServer();
                    },
                  ),
                  Text('${userProvider.filterClient ? 'Client' : 'Server'}'),
                ],
              ),
            ],
          ),
          body: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: userProvider.users
                        .map((e) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: userProvider.uid == e
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  userProvider.setUid(e);
                                },
                                child: Text(e,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('Feed'),
                ),
                const SizedBox(height: 20),
                userProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: ListView(
                          children: userProvider.feed
                              .map((e) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(e),
                                  ))
                              .toList(),
                        ),
                      ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
