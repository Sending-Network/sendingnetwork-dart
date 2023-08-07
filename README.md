To integrate and initialize  SDK  written in Dart, follow these steps:

#### 1）Download the project from this GitHub repository: sendingnetwork-dart.
```
https://github.com/Sending-Network/sendingnetwork-dart
```
#### 2）Add your own Wallet key and private key to simulate wallet address retrieval and signing operations. Update the following variables in your code:

```

 
String privKey = “wallet private Private key"; 
String addressHexAll = "wallet address";

```

#### 3) Configure the dependencies in your pubspec.yaml file. Add the following dependencies in the same directory:

```
sendingnetwork_flutter_demo
sendingnetwork_dart_sdk
sendingnetworkdart_api_lite
```
In the same pubspec.yaml file, include sendingnetwork_dart_sdk as a local path dependency:

yaml
```
sdn_api_lite:
  path: ../sendingnetworkdart_api_lite
Similarly, include sendingnetwork_flutter_demo as a local path dependency:
```
yaml

```
sdn:
  path: ../sendingnetwork_dart_sdk/
Refer to the configuration of sendingnetwork_flutter_demo for more details.
```

#### 4)Import the SDK in your code:

```
import 'package:sdn/sdn.dart';
```

#### 5) import 'package:sdn/sdn.dart';


Create a client and provide the server domain:
```
dart
final client = Client('SDN Example Chat', databaseBuilder: (_) async {
  final dir = await getApplicationSupportDirectory();
  final db = HiveCollectionsDatabase('sdn_example_chat', dir.path);
  await db.open();
  return db;
});
client.sdnnode = Uri.parse('https://XXX.network'); // Replace with your server's domain
```
#### 6) Run the demo:
```
flutter pub get
flutter run
```
By running the demo, you should be able to log in, create rooms, and see the effects on other platforms such as the web client when using an account that has created a room.