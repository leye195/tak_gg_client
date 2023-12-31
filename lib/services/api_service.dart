import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tak_gg/models/game_model.dart';
import 'package:tak_gg/models/item_model.dart';
import 'package:tak_gg/models/player_model.dart';
import 'package:tak_gg/models/rank_model.dart';

final Map<String, String> commonHeaders = {
  'Content-Type': 'application/json',
};

class ApiService {
  static const baseUrl =
      "https://xnvgk6ye12.execute-api.ap-northeast-2.amazonaws.com/dev/v1";

  static Future<PlayerModel> postAuthRequest(String token) async {
    final url = Uri.parse('$baseUrl/auth');
    final response = await http.post(url, body: {'oneTimeToken': token});

    if (response.statusCode == 200) {
      final result = jsonDecode(utf8.decode(response.bodyBytes));
      final String accessToken = result['data']['accessToken'];
      final PlayerModel player = PlayerModel.fromJSON(result['data']['player']);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('accessToken', accessToken);
      prefs.setString('playerId', player.playerId);

      return player;
    }

    throw Error();
  }

  static Future<List<PlayerModel>> getPlayers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accToken = prefs.getString('accessToken');

    Map<String, String> headers = commonHeaders;
    headers['Authorization'] = 'Bearer $accToken';

    List<PlayerModel> playerList = [];
    final url = Uri.parse('$baseUrl/players');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
      final List<dynamic> players = data;

      for (var player in players) {
        playerList.add(PlayerModel.fromJSON(player));
      }
      return playerList;
    }

    throw Error();
  }

  static Future<PlayerModel> getPlayer(String playerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accToken = prefs.getString('accessToken');

    Map<String, String> headers = commonHeaders;
    headers['Authorization'] = 'Bearer $accToken';

    final url = Uri.parse('$baseUrl/players/$playerId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      final player = PlayerModel.fromJSON(data);
      return player;
    }

    throw Error();
  }

  static Future<PlayerModel> modifyPlayer(
      {String? style, int? racket, List<int>? rubbers}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accToken = prefs.getString('accessToken');

    Map<String, String> headers = commonHeaders;
    headers['Authorization'] = 'Bearer $accToken';

    final url = Uri.parse('$baseUrl/players');
    final data = {"style": style, "racket": racket, 'rubbers': rubbers};
    data.removeWhere((key, value) => value == null);

    final response =
        await http.patch(url, headers: headers, body: jsonEncode(data));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      final player = PlayerModel.fromJSON(data);
      return player;
    }

    throw Error();
  }

  static Future<List<RankModel>> getRankList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accToken = prefs.getString('accessToken');

    List<RankModel> rankList = [];
    Map<String, String> headers = commonHeaders;
    headers['Authorization'] = 'Bearer $accToken';

    final url = Uri.parse('$baseUrl/ranking');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ranks = data['data'];

      for (var rank in ranks) {
        final RankModel ranker = RankModel.fromJSON(rank);

        rankList.add(ranker);
      }

      return rankList;
    }

    throw Error();
  }

  static Future<bool> postGameResult(
      List<Map<String, dynamic>> resultList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final accToken = prefs.getString('accessToken');

    Map<String, String> headers = commonHeaders;
    headers['Authorization'] = 'Bearer $accToken';

    final url = Uri.parse('$baseUrl/games');
    final response = await http.post(url,
        headers: headers, body: jsonEncode({"resultList": resultList}));

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  static Future<Map<String, dynamic>> getMatchHistory(
      String playerId, int? page) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final accToken = prefs.getString('accessToken');

      List<GameModel> historyList = [];
      Map<String, String> headers = commonHeaders;
      headers['Authorization'] = 'Bearer $accToken';

      final url = Uri.parse('$baseUrl/games/$playerId?page=${page ?? 1} ');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> histories = data['data']['games'];
        final String total = data['data']['total'];

        for (var history in histories) {
          historyList.add(GameModel.fromJSON(history));
        }

        return {
          'total': total,
          'data': historyList,
        };
      }

      throw Error();
    } catch (e) {
      return {'total': 0, 'data': []};
    }
  }

  static Future<Map<String, dynamic>> getAllItems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final accToken = prefs.getString('accessToken');

      Map<String, String> headers = commonHeaders;
      headers['Authorization'] = 'Bearer $accToken';

      List<RubberModel> rubberList = [];
      List<RacketModel> racketList = [];

      final url = Uri.parse('$baseUrl/items');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final List<dynamic> rubbers = data['rubbers'];
        final List<dynamic> rackets = data['rackets'];

        for (var rubber in rubbers) {
          rubberList.add(RubberModel.fromJSON(rubber));
        }

        for (var racket in rackets) {
          racketList.add(RacketModel.fromJSON(racket));
        }

        return {'rubbers': rubberList, 'rackets': racketList};
      }

      throw Error();
    } catch (e) {
      return {'rubbers': [], 'rackets': []};
    }
  }
}
