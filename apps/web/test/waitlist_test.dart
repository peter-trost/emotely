import 'dart:convert';

import 'package:emotely_web/waitlist.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  final supabase = Uri.parse('https://example.supabase.co');
  const key = 'sb_publishable_test';

  group('joinWaitlist', () {
    test(
      'posts the address with the publishable key, asking for nothing back',
      () async {
        http.Request? seen;
        final client = MockClient((request) async {
          seen = request;
          return http.Response('', 201);
        });

        final outcome = await joinWaitlist(
          client,
          email: 'alice@example.com',
          supabaseUrl: supabase,
          publishableKey: key,
        );

        expect(outcome, JoinOutcome.joined);
        expect(seen?.method, 'POST');
        expect(
          seen?.url,
          Uri.parse('https://example.supabase.co/rest/v1/waitlist'),
        );
        expect(seen?.headers['apikey'], key);
        expect(seen?.headers['authorization'], 'Bearer $key');
        expect(seen?.headers['content-type'], startsWith('application/json'));
        expect(seen?.headers['prefer'], 'return=minimal');
        expect(jsonDecode(seen!.body), {
          'email': 'alice@example.com',
          'source': 'landing',
        });
      },
    );

    test('a 429 means the caller should wait', () async {
      final client = MockClient(
        (_) async => http.Response('{"code":"PT429"}', 429),
      );
      final outcome = await joinWaitlist(
        client,
        email: 'a@example.com',
        supabaseUrl: supabase,
        publishableKey: key,
      );
      expect(outcome, JoinOutcome.tooMany);
    });

    test('a 400 means the address was refused', () async {
      final client = MockClient(
        (_) async => http.Response('{"code":"23514"}', 400),
      );
      final outcome = await joinWaitlist(
        client,
        email: 'nope',
        supabaseUrl: supabase,
        publishableKey: key,
      );
      expect(outcome, JoinOutcome.rejected);
    });

    test('any other status is a failure the caller can retry', () async {
      final client = MockClient((_) async => http.Response('', 503));
      final outcome = await joinWaitlist(
        client,
        email: 'a@example.com',
        supabaseUrl: supabase,
        publishableKey: key,
      );
      expect(outcome, JoinOutcome.failed);
    });

    test('a network error is a failure, not an exception', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      final outcome = await joinWaitlist(
        client,
        email: 'a@example.com',
        supabaseUrl: supabase,
        publishableKey: key,
      );
      expect(outcome, JoinOutcome.failed);
    });
  });

  group('looksLikeEmail', () {
    test('accepts an ordinary address', () {
      expect(looksLikeEmail('peter@getemotely.com'), isTrue);
    });
    test('rejects text without an @ or a dot after it', () {
      expect(looksLikeEmail('peter'), isFalse);
      expect(looksLikeEmail('peter@localhost'), isFalse);
      expect(looksLikeEmail('@getemotely.com'), isFalse);
    });
    test('rejects surrounding spaces and empty input', () {
      expect(looksLikeEmail(''), isFalse);
      expect(looksLikeEmail('a b@example.com'), isFalse);
    });
  });
}
