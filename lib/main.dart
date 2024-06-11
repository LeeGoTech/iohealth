// ignore_for_file: library_private_types_in_public_api, empty_catches

import 'dart:async';
// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as gauges;
import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:syncfusion_flutter_charts/sparkcharts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'INSERT YOUR SUPABASE URL HERE',
    anonKey:
        'INSERT YOUR SUPABASE ANON KEY HERE',
  );
  runApp(const IoHealth());
}

class IoHealth extends StatelessWidget {
  const IoHealth({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoHealth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

// SPLASH SCREEN LOCATED HERE:

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const NavBar()),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          body: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Image.asset('images/Splash Screen Logo.png')],
              ))),
    );
  }
}

// MAIN SCREEN LOCATED HERE:

class NavBar extends StatefulWidget {
  const NavBar({super.key});
  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late StreamSubscription subscription;
  var isDeviceConnected = false;
  bool isAlertSet = false;

  @override
  void initState() {
    getConnectivity();
    super.initState();
  }

  getConnectivity() =>
      subscription = Connectivity().onConnectivityChanged.listen(
        (List<ConnectivityResult> result) async {
          isDeviceConnected = await InternetConnectionChecker().hasConnection;
          if (!isDeviceConnected && isAlertSet == false) {
            showDialogBox();
            setState(() => isAlertSet = true);
          }
        },
      );

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  int _selectedIndex = 0;
  final _screens = [
    const LiteScreen(),
    const HistoryScreen(),
    const FullScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Image.asset('images/IoHealth Logo.png',
              fit: BoxFit.contain, width: 50),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: _screens[_selectedIndex],
        bottomNavigationBar: SizedBox(
          height: 80,
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.black26,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.circle_grid_3x3), label: "Lite"),
              BottomNavigationBarItem(
                  icon: Icon(
                    CupertinoIcons.hourglass,
                  ),
                  label: "History"),
              BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.circle_grid_hex_fill),
                  label: "Full"),
            ],
          ),
        ),
      ),
    );
  }

  showDialogBox() => showCupertinoDialog<String>(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
            title: const Text("No Connection"),
            content: const Text("Please check your Internet connectivity."),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, 'Cancel');
                  setState(() => isAlertSet = false);
                  isDeviceConnected =
                      await InternetConnectionChecker().hasConnection;
                  if (!isDeviceConnected) {
                    showDialogBox();
                    setState(() => isAlertSet = true);
                  }
                },
                child: const Text("OK"),
              )
            ]),
      );
}

// SCREENS CLASSES LOCATED HERE:

class LiteScreen extends StatefulWidget {
  const LiteScreen({super.key});

  @override
  _LiteScreenState createState() => _LiteScreenState();
}

class _LiteScreenState extends State<LiteScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchData();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchVitalSignsData(int typeId) {
    final query = Supabase.instance.client
        .from('vitals')
        .select('data')
        .eq('type_id', typeId)
        .order('created_at', ascending: false)
        .limit(1);

    return query;
  }

  Future<void> fetchData() async {
    try {
      final temperatureData = await fetchVitalSignsData(1);
      final heartRateData = await fetchVitalSignsData(2);
      final pulseOxygenData = await fetchVitalSignsData(3);

      setState(() {
        temperature = temperatureData.isNotEmpty
            ? temperatureData[0]['data'].toString()
            : "N/A";
        heartRate = heartRateData.isNotEmpty
            ? heartRateData[0]['data'].toString()
            : "N/A";
        pulseOxygen = pulseOxygenData.isNotEmpty
            ? pulseOxygenData[0]['data'].toString()
            : "N/A";
      });
    } catch (error) {}
  }

  String? temperature;
  String? heartRate;
  String? pulseOxygen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder(
              future: fetchVitalSignsData(1),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const VitalSignItemPlaceholder(
                    color: Colors.blue,
                    title: "Temperature:",
                    icon: Icons.thermostat,
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    VitalSignItem(
                      title: "Temperature:",
                      value: temperature ?? "N/A",
                      unit: "°C",
                      icon: Icons.thermostat,
                      color: Colors.blue,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16.0),
            FutureBuilder(
              future: fetchVitalSignsData(2),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const VitalSignItemPlaceholder(
                    color: Colors.red,
                    title: "Heart Rate:",
                    icon: Icons.favorite,
                  );
                }
                return Column(
                  children: <Widget>[
                    VitalSignItem(
                      title: "Heart Rate:",
                      value: heartRate ?? "N/A",
                      unit: "BPM",
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16.0),
            FutureBuilder(
              future: fetchVitalSignsData(3),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const VitalSignItemPlaceholder(
                    color: Colors.green,
                    title: "Pulse Oxygen:",
                    icon: Icons.monitor_heart,
                  );
                }
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    VitalSignItem(
                      title: "Pulse Oxygen:",
                      value: pulseOxygen ?? "N/A",
                      unit: "%",
                      icon: Icons.monitor_heart,
                      color: Colors.green,
                    ),
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<DataRow> temperatureRows = [];
  late List<DataRow> heartRateRows = [];
  late List<DataRow> pulseOxygenRows = [];
  late List<Map<String, dynamic>> query = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchData();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final temperatureData = await fetchVitalSignsList(1);

      final heartRateData = await fetchVitalSignsList(2);

      final pulseOxygenData = await fetchVitalSignsList(3);

      setState(() {
        temperatureRows =
            temperatureData.isNotEmpty ? buildDataRows(temperatureData) : [];
        heartRateRows =
            heartRateData.isNotEmpty ? buildDataRows(heartRateData) : [];
        pulseOxygenRows =
            pulseOxygenData.isNotEmpty ? buildDataRows(pulseOxygenData) : [];
      });
    } catch (error) {}
  }

  Future<List<Map<String, dynamic>>> fetchVitalSignsList(int typeId) async {
    final query = Supabase.instance.client
        .from('vitals')
        .select('id, data, type_id, created_at')
        .eq('type_id', typeId)
        .order('created_at', ascending: false);

    return query;
  }

  String formatDate(DateTime dateTime) {
    return DateFormat('MM/dd/yyyy').format(dateTime);
  }

  String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  List<DataRow> buildDataRows(List<Map<String, dynamic>> data) {
    return data.map((row) {
      DateTime createdAt = DateTime.parse(row['created_at'].toString());
      String formattedDate = formatDate(createdAt);
      String formattedTime = formatTime(createdAt);

      int typeId = row['type_id'];
      double value = row['data'].toDouble();

      Color textColor = Colors.black;

      if (typeId == 1) {
        if (value >= 13.7 && value < 36.0) {
          textColor = Colors.orange;
        } else if (value >= 36.0 && value < 38.0) {
          textColor = Colors.green;
        } else if (value >= 38.0 && value <= 46.5) {
          textColor = Colors.red;
        }
      } else if (typeId == 2) {
        if (value >= 26 && value < 60) {
          textColor = Colors.orange;
        } else if (value >= 60 && value <= 100) {
          textColor = Colors.green;
        } else if (value >= 101 && value <= 120) {
          textColor = Colors.red;
        }
      } else if (typeId == 3) {
        if (value >= 95 && value <= 100) {
          textColor = Colors.green;
        } else if (value < 95) {
          textColor = Colors.red;
        }
      }

      return DataRow(cells: [
        DataCell(Text(
          row['data'].toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        )),
        DataCell(Text(
          formattedDate,
        )),
        DataCell(Text(
          formattedTime,
        )),
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(dividerColor: Colors.transparent);
    const TextStyle columnLabelStyle = TextStyle(fontWeight: FontWeight.bold);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            DropdownVitalItem(
              number: '1',
              title: "Temperature (°C)",
              icon: const Icon(Icons.thermostat),
              theme: theme,
              style: columnLabelStyle,
              color: Colors.blue,
              rows: temperatureRows,
            ),
            DropdownVitalItem(
              number: '2',
              title: "Heart Rate (BPM)",
              icon: const Icon(Icons.favorite),
              theme: theme,
              style: columnLabelStyle,
              color: Colors.red,
              rows: heartRateRows,
            ),
            DropdownVitalItem(
              number: '3',
              title: "Pulse Oxygen (%)",
              icon: const Icon(Icons.monitor_heart),
              theme: theme,
              style: columnLabelStyle,
              color: Colors.green,
              rows: pulseOxygenRows,
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreen extends StatefulWidget {
  const FullScreen({super.key});

  @override
  _FullScreenState createState() => _FullScreenState();
}

class _FullScreenState extends State<FullScreen> {
  late Timer _timer;
  late List<ChartData> pulseOxygenList = [];

  @override
  void initState() {
    super.initState();
    fetchData();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchVitalSignsData(int typeId) {
    final query = Supabase.instance.client
        .from('vitals')
        .select('data')
        .eq('type_id', typeId)
        .order('created_at', ascending: false)
        .limit(1);

    return query;
  }

  Future<List<Map<String, dynamic>>> fetchVitalSignsList(int typeId) async {
    final query = Supabase.instance.client
        .from('vitals')
        .select('id, data, created_at')
        .eq('type_id', typeId)
        .order('created_at', ascending: true);

    return query;
  }

  Future<void> fetchData() async {
    try {
      final temperatureData = await fetchVitalSignsData(1);
      final heartRateData = await fetchVitalSignsData(2);
      final latestPulseOxygenData = await fetchVitalSignsData(3);
      final pulseOxygenData = await fetchVitalSignsList(3);
      pulseOxygenList = buildDataList(pulseOxygenData);

      setState(() {
        temperature = temperatureData.isNotEmpty
            ? temperatureData[0]['data'].toString()
            : "0";
        heartRate = heartRateData.isNotEmpty
            ? heartRateData[0]['data'].toString()
            : "0";
        latestPulseOxygen = latestPulseOxygenData.isNotEmpty
            ? latestPulseOxygenData[0]['data'].toString()
            : "0";
        pulseOxygen = pulseOxygenList.isNotEmpty ? pulseOxygenList : [];
      });
    } catch (error) {}
  }

  String? temperature;
  String? heartRate;
  String? latestPulseOxygen;
  List<ChartData>? pulseOxygen;

  List<ChartData> buildDataList(List<Map<String, dynamic>> data) {
    List<ChartData> dataList = [];

    for (int i = 0; i < data.length; i++) {
      double pulseOxygen = data[i]['data'].toDouble();
      int index = i + 1;
      dataList.add(ChartData(index, pulseOxygen));
    }

    return dataList;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: GridView.custom(
              gridDelegate: SliverQuiltedGridDelegate(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                pattern: [
                  const QuiltedGridTile(1, 1),
                  const QuiltedGridTile(1, 1),
                  const QuiltedGridTile(1, 2),
                ],
              ),
              childrenDelegate: SliverChildListDelegate(
                [
                  FutureBuilder(
                    future: fetchVitalSignsData(1),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const TemperatureGaugeItem(
                            temperatureStringValue: "0");
                      }
                      return TemperatureGaugeItem(
                        temperatureStringValue: temperature ?? "0",
                      );
                    },
                  ),
                  FutureBuilder(
                    future: fetchVitalSignsData(2),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const HeartRateGaugeItem(
                            heartRateStringValue: "0");
                      }
                      return HeartRateGaugeItem(
                        heartRateStringValue: heartRate ?? "0",
                      );
                    },
                  ),
                  Stack(
                    children: [
                      Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monitor_heart,
                                color: Colors.green,
                                size: 30,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Pulse Oxygen',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: SfCartesianChart(
                              primaryXAxis: const CategoryAxis(
                                isVisible: false,
                              ),
                              primaryYAxis: NumericAxis(
                                minimum: 90,
                                maximum: 100,
                                plotBands: <PlotBand>[
                                  PlotBand(
                                    isVisible: true,
                                    start: 90,
                                    end: 95,
                                    color: Colors.red.withOpacity(0.25),
                                  ),
                                ],
                              ),
                              series: <CartesianSeries>[
                                LineSeries<ChartData, int>(
                                  dataSource: pulseOxygen,
                                  xValueMapper: (ChartData data, _) => data.x,
                                  yValueMapper: (ChartData data, _) => data.y,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder(
            future: fetchVitalSignsData(1),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return VitalStatusChooser(
                stringValue: temperature ?? "0",
                type: "Temperature",
              );
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: fetchVitalSignsData(2),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return VitalStatusChooser(
                stringValue: heartRate ?? "0",
                type: "Heart Rate",
              );
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: fetchVitalSignsData(3),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }
              return VitalStatusChooser(
                stringValue: latestPulseOxygen ?? "0",
                type: "Pulse Oxygen",
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final int x;
  final double y;
}

// ITEM CLASSES LOCATED HERE:

class VitalSignItem extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const VitalSignItem({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.red;
    double? convertedValue;
    try {
      convertedValue = double.tryParse(value);
    } catch (e) {}

    if (convertedValue != null) {
      if (convertedValue >= 13.7 &&
          convertedValue < 36.0 &&
          title == "Temperature:") {
        textColor = Colors.orange;
      } else if (convertedValue >= 36.0 &&
          convertedValue < 38.0 &&
          title == "Temperature:") {
        textColor = Colors.green;
      } else if (convertedValue >= 38.0 &&
          convertedValue <= 46.5 &&
          title == "Temperature:") {
        textColor = Colors.red;
      } else if (convertedValue >= 26 &&
          convertedValue < 60 &&
          title == "Heart Rate:") {
        textColor = Colors.orange;
      } else if (convertedValue >= 60 &&
          convertedValue <= 100 &&
          title == "Heart Rate:") {
        textColor = Colors.green;
      } else if (convertedValue >= 101 &&
          convertedValue <= 120 &&
          title == "Heart Rate") {
        textColor = Colors.red;
      } else if (convertedValue >= 95 &&
          convertedValue <= 100 &&
          title == "Pulse Oxygen:") {
        textColor = Colors.green;
      } else if (convertedValue > 95 &&
          convertedValue <= 1 &&
          title == "Pulse Oxygen:") {
        textColor = Colors.red;
      }
    } else {
      textColor = Colors.black;
    }

    return Container(
      alignment: Alignment.center,
      child: SizedBox(
        width: 242,
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 24.0,
              color: color,
            ),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8.0),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: value == 'N/A' ? 16 : 20,
                      color: value == 'N/A' ? Colors.red : textColor,
                      fontWeight:
                          value == 'N/A' ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value == 'N/A' ? '' : ' ',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: textColor,
                    ),
                  ),
                  TextSpan(
                    text: value == 'N/A' ? '' : unit,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: value == 'N/A' ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VitalSignItemPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const VitalSignItemPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: SizedBox(
        width: 242,
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 24.0,
              color: color,
            ),
            const SizedBox(width: 8.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8.0),
            const Text(
              "N/A",
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DropdownVitalItem extends StatelessWidget {
  final String number;
  final String title;
  final Widget icon;
  final ThemeData theme;
  final TextStyle style;
  final Color color;
  final List<DataRow> rows;

  const DropdownVitalItem({
    super.key,
    required this.number,
    required this.title,
    required this.icon,
    required this.theme,
    required this.style,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
          color: Colors.white.withOpacity(0.0),
        ),
        child: Theme(
          data: theme,
          child: ExpansionTile(
            iconColor: color,
            collapsedIconColor: color,
            tilePadding:
                const EdgeInsets.only(left: 10, right: 20, top: 5, bottom: 5),
            leading: icon,
            title: Text(
              'Vital #$number',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 5,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: [
                      DataColumn(label: Text("Value", style: style)),
                      DataColumn(label: Text('Date', style: style)),
                      DataColumn(label: Text('Time', style: style)),
                    ],
                    rows: rows,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemperatureGaugeItem extends StatelessWidget {
  final String temperatureStringValue;

  const TemperatureGaugeItem({
    super.key,
    required this.temperatureStringValue,
  });

  @override
  Widget build(BuildContext context) {
    double value = double.parse(temperatureStringValue);
    Color generalColor = Colors.black;

    if (value >= 13.7 && value < 36.0) {
      generalColor = Colors.orange;
    } else if (value >= 36.0 && value < 38.0) {
      generalColor = Colors.green;
    } else if (value >= 38.0 && value <= 46.5) {
      generalColor = Colors.red;
    }
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          showLabels: false,
          showTicks: false,
          radiusFactor: 0.9,
          minimum: 13.7,
          maximum: 46.5,
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: 13.7,
              endValue: 36.0,
              color: Colors.orange,
            ),
            GaugeRange(
              startValue: 36.0,
              endValue: 38.0,
              color: Colors.green,
            ),
            GaugeRange(
              startValue: 38.0,
              endValue: 46.5,
              color: Colors.red,
            ),
          ],
          axisLineStyle:
              const AxisLineStyle(cornerStyle: gauges.CornerStyle.bothCurve),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: value,
              needleStartWidth: 1,
              needleEndWidth: 5,
              needleLength: 0,
              knobStyle: KnobStyle(knobRadius: 0.05, color: generalColor),
            ),
            MarkerPointer(
              value: value,
              markerHeight: 10,
              markerWidth: 10,
              elevation: 4,
              markerOffset: -3,
              color: Colors.black54,
              enableAnimation: true,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.thermostat, size: 20, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "$value",
                          style: TextStyle(
                            fontSize: 15.0,
                            color: generalColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: " °C",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              positionFactor: 0.5,
              angle: 90,
            ),
          ],
        ),
      ],
    );
  }
}

class HeartRateGaugeItem extends StatelessWidget {
  final String heartRateStringValue;

  const HeartRateGaugeItem({
    super.key,
    required this.heartRateStringValue,
  });

  @override
  Widget build(BuildContext context) {
    double value = double.parse(heartRateStringValue);
    Color generalColor = Colors.black;
    if (value >= 26 && value < 60) {
      generalColor = Colors.orange;
    } else if (value >= 60 && value <= 100) {
      generalColor = Colors.green;
    } else if (value >= 101 && value <= 120) {
      generalColor = Colors.red;
    }
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          showLabels: false,
          showTicks: false,
          radiusFactor: 0.9,
          minimum: 26,
          maximum: 120,
          ranges: <GaugeRange>[
            GaugeRange(
              startValue: 26,
              endValue: 60,
              color: Colors.orange,
            ),
            GaugeRange(
              startValue: 60,
              endValue: 100,
              color: Colors.green,
            ),
            GaugeRange(
              startValue: 100,
              endValue: 120,
              color: Colors.red,
            ),
          ],
          axisLineStyle:
              const AxisLineStyle(cornerStyle: gauges.CornerStyle.bothCurve),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: value,
              needleStartWidth: 1,
              needleEndWidth: 5,
              needleLength: 0,
              knobStyle: KnobStyle(knobRadius: 0.05, color: generalColor),
            ),
            MarkerPointer(
              value: value,
              markerHeight: 10,
              markerWidth: 10,
              elevation: 4,
              markerOffset: -3,
              color: Colors.black54,
              enableAnimation: true,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.favorite, size: 20, color: Colors.red),
                  const SizedBox(width: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "$value",
                          style: TextStyle(
                            fontSize: 15.0,
                            color: generalColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: " BPM",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              positionFactor: 0.5,
              angle: 90,
            ),
          ],
        ),
      ],
    );
  }
}

class VitalStatusItem extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final String text;

  const VitalStatusItem({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 4.0),
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      children: [
                        Text(
                          text,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class VitalStatusChooser extends StatelessWidget {
  final String stringValue;
  final String type;

  const VitalStatusChooser({
    super.key,
    required this.stringValue,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    double value = double.parse(stringValue);
    if (value >= 13.7 && value < 36.0 && type == "Temperature") {
      return const VitalStatusItem(
          backgroundColor: Color(0xffffe8c8),
          borderColor: Color(0xffffc96f),
          textColor: Color(0xffffa62f),
          icon: Icons.thermostat,
          iconColor: Colors.blue,
          text:
              "You might have a hypothermia. Seek medical attention as soon as possible.");
    } else if (value >= 36.0 && value < 38.0 && type == "Temperature") {
      return const VitalStatusItem(
          backgroundColor: Color(0xFFF6EEC9),
          borderColor: Color(0xffa1dd70),
          textColor: Color(0xff799351),
          icon: Icons.thermostat,
          iconColor: Colors.blue,
          text: "You got a normal temperature. Keep it up.");
    } else if (value >= 38.0 && value <= 46.5 && type == "Temperature") {
      return const VitalStatusItem(
          backgroundColor: Color(0xffE6CCCF),
          borderColor: Color(0xffD6BCBF),
          textColor: Colors.red,
          icon: Icons.thermostat,
          iconColor: Colors.blue,
          text:
              "You might have a hyperthermia or fever. Consult to a doctor immediately.");
    } else if (value >= 26 && value < 60 && type == "Heart Rate") {
      return const VitalStatusItem(
          backgroundColor: Color(0xffffe8c8),
          borderColor: Color(0xffffc96f),
          textColor: Color(0xffffa62f),
          icon: Icons.favorite,
          iconColor: Colors.red,
          text:
              "You might have a bradycardia. Seek medical attention as soon as possible.");
    } else if (value >= 60 && value <= 100 && type == "Heart Rate") {
      return const VitalStatusItem(
          backgroundColor: Color(0xFFF6EEC9),
          borderColor: Color(0xffa1dd70),
          textColor: Color(0xff799351),
          icon: Icons.favorite,
          iconColor: Colors.red,
          text: "You got a normal heart rate. Keep it up.");
    } else if (value >= 101 && value <= 120 && type == "Heart Rate") {
      return const VitalStatusItem(
          backgroundColor: Color(0xffE6CCCF),
          borderColor: Color(0xffD6BCBF),
          textColor: Colors.red,
          icon: Icons.favorite,
          iconColor: Colors.red,
          text:
              "You might have a tachycardia. Consult to a doctor immediately.");
    } else if (value >= 95 && value <= 100 && type == "Pulse Oxygen") {
      return const VitalStatusItem(
          backgroundColor: Color(0xFFF6EEC9),
          borderColor: Color(0xffa1dd70),
          textColor: Color(0xff799351),
          icon: Icons.monitor_heart,
          iconColor: Colors.green,
          text: "You got a normal pulse oxygen. Keep it up.");
    } else if (value < 95 && value >= 1 && type == "Pulse Oxygen") {
      return const VitalStatusItem(
          backgroundColor: Color(0xffE6CCCF),
          borderColor: Color(0xffD6BCBF),
          textColor: Colors.red,
          icon: Icons.monitor_heart,
          iconColor: Colors.green,
          text: "You might have an hypoxia. Consult to a doctor immediately.");
    }
    return Container();
  }
}
