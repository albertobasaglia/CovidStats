class HistoryData {
  String country;
  List<String> provinces;
  Timeline timeline;

  HistoryData({this.country, this.provinces, this.timeline});

  HistoryData.fromJson(Map<String, dynamic> json) {
    country = json['country'];
    provinces = json['provinces'] != null ? json['provinces'].cast<String>() : null;
    timeline = json['timeline'] != null
        ? new Timeline.fromJson(json['timeline'])
        : null;
  }

  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //   data['country'] = this.country;
  //   data['provinces'] = this.provinces;
  //   if (this.timeline != null) {
  //     data['timeline'] = this.timeline.toJson();
  //   }
  //   return data;
  // }
}

class Timeline {
  Map<String,dynamic> cases;
  Map<String,dynamic> deaths;
  Map<String,dynamic> recovered;

  Timeline({this.cases, this.deaths, this.recovered});

  Timeline.fromJson(Map<String, dynamic> json) {
    this.cases = json["cases"];
    this.deaths = json["deaths"];
    this.recovered = json["recovered"];
  }

  // Map<String, dynamic> toJson() {
  //   final Map<String, dynamic> data = new Map<String, dynamic>();
  //   if (this.cases != null) {
  //     data['cases'] = this.cases.toJson();
  //   }
  //   if (this.deaths != null) {
  //     data['deaths'] = this.deaths.toJson();
  //   }
  //   if (this.recovered != null) {
  //     data['recovered'] = this.recovered.toJson();
  //   }
  //   return data;
  // }
}
