import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CuponerasListPage extends StatelessWidget {
  const CuponerasListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuponeras'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => context.go('/cuponeras/detalle'),
            child: const _CuponeraCardMock(),
          );
        },
      ),
    );
  }
}

class _CuponeraCardMock extends StatelessWidget {
  const _CuponeraCardMock({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        height: 120,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nombre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Descripción breve',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                color: const Color(0xFF374151),
                child: const Center(
                  child: Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 48,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}