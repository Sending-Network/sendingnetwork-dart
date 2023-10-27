## sendingnetwork-dart  document

## 1. Integration and initialization

Download project: https://github.com/Sending-Network/sendingnetwork-dart

### 1) Add your own key and privateKey to metamask to simulate metamask's operation of obtaining wallet address and simulating signature
```
String privKey = ""; //
String addressHexAll = "";//
String homeUrl = "https://portal0101.sending.network";
String developSignUrl = "";

```

### 2) Configuration dependencies

Add dependencies in pubspec.yaml file

```
  sendingnetwork_dart_sdk: ^0.0.9

```


### 3) Import sdk

```
import 'package:sendingnetwork_dart_sdk/sdn.dart';
```


### 4) Create a client and fill in the domain name of the server

```
final client = Client('SDN Example Chat', databaseBuilder: (_) async {
final dir = await getApplicationSupportDirectory();
final db = HiveCollectionsDatabase('sdn_example_chat', dir.path);
await db. open();
return db;
});
client.sdnnode = Uri.parse('https://XXX.network'); // The domain name of the node
  
```




### 5) Run demo

```

flutter pub get
flutter run
```

The demo can run, after configuring the secret key, you can log in and create a room. It is best to use it on other ends, such as the account of the created room on the web end, to see the effect.




## 2. Interface

Please refer to our gitbook for detailed API docuemntation:
https://sending-network.gitbook.io/sending.network/sdk-documentation/flutter-sdk