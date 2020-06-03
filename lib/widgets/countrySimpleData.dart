import 'package:covidstats/models/historyData.dart';
import 'package:covidstats/models/simpleState.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountrySimplePage extends StatefulWidget {
  final SimpleState country;
  CountrySimplePage(this.country);
  @override
  State<StatefulWidget> createState() {
    return CountrySimplePageState(this.country);
  }
}

class CountrySimplePageState extends State<StatefulWidget> {
  SimpleState country;
  List<TimeSeriesCases> casesData = [];
  List<TimeSeriesCases> deathsData = [];
  List<TimeSeriesCases> recoveredData = [];
  int howMany = -50;
  List<DropElement> dropElements = <DropElement>[
    DropElement('Last Week', 7),
    DropElement('Last 2 Weeks', 14),
    DropElement('Last Month', 30),
    DropElement('Last 2 Months', 60),
    DropElement('All', 0),
  ];
  DropElement selected;
  CountrySimplePageState(this.country);
  DateFormat format = new DateFormat("yMd");
  bool isFavorite = false;
  @override
  void initState() {
    super.initState();
    selected = dropElements[4];
    http
        .get(
            'https://corona.lmao.ninja/v2/historical/${country.country}?lastdays=all') //TODO make days number custom
        .then((Response res) {
      HistoryData data = HistoryData.fromJson(json.decode(res.body));
      setState(() {
        //getting cases data
        casesData = [];
        deathsData = [];
        recoveredData = [];
        if (data.timeline != null && data.timeline.cases != null) {
          data.timeline.cases.keys.forEach((key) {
            DateTime fuckApi = format.parse(key);
            DateTime date =
                DateTime(fuckApi.year + 2000, fuckApi.month, fuckApi.day);
            casesData.add(
              TimeSeriesCases(date, data.timeline.cases[key]),
            );
            deathsData.add(
              TimeSeriesCases(date, data.timeline.deaths[key]),
            );
            recoveredData.add(
              TimeSeriesCases(date, data.timeline.recovered[key]),
            );
          });
        }
      });
    });
    SharedPreferences.getInstance().then((prefs) async {
      isFavorite =
          (prefs.getString('favoriteIso2') == country.countryInfo.iso2);
      await prefs.setString('recentIso2', country.countryInfo.iso2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(country.country),
        actions: <Widget>[
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              SharedPreferences.getInstance().then((prefs) async {
                if (isFavorite) {
                  prefs.remove('favoriteIso2');
                } else {
                  prefs.setString('favoriteIso2', country.countryInfo.iso2);
                }
                setState(() {
                  isFavorite = !isFavorite;
                });
              });
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 16,
            ),
            Container(
              child: Row(children: [
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text('Total Cases: ${country.cases}'),
                      Text('New Cases: ${country.todayCases}'),
                      Text('Total Deaths: ${country.deaths}'),
                      Text('New Deaths: ${country.todayDeaths}'),
                    ],
                  ),
                ),
                Container(
                  width: 140,
                  child: DropdownButton<DropElement>(
                    value: selected,
                    icon: Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (DropElement newValue) {
                      setState(() {
                        selected = newValue;
                        howMany = selected.value;
                      });
                    },
                    items: dropElements.map<DropdownMenuItem<DropElement>>(
                        (DropElement value) {
                      return DropdownMenuItem<DropElement>(
                        value: value,
                        child: Text(value.show),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(
                  width: 32,
                ),
              ]),
            ),
            SizedBox(
              height: 16,
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: charts.TimeSeriesChart(
                  [
                    getSeriesFromDate(
                        'Cases',
                        (howMany == 0 ||
                                howMany > casesData.length ||
                                howMany < 1)
                            ? casesData
                            : casesData.sublist(
                                casesData.length - howMany, casesData.length),
                        charts.MaterialPalette.blue.shadeDefault),
                    getSeriesFromDate(
                        'Deaths',
                        (howMany == 0 ||
                                howMany > casesData.length ||
                                howMany < 1)
                            ? deathsData
                            : deathsData.sublist(
                                deathsData.length - howMany, casesData.length),
                        charts.MaterialPalette.red.shadeDefault),
                    getSeriesFromDate(
                        'Recovered',
                        (howMany == 0 ||
                                howMany > casesData.length ||
                                howMany < 1)
                            ? recoveredData
                            : recoveredData.sublist(
                                recoveredData.length - howMany,
                                casesData.length),
                        charts.MaterialPalette.green.shadeDefault),
                  ],
                  behaviors: [
                    new charts.SeriesLegend(),
                    new charts.PanAndZoomBehavior(),
                  ],
                  animate: false, //TODO causes a bug if true
                  //domainAxis: charts.DateTimeAxisSpec(viewport: charts.DateTimeExtents()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static charts.Series<TimeSeriesCases, DateTime> getSeriesFromDate(
      String name, List<TimeSeriesCases> data, charts.Color color) {
    return charts.Series<TimeSeriesCases, DateTime>(
        id: name,
        data: data,
        domainFn: (TimeSeriesCases datum, int intex) => datum.time,
        measureFn: (TimeSeriesCases datum, int intex) => datum.cases,
        colorFn: (TimeSeriesCases datum, int intex) => color);
  }
}

class TimeSeriesCases {
  final DateTime time;
  final int cases;
  TimeSeriesCases(this.time, this.cases);
}

class DropElement {
  final String show;
  final int value;
  DropElement(this.show, this.value);
}
