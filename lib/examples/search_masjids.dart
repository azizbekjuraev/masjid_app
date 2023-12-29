import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masjid_app/examples/map_point.dart';
import 'package:masjid_app/examples/map_screen.dart';

class SearchMasjids extends StatefulWidget {
  const SearchMasjids({super.key});

  @override
  State<SearchMasjids> createState() => _SearchMasjidsState();
}

class _SearchMasjidsState extends State<SearchMasjids> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<MapPoint> _masjidOptions = [];

  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    // Set focus on the search field when the page is opened
    _searchFocusNode.requestFocus();
    fetchData();
  }

  void fetchData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    CollectionReference masjidsCollection = firestore.collection('masjids');

    QuerySnapshot querySnapshot = await masjidsCollection.get();

    List<QueryDocumentSnapshot> documents = querySnapshot.docs;

    List<MapPoint> options = [];

    for (var document in documents) {
      String masjidName = document['name'];
      double latitude = 0.0;
      double longitude = 0.0;
      if (document['coords'] is GeoPoint) {
        latitude = document['coords'].latitude;
        longitude = document['coords'].longitude;
      }

      MapPoint masjidOptions = MapPoint(
          documentId: document.id,
          name: masjidName,
          latitude: latitude,
          longitude: longitude);
      options.add(masjidOptions);
    }
    setState(() {
      _masjidOptions = options;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white38,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                // Hide options when focus is lost
                setState(() {
                  _showOptions = false;
                });
              }
            },
            child: Builder(builder: (context) {
              return Autocomplete<MapPoint>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // Update _showOptions only if the text is not empty and matches any suggestion
                  setState(() {
                    _showOptions = textEditingValue.text.isNotEmpty &&
                        _masjidOptions.any((option) => option.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                  });
                  return _showOptions
                      ? _masjidOptions
                          .where((option) => option.name
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()))
                          .toList()
                      : [];
                },

                onSelected: (MapPoint selection) {
                  // Handle the selected option
                  // _searchController.text = selection.name;
                  // Hide options when an option is selected
                  setState(() {
                    _showOptions = false;
                  });
                },
                displayStringForOption: (MapPoint option) => option.name,
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    autofocus: true,
                    onChanged: (String value) {
                      // You can use this to update the suggestions in real-time
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(20.0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          if (textEditingController.text == '') {
                            Navigator.of(context).pop();
                            // Hide options when text is cleared
                            setState(() {
                              _showOptions = false;
                            });
                          } else {
                            // fetchData();
                            textEditingController.text = '';
                          }
                        },
                      ),
                      hintText: 'Qidirmoq...',
                      border: InputBorder.none,
                    ),
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<MapPoint> onSelected,
                    Iterable<MapPoint> options) {
                  double listViewHeight = options.length * 65.0;
                  listViewHeight = listViewHeight.clamp(65.0, 207.0);
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        height: listViewHeight,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: options
                              .map(
                                (MapPoint option) => GestureDetector(
                                  onTap: () {
                                    onSelected(option);
                                    // _searchController.text = option.name;
                                    // Hide options when an option is selected
                                    setState(() {
                                      _showOptions = false;
                                    });
                                  },
                                  child: ListTile(
                                    horizontalTitleGap: 3.0,
                                    title: Text(option.name),
                                    subtitle: Text(
                                        '${option.latitude} ${option.longitude}'),
                                    leading: const Icon(
                                      Icons.location_on_sharp,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  );
                },
                optionsMaxHeight: 200.0,
                // Show options only when typing and there are matching suggestions
              );
            }),
          ),
        ),
      ),
    );
  }
}
