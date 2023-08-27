import 'package:flutter/material.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';
import 'package:get/get.dart';
import 'package:tak_gg/models/item_model.dart';
import 'package:tak_gg/screens/auth_screen.dart';
import 'package:tak_gg/services/api_service.dart';
import 'package:tak_gg/states/user_controller.dart';
import 'package:tak_gg/utils/auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late List<RubberModel> rubbers = [];
  late List<RacketModel> rackets = [];

  Map<String, dynamic> selected = {
    'style': '',
    'rubber': <String>[],
    'racket': 0,
  };

  void fetchItemList() async {
    final data = await ApiService.getAllItems();
    final List<RubberModel> rubberList =
        List<RubberModel>.from(data['rubbers']);
    final List<RacketModel> racketList =
        List<RacketModel>.from(data['rackets']);

    setState(() {
      rubbers = rubberList;
      rackets = racketList;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchItemList();
  }

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.put(UserController());

    void handleEditStyle() {
      showMaterialRadioPicker(
          context: context,
          items: ['shake', 'penhold'],
          selectedItem: selected['style'] == ''
              ? userController.style.toLowerCase()
              : selected['style'],
          onChanged: (value) {
            setState(() {
              selected['style'] = value;
            });
          },
          onConfirmed: () async {
            if (selected['style'] == userController.style.toLowerCase()) return;

            await ApiService.modifyPlayer(style: selected['style']);
            setState(() {
              userController.updateUser(
                  {'style': selected['style'].toString().toUpperCase()});
            });
          },
          onCancelled: () {
            setState(() {
              selected['style'] = '';
            });
          });
    }

    void handleEditRacket() {
      showMaterialRadioPicker(
          context: context,
          items: rackets,
          selectedItem: selected['racket'] != 0
              ? rackets[selected['racket'] - 1]
              : selected['racket'],
          onChanged: (value) {
            final id = (value as RacketModel).id;
            setState(() {
              selected['racket'] = id;
            });
          },
          onConfirmed: () async {
            final res =
                await ApiService.modifyPlayer(racket: selected['racket']);
            setState(() {
              userController.updateUser({'racket': res.racket});
            });
          },
          onCancelled: () {
            setState(() {
              selected['racket'] = 0;
            });
          });
    }

    void handleEditRubber() {
      showMaterialCheckboxPicker(
          context: context,
          items: rubbers,
          onChanged: (value) async {
            final ids = value.map((rubber) => rubber.id).toList();
            final res = await ApiService.modifyPlayer(rubbers: ids);
            setState(() {
              userController.updateUser(
                  {'rubberList': List<String>.from(res.rubberList ?? [])});
            });
          },
          onCancelled: () {
            setState(() {
              selected['rubber'] = [];
            });
          });
    }

    void handleSignOut() {
      resetSession();
      userController.resetUser();
      setState(() {
        Navigator.of(context).popUntil(ModalRoute.withName("/home"));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                settings: const RouteSettings(name: "/auth"),
                builder: (context) => const AuthScreen(),
                fullscreenDialog: true));
      });
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Transform.scale(
                  scale: 2.5,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(100),
                        bottomRight: Radius.circular(100)),
                    child: Container(
                      width: 200,
                      height: 90,
                      color: Colors.blue,
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(userController.displayName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white))),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(userController.profileImage)),
                const SizedBox(height: 32),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                width: 1.0,
                                color: Colors.black12,
                              ))),
                              child: InkWell(
                                onTap: handleEditStyle,
                                child: PlayerInfo(
                                    name: 'Style',
                                    value: userController.style.toUpperCase()),
                              ),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                width: 1.0,
                                color: Colors.black12,
                              ))),
                              child: InkWell(
                                  onTap: handleEditRacket,
                                  child: PlayerInfo(
                                      name: 'Racket',
                                      value: userController.racket ?? 'None')),
                            ),
                            Container(
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                width: 1.0,
                                color: Colors.black12,
                              ))),
                              child: InkWell(
                                  onTap: handleEditRubber,
                                  child: PlayerInfo(
                                      name: 'Rubber',
                                      value: userController.rubberList
                                              ?.join(',') ??
                                          'None')),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rating Point',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600)),
                                Text('${userController.ratingPoint}.LP',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500))
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: handleSignOut,
                        child: const Text('Sign Out'))
                  ],
                )
              ],
            )));
  }
}

class PlayerInfo extends StatelessWidget {
  const PlayerInfo({
    super.key,
    required this.name,
    required this.value,
  });

  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          Row(
            children: [
              Text(value),
              const SizedBox(width: 4),
              const Icon(
                Icons.edit,
                size: 16,
              )
            ],
          )
        ],
      ),
    );
  }
}
