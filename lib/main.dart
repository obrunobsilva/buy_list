import 'package:buy_list/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: HomePage(),
      theme: ThemeData(primaryColor: Colors.black),
      debugShowCheckedModeBanner: false,
    ),
  );
}
