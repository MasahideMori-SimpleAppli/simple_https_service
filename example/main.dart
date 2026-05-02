// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:simple_https_service/simple_https_service.dart';

// TODO: Please make sure to rewrite this URL.
const String postURL = "https://your-endpoint.example.com/api";
const String postWithJwtURL = "https://your-endpoint.example.com/api";

void main() {
  // Optional: configure global retry behavior at app startup.
  RetryConfig()
    ..maxRetries = 3
    ..baseDelay = const Duration(seconds: 1)
    ..maxJitter = const Duration(milliseconds: 500)
    ..defaultCondition = (url, res, error) {
      // TODO: Define your retry condition here.
      // Return true to retry, false to return the result as-is.
      // Example: retry on "Failed to fetch" network errors.
      return error.toString().contains('Failed to fetch');
    };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _tecJwt = TextEditingController();

  @override
  void dispose() {
    _tecJwt.dispose();
    super.dispose();
  }

  // TODO: Please note that this is just a usage example and will not typically be laid out like this.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple HTTPS Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple HTTPS Example'),
          backgroundColor: const Color.fromARGB(255, 0, 255, 0),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: 320,
                    margin: EdgeInsets.zero,
                    child: TextField(
                      controller: _tecJwt,
                      decoration:
                          const InputDecoration(hintText: "JWT (optional)"),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 48, 0, 0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // For web or native device.
                        final ServerResponse res = await HttpsService.post(
                          postURL,
                          {"key": "value"},
                          EnumPostEncodeType.json,
                        );

                        // For native device only.
                        // This version can support self-signed certificates.
                        // final ServerResponse res =
                        //     await HttpsServiceForNative.post(
                        //   postURL,
                        //   {"key": "value"},
                        //   EnumPostEncodeType.json,
                        //   badCertificateCallback:
                        //       (X509Certificate cert, String host, int port) {
                        //     // TODO
                        //     // The condition is checked here, and if it returns true,
                        //     // self-signed certificates are allowed.
                        //     return true;
                        //   },
                        // );

                        debugPrint("Server response: $res");
                        switch (res.resultStatus) {
                          case EnumServerResponseStatus.success:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.timeout:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.serverError:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.otherError:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.signInRequired:
                          // TODO: Handle this case.
                        }
                      },
                      child: const Text('POST'),
                    )),
                Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    child: ElevatedButton(
                      onPressed: () async {
                        final String jwt = _tecJwt.text;

                        // For web or native device.
                        // The jwt parameter automatically sets the Authorization: Bearer header.
                        final ServerResponse res = await HttpsService.post(
                          postWithJwtURL,
                          {"key": "value"},
                          EnumPostEncodeType.json,
                          jwt: jwt,
                        );

                        // For native device only.
                        // This version can support self-signed certificates.
                        // final ServerResponse res =
                        //     await HttpsServiceForNative.post(
                        //   postWithJwtURL,
                        //   {"key": "value"},
                        //   EnumPostEncodeType.json,
                        //   jwt: jwt,
                        //   badCertificateCallback:
                        //       (X509Certificate cert, String host, int port) {
                        //     // TODO
                        //     // The condition is checked here, and if it returns true,
                        //     // self-signed certificates are allowed.
                        //     return true;
                        //   },
                        // );

                        debugPrint("Server response: $res");
                        switch (res.resultStatus) {
                          case EnumServerResponseStatus.success:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.timeout:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.serverError:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.otherError:
                          // TODO: Handle this case.
                          case EnumServerResponseStatus.signInRequired:
                          // TODO: The token has expired or is invalid.
                        }
                      },
                      child: const Text('POST with JWT'),
                    )),
              ],
            )
          ],
        ),
      ),
    );
  }
}
