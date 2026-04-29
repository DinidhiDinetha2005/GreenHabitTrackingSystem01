import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              "https://images.unsplash.com/photo-1720198143689-07ed12af857b?w=700&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8ODEwfHxncmVlbiUyMGZvcmVzdHxlbnwwfHwwfHx8MA%3D%3D",
            ),
            fit: BoxFit.cover,
          ),
        ),




        child: Padding(
          padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //const Icon(Icons.eco, size: 90),
            const SizedBox(height: 150),
            const Text(
              "Green Habit",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 43,
                  color: Colors.white,
                  fontWeight:FontWeight.w700),

              textAlign: TextAlign.left,
            ),
            const Text(
              "Tracker",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 43,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),

              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 10),
            const Text(
              "Build sustainable habits, track your progress, and earn eco-points for everyday actions.",
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400),

              textAlign: TextAlign.left,
            ),



            const SizedBox(height: 300),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000000),


                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),

                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/auth");
                },
                child: const Text(
                  "Get Started",

                  style: TextStyle(
                    fontFamily: 'Poppins',
                  color: Colors.white ,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}