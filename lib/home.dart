import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool switchValue = false;
  String isconnected = "";

  @override
  void initState () {
    super.initState();
    setState(() {
      if(switchValue == true){
        isconnected = "Connected !";
      }else{
        isconnected = "Not Connected !";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 53.0,
            left: 25.0,
            right: 0,
            child: Center(
              child: Text(
                isconnected,
                style: const TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 35.0, top: 50.0),
              child: Transform.scale(
                scale: 1.5,
                child: Switch(
                  value: switchValue,
                  onChanged: (value) {
                    setState(() {
                      switchValue = value;
                      if(switchValue == true){
                        isconnected = "Connected !";
                      }else{
                        isconnected = "Not Connected !";
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 140.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(width: 25.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle forward button press
                      },
                      child: Image.asset(
                        'assets/left.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                    const SizedBox(width: 25.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle rightward button press
                      },
                      child: Image.asset(
                        'assets/right.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 200.0,top: 160.0,),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(10.0,), // Set padding to zero
                ),
                onPressed: () {
                  // Handle brake button press
                },
                child: Image.asset(
                  'assets/brake.png',
                  width: 100.0, 
                  height: 100.0,
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle forward button press
                      },
                      child: Image.asset(
                        'assets/up.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                    const SizedBox(height: 20.0,),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(10.0,), // Set padding to zero
                      ),
                      onPressed: () {
                        // Handle rightward button press
                      },
                      child: Image.asset(
                        'assets/down.png',
                        width: 100.0, 
                        height: 100.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20.0,),
              ],
            ),
          )
        ],
      ),
    );
  }
}
