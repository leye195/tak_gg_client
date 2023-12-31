import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:tak_gg/screens/auth_screen.dart';
import 'package:tak_gg/screens/home_screen.dart';
import 'package:tak_gg/services/api_service.dart';
import 'package:tak_gg/states/user_controller.dart';
import 'package:tak_gg/utils/auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 1500), () async {
      final UserController userController = Get.put(UserController());
      final result = await checkIsAuthorized();
      final playerId = await getPlayerId();

      if (!mounted) return;

      if (result == true) {
        ApiService.getPlayer(playerId).then((value) {
          final player = value;
          userController.updateUser({
            "playerId": player.playerId,
            "profileImage": player.profileImage,
            "displayName": player.displayName,
            "racket": player.racket,
            "rubberList": List<String>.from(player.rubberList ?? []),
            "ratingPoint": player.ratingPoint,
            "style": player.style,
            'winCount': player.matchStat?.winCount ?? '0',
            "loseCount": player.matchStat?.loseCount ?? '0',
            "total": player.matchStat?.total ?? '0',
          });
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  settings: const RouteSettings(name: "/home"),
                  builder: (context) => const HomeScreen(),
                  fullscreenDialog: true));
        }).catchError((e) {
          resetSession();
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  settings: const RouteSettings(name: "/auth"),
                  builder: (context) => const AuthScreen(),
                  fullscreenDialog: true));
        });
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const AuthScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const String logo = 'assets/takgg_icon_rdbox.svg';

    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
        onWillPop: () async => false,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: screenHeight * 0.384375),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      logo,
                      width: screenWidth * 0.2,
                      height: screenHeight * 0.2,
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.0625,
                ),
              ],
            ),
          ),
        ));
  }
}
