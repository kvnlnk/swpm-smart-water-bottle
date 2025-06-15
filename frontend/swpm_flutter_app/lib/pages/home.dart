import 'package:flutter/material.dart';
import '../components/water_bottle/water_bottle.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  double waterLevel = 0.5;
  int selectedStyle = 0;

  @override
  Widget build(BuildContext context) {
    final plain = WaterBottle(
      waterColor: Colors.blue,
      bottleColor: Colors.lightBlue,
      capColor: Colors.blueGrey,
      waterLevel: waterLevel,
    );

    final bottle = Center(
      child: SizedBox(width: 200, height: 300, child: plain),
    );

    final waterSlider = Padding(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.opacity),
          SizedBox(width: 10),
          Expanded(
            child: Slider(
              value: waterLevel,
              max: 1.0,
              min: 0.0,
              onChanged: (value) {
                setState(() {
                  waterLevel = value;
                });
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Smart Water Bottle",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Spacer(), bottle, Spacer(), waterSlider, Spacer()],
        ),
      ),
    );
  }
}
