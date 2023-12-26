//this is for search_masjids.dart;
TextField(
controller: \_searchController,
focusNode: \_searchFocusNode,
autofocus: true,
decoration: InputDecoration(
// prefixIcon: const Icon(Icons.search),
contentPadding: const EdgeInsets.all(10.0),
suffixIcon: IconButton(
icon: const Icon(Icons.clear),
onPressed: () {
if (\_searchController.text.isEmpty) {
Navigator.of(context).pop();
} else {
\_searchController.text = '';
}

                    /* Clear the search field */
                  },
                ),
                hintText: 'Qidirmoq...',
                border: InputBorder.none),
          ),
