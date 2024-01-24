import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:masjid_app/examples/data/provider.dart';
import 'package:masjid_app/examples/styles/app_styles.dart';

class News {
  final String title;
  final String text;
  final Timestamp date;
  bool seen;
  final String id;

  News({
    required this.title,
    required this.text,
    required this.date,
    required this.seen,
    required this.id,
  });
}

class NewsView extends StatefulWidget {
  final NotificationCountNotifier? notifier;
  const NewsView({Key? key, this.notifier}) : super(key: key);

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  var newsCollection = FirebaseFirestore.instance.collection('news');
  List<News> newsList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchNewsData();
  }

  Future<void> fetchNewsData() async {
    print(isLoading);
    var querySnapshot = await newsCollection.get();
    var newsData = querySnapshot.docs
        .map((doc) => News(
            date: doc['date'],
            title: doc['title'],
            text: doc['text'],
            seen: doc['seen'],
            id: doc.id))
        .toList();

    setState(() {
      newsList = newsData;
      isLoading = true;
      print(isLoading);
    });
  }

  Future<void> markNewsAsSeen(News news) async {
    print(isLoading);
    await newsCollection.doc(news.id).update({'seen': true});
    setState(() {
      news.seen = true;
    });
    // Update the notification count in the provider
    int newNotificationCount = newsList.where((n) => !n.seen).length;
    widget.notifier!.setNotificationCount(newNotificationCount);
  }

  void _showNewsDetails(News news) {
    markNewsAsSeen(news);
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      builder: (BuildContext context) {
        double screenWidth = MediaQuery.of(context).size.width;
        return Column(
          children: [
            Expanded(
                child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd, HH:mm').format(news.date.toDate()),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    news.text,
                  ),
                ],
              ),
            )),
            // Add the button at the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: screenWidth,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(
                        AppStyles.backgroundColorGreen700),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            10.0), // Set your desired border radius here
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Yaxshi',
                    style: TextStyle(color: AppStyles.foregroundColorYellow),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangiliklar'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            Expanded(
                child: isLoading
                    ? ListView.builder(
                        itemCount: newsList.length,
                        itemBuilder: (BuildContext context, int index) {
                          var news = newsList[index];
                          return GestureDetector(
                            onTap: () => _showNewsDetails(news),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 5.0),
                              padding: const EdgeInsets.all(20.0),
                              decoration: BoxDecoration(
                                color: AppStyles.backgroundColorGreen900,
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppStyles.backgroundColorGreen700
                                        .withOpacity(0.4),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            news.title,
                                            style: const TextStyle(
                                                color: AppStyles
                                                    .foregroundColorYellow),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            DateFormat('yyyy-MM-dd, HH:mm')
                                                .format(news.date.toDate()),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppStyles
                                                    .foregroundColorYellow),
                                          ),
                                        ],
                                      ),
                                      news.seen
                                          ? Container()
                                          : const Icon(
                                              Icons.circle_notifications,
                                              size: 40,
                                              color: AppStyles
                                                  .foregroundColorYellow,
                                            )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      )),
          ],
        ),
      ),
    );
  }
}
