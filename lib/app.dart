import 'package:flutter/material.dart';

/// Raíz de la aplicación EIRA.
///
/// Provisional a propósito: en T-001 solo verifica que el proyecto compila
/// e instala en el dispositivo físico. El tema propio entra en T-004 y T-005;
/// el `go_router` con el shell de 5 pestañas, en T-010.
class EiraApp extends StatelessWidget {
  const EiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'EIRA',
      home: Scaffold(
        body: Center(
          child: Text('EIRA'),
        ),
      ),
    );
  }
}
