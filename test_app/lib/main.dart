// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Minimal Flutter shell whose sole purpose is to host the integration_test
// driver on iOS and Android (and any other Flutter platform that needs
// device-side FFI coverage). The user-facing demo lives in `example/`.

import 'package:flutter/material.dart';

void main() {
  runApp(const _TestAppShell());
}

class _TestAppShell extends StatelessWidget {
  const _TestAppShell();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'mpv_audio_kit test harness',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('mpv_audio_kit test harness'),
        ),
      ),
    );
  }
}
