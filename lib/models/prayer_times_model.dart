class PrayerData {
  String? region;
  String? date;
  String? weekday;
  HijriDate? hijriDate;
  Times? times;

  PrayerData(
      {this.region, this.date, this.weekday, this.hijriDate, this.times});

  PrayerData.fromJson(Map<String, dynamic> json) {
    region = json['region'];
    date = json['date'];
    weekday = json['weekday'];
    hijriDate = json['hijri_date'] != null
        ? HijriDate.fromJson(json['hijri_date'])
        : null;
    times = json['times'] != null ? Times.fromJson(json['times']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['region'] = region;
    data['date'] = date;
    data['weekday'] = weekday;
    if (hijriDate != null) {
      data['hijri_date'] = hijriDate!.toJson();
    }
    if (times != null) {
      data['times'] = times!.toJson();
    }
    return data;
  }
}

class HijriDate {
  String? month;
  int? day;

  HijriDate({this.month, this.day});

  HijriDate.fromJson(Map<String, dynamic> json) {
    month = json['month'];
    day = json['day'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['month'] = month;
    data['day'] = day;
    return data;
  }
}

class Times {
  String? tongSaharlik;
  String? quyosh;
  String? peshin;
  String? asr;
  String? shomIftor;
  String? hufton;

  Times(
      {this.tongSaharlik,
      this.quyosh,
      this.peshin,
      this.asr,
      this.shomIftor,
      this.hufton});

  Times.fromJson(Map<String, dynamic> json) {
    tongSaharlik = json['tong_saharlik'];
    quyosh = json['quyosh'];
    peshin = json['peshin'];
    asr = json['asr'];
    shomIftor = json['shom_iftor'];
    hufton = json['hufton'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tong_saharlik'] = tongSaharlik;
    data['quyosh'] = quyosh;
    data['peshin'] = peshin;
    data['asr'] = asr;
    data['shom_iftor'] = shomIftor;
    data['hufton'] = hufton;
    return data;
  }
}
