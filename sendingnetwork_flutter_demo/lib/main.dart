// ignore_for_file: unused_import, avoid_print
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:sdn/sdn.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import "package:web3dart/web3dart.dart";
import 'package:web3dart/crypto.dart';
import 'package:intl/intl.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:path_provider/path_provider.dart';

String privKey = ""; //
String addressHexAll = "";
String homeUrl = "";
late Room currentRoom;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final client = Client('SDN Example Chat', databaseBuilder: (_) async {
    final dir = await getApplicationSupportDirectory();
    final db = HiveCollectionsDatabase('sdn_example_chat', dir.path);
    await db.open();
    return db;
  });
  client.sdnnode = Uri.parse(homeUrl);
  await client.init();
  runApp(SDNExampleChat(client: client));
}

class SDNExampleChat extends StatelessWidget {
  final Client client;
  const SDNExampleChat({required this.client, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SDN Example Chat',
      builder: (context, child) => Provider<Client>(
        create: (context) => client,
        child: child,
      ),
      home: client.isLogged() ? const RoomListPage() : const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  createAddress() {
    Random rng = Random.secure();
    print("rng value: $rng"); //BigInt.from(12345678);

    getDIDList(addressHexAll);
  }

  Uint8List bigIntToUint8List(BigInt value) {
    List<int> byteList = [];
    while (value > BigInt.zero) {
      byteList.add(value.toUnsigned(8).toInt());
      value >>= 8;
    }
    byteList = byteList.reversed.toList();
    return Uint8List.fromList(byteList);
  }

  void getDIDList(String address) async {
    print('getDIDList address => $address');
    setState(() {
      _loading = true;
    });
    final client = Provider.of<Client>(context, listen: false);
    SDNDIDListResponse response = await client.getDIDList(address: address);
    print("getDIDList response.did= ${response.data}");
    if (response.data.isNotEmpty) {
      showToast("getDIDListresult:did=:${response.data[0]}");
    }
    postPreLoginDID(response, address);
    setState(() {
      _loading = false;
    });
  }

  void postPreLoginDID(SDNDIDListResponse response1, String address) async {
    setState(() {
      _loading = true;
    });
    final client = Provider.of<Client>(context, listen: false);
    String responseStr;
    if (response1.data.isNotEmpty) {
      responseStr = await client.postPreLoginDID(did: response1.data[0]);
    } else {
      responseStr = await client.postPreLoginDID(address: address);
    }
    final json = jsonDecode(responseStr);
    print("json=$responseStr");
    var response = SDNLoginResponse.fromJson(json as Map<String, Object?>);
    print("postPreLoginDID response.did= ${response.did}");
    print("postPreLoginDID response.message= ${response.message}");
    print("postPreLoginDID response.updated= ${response.updated}");
    print("postPreLoginDID random_server= ${response.random_server}");
    showToast("postPreLoginDIDresultdid=:${response.did}");
    postLoginDId(response);
    setState(() {
      _loading = false;
    });
  }

  void postLoginDId(SDNLoginResponse responsesdn) async {
    setState(() {
      _loading = true;
    });
    final client = Provider.of<Client>(context, listen: false);
    try {
      print("Message responsesdn.message : ${responsesdn.message}");
      String str = responsesdn.message; ////responsesdn.message;
      String signMessage = EthSigUtil.signPersonalMessage(
          privateKey: privKey, message: convertStringToUint8List(str));
      print("Message Hash signMessage (Uint8List): $signMessage");
      Map<String, dynamic> jsonData = {
        "did": responsesdn.did,
        "address": addressHexAll,
        "token": signMessage,
        "message": str
      };
      print("jsonString $jsonData");
      var response = await client.postLoginDId(
        type: "m.login.did.identity",
        updated: responsesdn.updated,
        identifier: jsonData,
        random_server: responsesdn.random_server,
      );

      print("postLoginDId response.access_token= ${response.access_token}");
      print("postLoginDId response.device_id= ${response.device_id}");
      print("postLoginDIdresponse.user_id= ${response.user_id}");
      showToast(
          "postLoginDIdresult:did=:${response.user_id} ${response.error} ${response.errorcode}  ");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoomListPage()),
        (route) => false,
      );
    } catch (e) {
      print('Exception caught: $e');
      showToast('Exception caught: $e');
    }
    setState(() {
      _loading = false;
    });
  }

  Uint8List encode(String s) {
    var encodedString = utf8.encode(s);
    var encodedLength = encodedString.length;
    var data = ByteData(encodedLength + 4);
    data.setUint32(0, encodedLength, Endian.big);
    var bytes = data.buffer.asUint8List();
    bytes.setRange(4, encodedLength + 4, encodedString);
    return bytes;
  }

  Uint8List convertStringToUint8List(String str) {
    final List<int> codeUnits = utf8.encode(str);
    final Uint8List unit8List = Uint8List.fromList(codeUnits);
    return unit8List;
  }

  void showToast(String text) {
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 13.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo network test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : createAddress,
                child: _loading
                    ? const LinearProgressIndicator()
                    : const Text('login'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: _loading
                    ? const LinearProgressIndicator()
                    : const Text('login need wallet address and privateKey'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class RoomListPage extends StatefulWidget {
  const RoomListPage({Key? key}) : super(key: key);

  @override
  _RoomListPageState createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
  void _logout() async {
    final client = Provider.of<Client>(context, listen: false);
    await client.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _join(Room room) async {
    if (room.membership != Membership.join) {
      print("roomid=${room.id}");
      currentRoom = room;
      await room.join();
      print("joined roomid=${room.id}");
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoomPage(room: room),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<Client>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: client.onSync.stream,
        builder: (context, _) => ListView.builder(
          itemCount: client.rooms.length,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(
              foregroundImage: client.rooms[i].avatar == null
                  ? null
                  : NetworkImage(
                      client.rooms[i].avatar!
                          .getThumbnail(
                            client,
                            width: 56,
                            height: 56,
                          )
                          .toString(),
                    ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(client.rooms[i].displayname)),
                if (client.rooms[i].notificationCount > 0)
                  Material(
                      borderRadius: BorderRadius.circular(99),
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child:
                            Text(client.rooms[i].notificationCount.toString()),
                      ))
              ],
            ),
            subtitle: Text(
              client.rooms[i].lastEvent?.body ?? 'No messages',
              maxLines: 1,
            ),
            onTap: () => _join(client.rooms[i]),
          ),
        ),
      ),
    );
  }
}

void _invite(Room room) async {
  print("roomid=${room.id}");
  currentRoom = room;
  await room.invite("XXX");
  print("invite userid=${room.id}");
}

void _showAlertDialog(BuildContext context, Room room) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('more test'),
        content: const Text('click the  button to  test more'),
        actions: [
          TextButton(
            onPressed: () {
              _invite(room);
              Navigator.of(context).pop();
            },
            child: const Text('invite'),
          ),
        ],
      );
    },
  );
}

class RoomPage extends StatefulWidget {
  final Room room;
  const RoomPage({required this.room, Key? key}) : super(key: key);

  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  late final Future<Timeline> _timelineFuture;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    _timelineFuture = widget.room.getTimeline(onChange: (i) {
      print('on change! $i');
      _listKey.currentState?.setState(() {});
    }, onInsert: (i) {
      print('on insert! $i');
      _listKey.currentState?.insertItem(i);
    }, onRemove: (i) {
      print('On remove $i');
      _listKey.currentState?.removeItem(i, (_, __) => const ListTile());
    }, onUpdate: () {
      print('On update');
    });
    super.initState();
  }

  final TextEditingController _sendController = TextEditingController();

  void _send() {
    widget.room.sendTextEvent(_sendController.text.trim());
    _sendController.clear();
  }

  void _leave(Room room) async {
    await widget.room.leave();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room.displayname),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _showAlertDialog(context, widget.room);
            },
            child: const Text('more test'),
          ),
          ElevatedButton(
            onPressed: () {
              _leave(widget.room);
              print("back");
              Navigator.of(context).pop();
            },
            child: const Text('leave'),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<Timeline>(
                future: _timelineFuture,
                builder: (context, snapshot) {
                  final timeline = snapshot.data;
                  if (timeline == null) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  return Column(
                    children: [
                      Center(
                        child: TextButton(
                            onPressed: timeline.requestHistory,
                            child: const Text('Load more...')),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: AnimatedList(
                          key: _listKey,
                          reverse: true,
                          initialItemCount: timeline.events.length,
                          itemBuilder: (context, i, animation) => timeline
                                      .events[i].relationshipEventId !=
                                  null
                              ? Container()
                              : ScaleTransition(
                                  scale: animation,
                                  child: Opacity(
                                    opacity: timeline.events[i].status.isSent
                                        ? 1
                                        : 0.5,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        foregroundImage: timeline.events[i]
                                                    .sender.avatarUrl ==
                                                null
                                            ? null
                                            : NetworkImage(timeline
                                                .events[i].sender.avatarUrl!
                                                .getThumbnail(
                                                  widget.room.client,
                                                  width: 56,
                                                  height: 56,
                                                )
                                                .toString()),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(timeline
                                                .events[i].sender
                                                .calcDisplayname()),
                                          ),
                                          Text(
                                            timeline.events[i].originServerTs
                                                .toIso8601String(),
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(timeline.events[i]
                                          .getDisplayEvent(timeline)
                                          .body),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _sendController,
                    decoration: const InputDecoration(
                      hintText: 'Send message',
                    ),
                  )),
                  IconButton(
                    icon: const Icon(Icons.send_outlined),
                    onPressed: _send,
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
