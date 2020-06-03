//TODO scegliere se mostrare ordinato per ordine alfabetico, nuovi casi, casi totali.
import 'dart:convert';

import 'package:covidstats/models/simpleState.dart';
import 'package:covidstats/models/summaryData.dart';
import 'package:covidstats/widgets/countrySimpleData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Covid-19 Stats',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Covid-19 Stats'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<SimpleState> simpleStates = [];
  SummaryData today;
  SummaryData yesterday;
  String queryFilter = "";
  int recentStateId = -1;
  int favoriteStateId = -1;
  @override
  void initState() {
    super.initState();
    http
        .get('https://corona.lmao.ninja/v2/countries?yesterday=false')
        .then((Response res) {
      setState(() {
        simpleStates = (json.decode(res.body) as List)
            .map((model) => SimpleState.fromJson(model))
            .toList();
      });
      
    });
    http
        .get('https://corona.lmao.ninja/v2/all?yesterday=false')
        .then((Response res) {
      setState(() {
        today = SummaryData.fromJson(json.decode(res.body));
      });
    });
    http
        .get('https://corona.lmao.ninja/v2/all?yesterday=true')
        .then((Response res) {
      setState(() {
        yesterday = SummaryData.fromJson(json.decode(res.body));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
        setState(() {
          String recentStateIso = prefs.getString('recentIso2');
          if (recentStateIso == null) {
            recentStateId = -1;
          } else {
            recentStateId = simpleStates.indexWhere((SimpleState state) =>
                state.countryInfo.iso2 == recentStateIso);
          }
          String favoriteStateIso = prefs.getString('favoriteIso2');
          if (favoriteStateIso == null) {
            favoriteStateId = -1;
          } else {
            favoriteStateId = simpleStates.indexWhere((SimpleState state) =>
                state.countryInfo.iso2 == favoriteStateIso);
          }
        });
      });
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 12,
            ),
            Container(
              //height: 200,
              child: Column(
                  children: (today != null && yesterday != null)
                      ? [
                          Text(
                              'Total Cases: ${today.cases} (yesterday ${yesterday.cases})'),
                          Text(
                              'New Cases: ${today.todayCases} (yesterday ${yesterday.todayCases})'),
                          Text(
                              'Total Deaths: ${today.deaths} (yesterday ${yesterday.deaths})'),
                          Text(
                              'New Deaths: ${today.todayDeaths} (yesterday ${yesterday.todayDeaths})'),
                        ]
                      : [] //TODO show a spinner,
                  ),
            ),
            SizedBox(
              height: 12,
            ),
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Country query',
                ),
                onChanged: (value) {
                  setState(() {
                    queryFilter = value;
                  });
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              margin: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                children: <Widget>[
                  Text('Last:'),
                  (recentStateId != -1)
                      ? AppCountryListItem(simpleStates[recentStateId], null)
                      : AppCountryListItem(null, 'No recent state found!'),
                  Text('Favorite:'),
                  (favoriteStateId != -1)
                      ? AppCountryListItem(simpleStates[favoriteStateId], null)
                      : AppCountryListItem(null, 'No favorite state found!'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: simpleStates.length,
                  itemBuilder: (BuildContext context, int index) {
                    if (simpleStates[index]
                        .country
                        .contains(RegExp(queryFilter, caseSensitive: false))) {
                      return AppCountryListItem(simpleStates[index], null);
                    } else {
                      return SizedBox();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCountryListItem extends StatelessWidget {
  final SimpleState simpleState;
  final String message;
  AppCountryListItem(this.simpleState, this.message);
  @override
  Widget build(BuildContext context) {
    return new Container(
      padding: EdgeInsets.all(4),
      margin: EdgeInsets.all(2),
      child: (this.message == null)
          ? Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                  height: 30,
                  child: (simpleState.countryInfo.iso2 != null)
                      ? SvgPicture.network(
                          'https://cdn.staticaly.com/gh/hjnilsson/country-flags/master/svg/${simpleState.countryInfo.iso2.toLowerCase()}.svg')
                      : null,
                ),
                //TODO fix images
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Text(simpleState.country +
                      ' (${simpleState.todayCases} new cases)'),
                ),
                FlatButton(
                  child: Text('Details'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CountrySimplePage(simpleState),
                      ),
                    );
                  },
                )
              ],
            )
          : Row(
              children: <Widget>[
                SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: Text(this.message),
                ),
              ],
            ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
