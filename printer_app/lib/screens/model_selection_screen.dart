import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class ModelSelectionScreen extends StatelessWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch<AppState>();
    final List<String> models = appState.printerModels;

    return Scaffold(
      appBar: AppBar(title: const Text('Выбор модели принтера')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: models.length,
        itemBuilder: (context, index) {
          final String model = models[index];
          return InkWell(
            onTap: () async {
              await appState.setSelectedModel(model);
              if (context.mounted) {
                Navigator.of(context).pushNamed('/credentials');
              }
            },
            child: Card(
              elevation: 2,
              child: Center(
                child: Text(
                  model,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

