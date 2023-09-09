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



```
sendingnetwork_flutter_demo
sendingnetwork_dart_sdk
sendingnetworkdart_api_lite
```

under the same directory

sendingnetwork_dart_sdk depends on local path
```
sdn_api_lite:
path: ../sendingnetworkdart_api_lite
```


sendingnetwork_flutter_demo depends on local path
```
sdn:
path: ../sendingnetwork_dart_sdk/
```

For details, refer to the configuration of sendingnetwork_flutter_demo

### 3) import sdk

```
import 'package:sdn/sdn.dart';
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

#### 1. DID interface

##### Call order

1. Determine whether there is a did in the current address



``` dart
final client = Provider.of<Client>(context, listen: false);
SDNDIDListResponse response = await client.getDIDList(address: address);
```

   

Entry parameters:

| Name | Type | Description | Required |
| ---------- | :----- | :----------- | :------- |
| homeserver | String | edgenode address | true |
| address | String | Wallet address | True |

Out of parameters:

SDNDIDListResponse

| Name | Type | Description | Required |
| ------- | :----- | :---------- | :------- |
| data | String | User didid list | true |


2. Select did or use address to log in. When the interface array is empty, use address to log in, otherwise use the first element of the array as the did parameter

```dart
final client = Provider.of<Client>(context, listen: false);
String responseStr;
if (response1.data.isNotEmpty) {
responseStr = await client.postPreLoginDID(did: response1.data[0]);
} else {
responseStr = await client.postPreLoginDID(address: address);
}
```

Entry parameters:

| Name | Type | Description | Required |
| :--------- | :----- | :----------------------------- | :------- |
| did | string | did string, choose one of did and address | False |
| address | String | Wallet address, choose one of did and address | False |

Output:

PreloginResponse

| Name | Type | Description | Required |
| ------- | ------ | ------------------------- | -------- |
| did | string | user did (exist or newly created) | true |
| message | string | message to be signed | true |
| updated | string | updated time | true |
| random_server | string | update time | true |

3. Sign appServiceSign on the message return value of  step 2

```dart
// Make a request to your backend API to sign the message and retrieve the signature.
// Note: This example demonstrates the concept; implement this API in your backend.
  
final client = Provider.of<Client>(context, listen: false);
ApperviceSignResponse response =
await client.appServiceSign(message: responsesdn.message);
print('appServiceSign message => ${response. signature}');
   
postLoginDId(responsesdn, response);
```

Entry parameters:

| Name | Type | Description | Required |
| :------ | :----- | :------------ | :------ |
| message | string | returned message | True |
| | | | |

Out of parameters:

AppServiceSignResponse

| Name | Type | Description | Require |
| ------- | ------ | -------------------------- | -------- |
| signature | string | message to be signed | true |

The `signature` returned by the interface is used as the app_token parameter of the fourth step interface to log in.


4. Perform wallet signature on the return value message of step 2

```dart
String str = responsesdn.message; //responsesdn.message;
String signMessage = EthSigUtil.signPersonalMessage(
privateKey: privKey, message: convertStringToUint8List(str));
```


Entry parameters:

LoginRequest

| Name | Type | Description | Required |
| :---------- | :-------------- | :------- | :------- |
| type | string | login type (currently m.login.did.identity) | true |
| updated | string | time, updated | true | returned by pre_login
| identifier | IdentifierModel | login information | true |
| `device_id` | string | device id, new device login does not need to pass this field | false |

IdentifierModel type:

| Name | Type | Description |
| :---- | :----- | :------------ |
| did | string | user did |
| token | string | The method of signing the message signature returned by pre_login is to sign directly using the private key: you can directly call EthSigUtil.signPersonalMessage in the did class to sign |
| app_token | string | The message signature method returned by pre_login is to use the interface "appServiceSign" signature|


Out of parameters:

SDNDIDLoginResponse

| Name | Type | Description | Required |
| :------------- | :----- | :---------- | :------- |
| access_token | string | access token | true |
| user_id | string | user id | true |
| device_id | string | device id | true |


> For the complete login process of 1 2 3 4, please refer to `main.dart` in `sendingnetwork_flutter_demo`

5. Log out

```dart
Future<void> logout() async {
try {
await super.logout();
} catch (e, s) {
Logs().e('Logout failed', e, s);
rethrow;
} finally {
await clear();
}
}
```


Entry parameters:

| Name | Type | Description | Required |
| :---- | :----- | :--------- | :------- |
| token | string | login type (current value m.login.did.identity) | true |
| | | |



#### 2. Message interface

1. Send a message

```
Future<String?> sendTextEvent(String message,
{String? txid,
Event? inReplyTo,
String? editEventId,
bool parseMarkdown = true,
bool parseCommands = true,
String msgtype = MessageTypes. Text,
String? threadRootEventId,
String? threadLastEventId})
```

Entry parameters:

| Name | Type | Description | Required |
| :------ | :----- | :------------- | :------ |
| message | String | message | True |
| txid | String | txid | False |
| inReplyTo | String | inReplyTo | False |
| threadRootEventId | String | threadRootEventId | False |
| threadLastEventId | String | threadLastEventId | False |

2. Receive messages

```dart
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
```

#### 3. Room interface

1. Join the room

```dart
client. joinRoomById(id);
```

Entry parameters:

| Name | Type | Description | Required |
| :----- | :----- | :------------- | :------- |
| roomId | string | Room_id string | true |

2. Create a room

```dart
Future<String> createRoom(
{Map<String, Object?>? creationContent,
List<StateEvent>? initialState,
List<String>? invite,
List<Invite3pid>? invite3pid,
bool? isDirect,
String? name,
Map<String, Object?>? powerLevelContentOverride,
CreateRoomPreset? preset,
String? roomAliasName,
String? roomVersion,
String? topic,
Visibility? visibility})
```

3. Open chat directly

```dart
// Start a new direct chat
final roomId = await createRoom(
invite: [mxid],
isDirect: true,
preset: preset,
initialState: initialState,
powerLevelContentOverride: powerLevelContentOverride,
);
```

3. Invite into the room

```
Future<void> invite(String userID)
```

Entry parameters:

| Name | Type | Description | Required |
| :----- | :----- | :------------ | :------ |
| userID | string | userID string | true |



4. Get room information

```dart
 
builder: (context, snapshot) {
final timeline = snapshot.data; The entrance to the reception room in the demo
}


Future<SyncUpdate> sync(
{String? filter,
String? since,
bool?fullState,
PresenceType? setPresence,
int? timeout})
   
```

Entry parameters:

| Name | Type | Description | Required |
| :----- | :----- | :------------ | :------ |
| filter | string | filter string | false |
| since | string | since string | false |
| fullState | bool | fullState bool | false |
| setPresence | PresenceType | setPresence PresenceType | false |
| timeout | string | timeout int | false |

5. Leave the room

```dart
Future<void> leave() async
```

6. Modify the room name

```
Future<String> setName(String newName)
```

Entry parameters:

| Name | Type | Description | Required |
| :------ | :----- | :--------------- | :------- |
| newName | string | Room name string | true |


## developkey
https://sending-network.gitbook.io/sending.network/sdk-documentation/developer-key