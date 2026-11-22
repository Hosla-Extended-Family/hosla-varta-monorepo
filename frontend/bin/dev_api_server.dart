import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
      'Content-Type, X-Client-Platform, Authorization',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

class _AttemptState {
  int count;
  DateTime firstAttemptAt;
  DateTime? blockedUntil;

  _AttemptState({
    required this.count,
    required this.firstAttemptAt,
    this.blockedUntil,
  });
}

class _OtpState {
  final String otp;
  final DateTime expiresAt;

  const _OtpState({required this.otp, required this.expiresAt});
}

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args.first : '0.0.0.0';
  final port = args.length >= 2 ? int.tryParse(args[1]) ?? 8080 : 8080;

  final attempts = <String, _AttemptState>{};
  final otpStore = <String, _OtpState>{};

  final server = await HttpServer.bind(host, port);
  stdout.writeln('Dev API server listening on http://$host:$port');

  await for (final request in server) {
    unawaited(_handle(request, attempts, otpStore));
  }
}

Future<void> _handle(
  HttpRequest req,
  Map<String, _AttemptState> attempts,
  Map<String, _OtpState> otpStore,
) async {
  try {
    // CORS preflight
    if (req.method == 'OPTIONS') {
      req.response
        ..statusCode = HttpStatus.noContent
        ..headers.set(
          'Access-Control-Allow-Origin',
          _jsonHeaders['Access-Control-Allow-Origin']!,
        )
        ..headers.set(
          'Access-Control-Allow-Headers',
          _jsonHeaders['Access-Control-Allow-Headers']!,
        )
        ..headers.set(
          'Access-Control-Allow-Methods',
          _jsonHeaders['Access-Control-Allow-Methods']!,
        );
      await req.response.close();
      return;
    }

    if (req.method != 'POST') {
      await _writeJson(req, HttpStatus.methodNotAllowed, {
        'success': false,
        'error': {
          'code': 'METHOD_NOT_ALLOWED',
          'message': 'Method not allowed',
        },
      });
      return;
    }

    if (req.uri.path == '/api/auth/verify-otp') {
      await _verifyOtp(req, attempts);
      return;
    }

    if (req.uri.path == '/api/auth/request-otp') {
      await _requestOtp(req, otpStore);
      return;
    }

    await _writeJson(req, HttpStatus.notFound, {
      'success': false,
      'error': {'code': 'NOT_FOUND', 'message': 'Route not found'},
    });
  } catch (e) {
    // Avoid crashing the server on unexpected errors.
    try {
      await _writeJson(req, HttpStatus.internalServerError, {
        'success': false,
        'error': {'code': 'INTERNAL', 'message': 'Internal server error'},
      });
    } catch (_) {
      try {
        await req.response.close();
      } catch (_) {}
    }
  }
}

Future<void> _requestOtp(HttpRequest req, Map<String, _OtpState> otpStore) async {
  final body = await utf8.decoder.bind(req).join();
  final decoded = _tryDecodeJsonObject(body);

  if (decoded == null) {
    await _writeJson(req, HttpStatus.badRequest, {
      'success': false,
      'error': {'code': 'BAD_REQUEST', 'message': 'Invalid JSON body'},
    });
    return;
  }

  final phone = decoded['phone']?.toString().trim();
  final countryCodeRaw = decoded['countryCode']?.toString().trim();

  if (phone == null || phone.isEmpty) {
    await _writeJson(req, HttpStatus.badRequest, {
      'success': false,
      'error': {'code': 'BAD_REQUEST', 'message': 'phone is required'},
    });
    return;
  }

  // Keep this dev endpoint compatible with existing app calls that only send
  // { phone }. If countryCode is provided, use it for masking.
  final countryCode = (countryCodeRaw != null && countryCodeRaw.isNotEmpty)
      ? countryCodeRaw
      : _guessCountryCodeFromPhone(phone);

  const ttlSeconds = 300;
  const otp = '123456';
  final now = DateTime.now().toUtc();
  otpStore[phone] = _OtpState(
    otp: otp,
    expiresAt: now.add(const Duration(seconds: ttlSeconds)),
  );

  stdout.writeln('DEV OTP for $phone: $otp (ttl ${ttlSeconds}s)');

  await _writeJson(req, HttpStatus.ok, {
    'success': true,
    'data': {
      'phone': _maskPhone(phone: phone, countryCode: countryCode),
      'ttlSeconds': ttlSeconds,
    },
  });
}

Future<void> _verifyOtp(
  HttpRequest req,
  Map<String, _AttemptState> attempts,
) async {
  final body = await utf8.decoder.bind(req).join();
  final decoded = _tryDecodeJsonObject(body);

  if (decoded == null) {
    await _writeJson(req, HttpStatus.badRequest, {
      'success': false,
      'error': {'code': 'BAD_REQUEST', 'message': 'Invalid JSON body'},
    });
    return;
  }

  final phone = decoded['phone']?.toString().trim();
  final otp = decoded['otp']?.toString().trim();

  if (phone == null || phone.isEmpty || otp == null || otp.isEmpty) {
    await _writeJson(req, HttpStatus.badRequest, {
      'success': false,
      'error': {'code': 'BAD_REQUEST', 'message': 'phone and otp are required'},
    });
    return;
  }

  // Simple in-memory attempt limiting per phone.
  const maxAttempts = 5;
  const window = Duration(minutes: 10);
  const blockFor = Duration(minutes: 15);

  final now = DateTime.now().toUtc();
  final state = attempts.putIfAbsent(
    phone,
    () => _AttemptState(count: 0, firstAttemptAt: now),
  );

  // Reset window if needed.
  if (now.difference(state.firstAttemptAt) > window) {
    state
      ..count = 0
      ..firstAttemptAt = now
      ..blockedUntil = null;
  }

  if (state.blockedUntil != null && now.isBefore(state.blockedUntil!)) {
    await _writeJson(req, HttpStatus.tooManyRequests, {
      'success': false,
      'error': {
        'code': 'RATE_LIMITED',
        'message': 'Too many verification attempts',
      },
    });
    return;
  }

  // Dev behavior: OTP is valid only if it equals "123456".
  const validOtp = '123456';
  final isValid = otp == validOtp;

  if (!isValid) {
    state.count += 1;
    if (state.count >= maxAttempts) {
      state.blockedUntil = now.add(blockFor);
      await _writeJson(req, HttpStatus.tooManyRequests, {
        'success': false,
        'error': {
          'code': 'RATE_LIMITED',
          'message': 'Too many verification attempts',
        },
      });
      return;
    }

    await _writeJson(req, HttpStatus.unauthorized, {
      'success': false,
      'error': {'code': 'UNAUTHORIZED', 'message': 'Invalid or expired OTP'},
    });
    return;
  }

  // Success: reset attempts.
  attempts.remove(phone);

  await _writeJson(req, HttpStatus.ok, {
    'success': true,
    'data': {
      'user': {'id': 'user_1', 'name': 'Suman', 'role': 'USER'},
      'accessToken': _fakeJwt('access'),
      'expiresIn': 900,
      'refreshToken': _randomToken('rft'),
      'refreshExpiresIn': 7776000,
    },
  });
}

Map<String, dynamic>? _tryDecodeJsonObject(String raw) {
  try {
    final decoded = json.decode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

String _guessCountryCodeFromPhone(String phone) {
  final trimmed = phone.trim();
  if (!trimmed.startsWith('+')) return '';
  // Simple heuristic: + followed by 1-3 digits.
  final digits = trimmed.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  final ccLen = digits.length >= 2 ? 2 : 1;
  return '+${digits.substring(0, ccLen)}';
}

String _maskPhone({required String phone, required String countryCode}) {
  final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final last4 = digitsOnly.length >= 4
      ? digitsOnly.substring(digitsOnly.length - 4)
      : digitsOnly;
  final cc = countryCode.trim();
  final prefix = cc.isNotEmpty ? cc : (phone.trim().startsWith('+') ? phone.trim().split(RegExp(r'\d')).first : '');
  // Match the example: "+91*****3210"
  return '${prefix}*****$last4';
}

String _randomToken(String prefix) {
  final rnd = Random.secure();
  return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${rnd.nextInt(1 << 32)}';
}

String _fakeJwt(String kind) {
  // Not a real JWT, but shaped like one: header.payload.signature
  final header = base64Url
      .encode(utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})))
      .replaceAll('=', '');
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'sub': 'user_1',
            'kind': kind,
            'iat': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
          }),
        ),
      )
      .replaceAll('=', '');
  final sig = _randomToken('sig');
  return '$header.$payload.$sig';
}

Future<void> _writeJson(
  HttpRequest req,
  int status,
  Map<String, Object?> body,
) async {
  final res = req.response;
  res.statusCode = status;
  _jsonHeaders.forEach((k, v) => res.headers.set(k, v));
  res.write(jsonEncode(body));
  await res.close();
}
