package com.example.masjid_app

import io.flutter.embedding.android.FlutterActivity
import com.yandex.mapkit.MapKitFactory

class MainActivity: FlutterActivity() {

    // Add an init block to set the API key when the activity is created
    init {
        MapKitFactory.setApiKey("b70ad724-8dcb-495e-ae87-0ce332948f91")
    }

    // Other methods or code can go here

}
