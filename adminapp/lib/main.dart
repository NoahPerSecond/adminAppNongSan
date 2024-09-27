import 'package:adminapp/screens/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  runApp(MainApp());
  try{
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    
    print('Ket noi firebase thanh cong');
  }catch(e)
  {
    print(e.toString());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainScreen());
  }
}
