/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2020 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:olm/olm.dart' as olm;
import 'package:test/test.dart';

import 'package:sdn/sdn.dart';
import '../fake_client.dart';

void main() {
  group('Encrypt/Decrypt room message', () {
    Logs().level = Level.error;
    var olmEnabled = true;

    late Client client;
    final roomId = '!726s6s6q:example.com';
    late Room room;
    late Map<String, dynamic> payload;
    final now = DateTime.now();

    test('setupClient', () async {
      try {
        await olm.init();
        olm.get_library_version();
      } catch (e) {
        olmEnabled = false;
        Logs().w('[LibOlm] Failed to load LibOlm', e);
      }
      Logs().i('[LibOlm] Enabled: $olmEnabled');
      if (!olmEnabled) return;

      client = await getClient();
      room = client.getRoomById(roomId)!;
    });

    test('encrypt payload', () async {
      if (!olmEnabled) return;
      payload = await client.encryption!.encryptGroupMessagePayload(roomId, {
        'msgtype': 'm.text',
        'text': 'Hello foxies!',
      });
      expect(payload['algorithm'], AlgorithmTypes.megolmV1AesSha2);
      expect(payload['ciphertext'] is String, true);
      expect(payload['device_id'], client.deviceID);
      expect(payload['sender_key'], client.identityKey);
      expect(payload['session_id'] is String, true);
    });

    test('decrypt payload', () async {
      if (!olmEnabled) return;
      final encryptedEvent = Event(
        type: EventTypes.Encrypted,
        content: payload,
        room: room,
        originServerTs: now,
        eventId: '\$event',
        senderId: client.userID!,
      );
      final decryptedEvent =
          await client.encryption!.decryptRoomEvent(roomId, encryptedEvent);
      expect(decryptedEvent.type, 'm.room.message');
      expect(decryptedEvent.content['msgtype'], 'm.text');
      expect(decryptedEvent.content['text'], 'Hello foxies!');
      expect(decryptedEvent.originalSource?.toJson(), encryptedEvent.toJson());
    });

    test('decrypt payload without device_id', () async {
      if (!olmEnabled) return;
      payload.remove('device_id');
      payload.remove('sender_key');
      final encryptedEvent = Event(
        type: EventTypes.Encrypted,
        content: payload,
        room: room,
        originServerTs: now,
        eventId: '\$event',
        senderId: client.userID!,
      );
      final decryptedEvent =
          await client.encryption!.decryptRoomEvent(roomId, encryptedEvent);
      expect(decryptedEvent.type, 'm.room.message');
      expect(decryptedEvent.content['msgtype'], 'm.text');
      expect(decryptedEvent.content['text'], 'Hello foxies!');
      expect(decryptedEvent.originalSource?.toJson(), encryptedEvent.toJson());
    });

    test('decrypt payload nocache', () async {
      if (!olmEnabled) return;
      client.encryption!.keyManager.clearInboundGroupSessions();
      final encryptedEvent = Event(
        type: EventTypes.Encrypted,
        content: payload,
        room: room,
        originServerTs: now,
        eventId: '\$event',
        senderId: '@alice:example.com',
      );
      final decryptedEvent =
          await client.encryption!.decryptRoomEvent(roomId, encryptedEvent);
      expect(decryptedEvent.type, 'm.room.message');
      expect(decryptedEvent.content['msgtype'], 'm.text');
      expect(decryptedEvent.content['text'], 'Hello foxies!');
      await client.encryption!
          .decryptRoomEvent(roomId, encryptedEvent, store: true);
    });

    test('dispose client', () async {
      if (!olmEnabled) return;
      await client.dispose(closeDatabase: true);
    });
  });
}
